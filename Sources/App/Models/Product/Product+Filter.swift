import FluentMySQL
import Foundation
import FluentSQL
import Vapor

typealias QueryList = [String: (sql: String, bindings: [Encodable])]
struct SearchResult: Content {
    let products: [ProductResponseBody]
    let count: Int
}

extension Product {
    static func search(on request: Request) -> Future<SearchResult> {
        do {
            let list = try self.query(for: request)
            guard let productQuery = list["products"] else {
                throw Abort(.internalServerError, reason: "Missing query for product search")
            }
            let countQuery = list["count"] ?? productQuery
            
            let products = request.withPooledConnection(to: .mysql) { conn -> Future<[ProductResponseBody]> in
                let products = conn.raw(productQuery.sql).binds(productQuery.bindings).all(decoding: Product.self)
                return products.flatMap { products in products.map { Promise(product: $0, on: request).futureResult }.flatten(on: request) }
            }
            let count = request.withPooledConnection(to: .mysql) { conn in
                return conn.raw(countQuery.sql).binds(countQuery.bindings).all(decoding: Product.self)
            }
            
            return map(products, count) { products, count in
                return SearchResult(products: products, count: count.count)
            }
        } catch let error {
            return request.future(error: error)
        }
    }
    
    private static func query(for request: Request)throws -> QueryList {
        var structre = QueryStructure(table: Product.table, selects: [Product.table + ".*"], groups: [Product.table + ".`id`"])
        
        try structre.add(structure: self.skuFilter(for: request))
        try structre.add(structure: self.priceFilter(for: request))
        try structre.add(structure: self.categoryFilter(on: request))
        try structre.add(structure: self.attributeFilter(on: request))
        
        if let sort = try self.sort(query: &structre, on: request) {
            structre.order = sort
        }
        
        if let pagination = try self.pagination(on: request) {
            let count = structre.serelize()
            
            structre.limit = pagination
            let products = structre.serelize()
            
            return [
                "products": (products.query + ";", products.binds),
                "count": (count.query + ";", count.binds)
            ]
        } else {
            let serelized = structre.serelize()
            return ["products": (serelized.query + ";", serelized.binds)]
        }
    }
    
    private static func skuFilter(for request: Request)throws -> QueryStructure {
        guard let sku = try request.query.get(String?.self, at: "sku") else { return QueryStructure() }
        return QueryStructure(joins: [], filter: [.init(Product.table + ".`sku` = ?", [sku])], having: [])
    }
    
    private static func priceFilter(for request: Request)throws -> QueryStructure {
        let minPrice = try request.query.get(Int?.self, at: "minPrice")
        let maxPrice = try request.query.get(Int?.self, at: "maxPrice")
        var queryData: QueryStructure
        
        if minPrice != nil || maxPrice != nil {
            queryData = QueryStructure(joins: [.init(table: Price.table, on: Price.table + ".`productID`", to: Product.table + ".`id`")])
        } else { return QueryStructure() }
        
        if let min = minPrice {
            queryData.filter.append(.init(Price.table + ".`cents` >= ?", [min]))
        }
        if let max = maxPrice {
            queryData.filter.append(.init(Price.table + ".`cents` <= ?", [max]))
        }
        
        return queryData
    }
    
    private static func categoryFilter(on request: Request)throws -> QueryStructure {
        guard let categories = try request.query.get([String]?.self, at: "categories") else { return QueryStructure() }
        
        return QueryStructure(
            joins: [
                .init(table: ProductCategory.table, on: ProductCategory.table + ".`productID`", to: Product.table + ".`id`"),
                .init(table: Category.table, on: Category.table + ".`id`", to: ProductCategory.table + ".`categoryID`")
            ],
            filter: [
                .init(Category.table + ".`name` IN (" + Array(repeating: "?", count: categories.count).joined(separator: ", ") + ")", categories)
            ],
            having: [
                .init("COUNT(DISTINCT " + Category.table + ".`name`) = ?", [categories.count])
            ]
        )
    }
    
    private static func attributeFilter(on request: Request)throws -> QueryStructure {
        guard let attributes = try request.query.get([String: String]?.self, at: "attributes") else { return QueryStructure() }
        let pivots = self.productAttributes(attributes: attributes)
        
        return QueryStructure(
            joins: [
                .init(table: ProductAttribute.table, on: ProductAttribute.table + ".`productID`", to: Product.table + ".`id`"),
                .init(table: Attribute.table, on: Attribute.table + ".`id`", to: ProductAttribute.table + ".`attributeID`")
            ],
            filter: [
                .init(ProductAttribute.table + ".`id` IN (" + pivots.query + ")", pivots.binds)
            ],
            having: [
                .init("COUNT(DISTINCT " + ProductAttribute.table + ".`id`) = ?", [attributes.count])
            ]
        )
    }
    
    private static func productAttributes(attributes: [String: String]) -> (query: String, binds: [Encodable]) {
        let filter: (query: [String], binds: [Encodable]) = attributes.reduce(into: (query: [], binds: [])) { result, attribute in
            result.query.append("(" + Attribute.table + ".`name` = ? AND " + ProductAttribute.table + ".`value` = ?)")
            result.binds.append(contentsOf: [attribute.key, attribute.value])
        }
        
        let structure = QueryStructure(
            joins: [
                .init(table: Attribute.table, on: Attribute.table + ".`id`", to: ProductAttribute.table + ".`attributeID`")
            ],
            filter: [
                .init(filter.query.joined(separator: " OR "), filter.binds)
            ]
        )
        let serelized = structure.serelize()
        let query =
            "SELECT " + ProductAttribute.table + ".`id` FROM " + ProductAttribute.table +
            " " + serelized.query +
            " GROUP BY " + ProductAttribute.table + ".`id`"
        
        return (query, serelized.binds)
    }
    
    private static func pagination(on request: Request)throws -> (offset: Int, rowCount: Int)? {
        let page = try request.query.get(Int?.self, at: "page")
        let pageSize = try request.query.get(Int?.self, at: "pageSize")
        
        if page == nil && pageSize == nil {
            return nil
        }
        
        guard let offset = page, let rowCount = pageSize else {
            throw Abort(.badRequest, reason: "Both `page` and `pageSize` values must be passed in for pagination")
        }
        guard offset >= 0 else {
            throw Abort(.badRequest, reason: "`page` value must be equal to, or greater than, `0`")
        }
        guard rowCount > 0 else {
            throw Abort(.badRequest, reason: "`pageSize` value must be greater than `0`")
        }
        
        return ((offset * rowCount), rowCount)
    }
    
    private static func sort(
        query: inout QueryStructure,
        on request: Request
    )throws -> (property: QueryStructure.OrderValue, direction: MySQLDirection)? {
        let direction = try request.query.get(String?.self, at: "sortDirection")
        let property = try request.query.get(String?.self, at: "sortBy")
        
        if direction == nil && property == nil {
            return nil
        }
        
        let mysqlDirection: MySQLDirection
        switch direction?.lowercased() {
        case "asc", "ascending": mysqlDirection = .ascending
        case "desc", "descending": mysqlDirection = .descending
        default: throw Abort(.badRequest, reason: "No valid `sortDirection` value. Expected `asc`, `ascending`, `desc`, `descending`.")
        }
        
        let mysqlProperty: String
        switch property?.lowercased() {
        case "name": mysqlProperty = Product.table + ".`name`"
        case "price":
            mysqlProperty = Price.table + ".`cents`"
            
            query.selects.append(mysqlProperty)
            query.groups.append(mysqlProperty)
            if !query.joins.contains(where: { $0.table == Price.table }) {
                query.joins.append(.init(table: Price.table, on: Price.table + ".`productID`", to: Product.table + ".`id`"))
            }
        case "category":
            mysqlProperty = Category.table + ".`name`"
            
            query.selects.append(mysqlProperty)
            query.groups.append(mysqlProperty)
            if !query.joins.contains(where: { $0.table == Category.table }) {
                query.joins.append(contentsOf: [
                    .init(table: ProductCategory.table, on: ProductCategory.table + ".`productID`", to: Product.table + ".`id`"),
                    .init(table: Category.table, on: Category.table + ".`id`", to: ProductCategory.table + ".`categoryID`")
                ])
            }
        default: throw Abort(.badRequest, reason: "No valid `sortBy` value. Expected `price`, `name`, `category`.")
        }
        
        return (.property(mysqlProperty), mysqlDirection)
    }
}

extension Model {
    static var table: String {
        return "`" + self.entity + "`"
    }
}

struct QueryStructure {
    var table: String?
    var selects: [String]
    var joins: [Join]
    var filter: [Query]
    var groups: [String]
    var having: [Query]
    var order: (property: OrderValue, direction: MySQLDirection)?
    var limit: (offset: Int, rowCount: Int)?
    
    init(
        table: String? = nil,
        selects: [String] = [],
        joins: [Join] = [],
        filter: [Query] = [],
        groups: [String] = [],
        having: [Query] = []
    ) {
        self.table = table
        self.selects = selects
        self.joins = joins
        self.filter = filter
        self.groups = groups
        self.having = having
        self.order = nil
        self.limit = nil
    }
    
    func serelize(afterFilter intermediate: Query? = nil) -> (query: String, binds: [Encodable]) {
        var query = ""
        var binds: [Encodable] = []
        
        if let table = self.table, self.selects.count > 0 {
            query.append("SELECT " + self.selects.joined(separator: ", ") + " FROM " + table + " ")
        }
        if self.joins.count > 0 {
            let joins = self.joins.map { return "JOIN " + $0.table + " ON " + $0.base + " = " + $0.relative }
            query.append(joins.joined(separator: " ") + " ")
        }
        if self.filter.count > 0 {
            query.append("WHERE " + self.filter.map { $0.query }.joined(separator: " AND ") + " ")
            binds.append(contentsOf: self.filter.flatMap { $0.binds })
        }
        if self.groups.count > 0 {
            query.append(" GROUP BY " + self.groups.joined(separator: ", ") + " ")
        }
        if let inter = intermediate {
            query.append(inter.query)
            binds.append(contentsOf: inter.binds)
        }
        if self.having.count > 0 {
            query.append(contentsOf: " HAVING " + self.having.map { $0.query }.joined(separator: " AND "))
            binds.append(contentsOf: self.having.flatMap { $0.binds })
        }
        if let order = self.order {
            switch order.property {
            case let .property(prop): query.append(" ORDER BY " + prop + " ")
            case let .location(string, property):
                query.append(" ORDER BY LOCATE (?, " + property + ") ")
                binds.append(string)
            }
            query.append(order.direction.serialize(&binds))
        }
        if let limit = self.limit {
            query.append(" LIMIT ?, ?")
            binds.append(contentsOf: [limit.offset, limit.rowCount])
        }
        
        return (query, binds)
    }
    
    mutating func add(structure: QueryStructure) {
        self.selects.append(contentsOf: structure.selects)
        self.joins.append(contentsOf: structure.joins)
        self.filter.append(contentsOf: structure.filter)
        self.groups.append(contentsOf: structure.groups)
        self.having.append(contentsOf: structure.having)
    }
    
    struct Query {
        var query: String
        var binds: [Encodable]
        
        init(_ query: String, _ binds: [Encodable]) {
            self.query = query
            self.binds = binds
        }
    }
    
    struct Join {
        var table: String
        var base: String
        var relative: String
        
        init(table: String, on base: String, to relative: String) {
            self.table = table
            self.base = base
            self.relative = relative
        }
    }
    
    enum OrderValue {
        case property(String)
        case location(string: String, property: String)
    }
}
