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
        var structre = QueryStructure()
        
        try structre.add(structure: self.skuFilter(for: request))
        try structre.add(structure: self.priceFilter(for: request))
        try structre.add(structure: self.categoryFilter(on: request))
        try structre.add(structure: self.attributeFilter(on: request))
        
        if let pagination = try self.pagination(on: request) {
            let count = structre.serelize(afterFilter: .init(" GROUP BY " + Product.table + ".`id` ", []))
            
            structre.limit = pagination
            let products = structre.serelize(afterFilter: .init(" GROUP BY " + Product.table + ".`id` ", []))
            
            return [
                "products": ("SELECT " + Product.table + ".* FROM " + Product.table + " " + products.query + ";", products.binds),
                "count": ("SELECT " + Product.table + ".* FROM " + Product.table + " " + count.query + ";", count.binds)
            ]
        } else {
            let serelized = structre.serelize(afterFilter: .init(" GROUP BY " + Product.table + ".`id` ", []))
            let query = "SELECT " + Product.table + ".* FROM " + Product.table + " " + serelized.query + ";"
            return ["products": (query, serelized.binds)]
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
            queryData = QueryStructure(joins: ["JOIN " + Price.table + " ON " + Price.table + ".`productID` = " + Product.table + ".`id`"])
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
                "JOIN " + ProductCategory.table + " ON " + ProductCategory.table + ".`productID` = " + Product.table + ".`id`",
                "JOIN " + Category.table + " ON " + Category.table + ".`id` = " + ProductCategory.table + ".`categoryID`"
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
                "JOIN " + ProductAttribute.table + " ON " + ProductAttribute.table + ".`productID` = " + Product.table + ".`id`",
                "JOIN " + Attribute.table + " ON " + Attribute.table + ".`id` = " + ProductAttribute.table + ".`attributeID`"
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
                "JOIN " + Attribute.table + " ON " + Attribute.table + ".`id` = " + ProductAttribute.table + ".`attributeID`"
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
        guard offset > 0 && rowCount > 0 else {
            throw Abort(.badRequest, reason: "`page` and `pageSize` values must be greater than `0`")
        }
        
        return ((offset * rowCount) - (rowCount - 1), rowCount)
    }
}

extension Model {
    static var table: String {
        return "`" + self.entity + "`"
    }
}

struct QueryStructure {
    var joins: [String]
    var filter: [Query]
    var having: [Query]
    var limit: (offset: Int, rowCount: Int)?
    
    init(joins: [String] = [], filter: [Query] = [], having: [Query] = []) {
        self.joins = joins
        self.filter = filter
        self.having = having
        self.limit = nil
    }
    
    func serelize(afterFilter intermediate: Query? = nil) -> (query: String, binds: [Encodable]) {
        var query = ""
        var binds: [Encodable] = []
        
        if self.joins.count > 0 {
            query.append(self.joins.joined(separator: " ") + " ")
        }
        if self.filter.count > 0 {
            query.append("WHERE " + self.filter.map { $0.query }.joined(separator: " AND ") + " ")
            binds.append(contentsOf: self.filter.flatMap { $0.binds })
        }
        if let inter = intermediate {
            query.append(inter.query)
            binds.append(contentsOf: inter.binds)
        }
        if self.having.count > 0 {
            query.append(contentsOf: " HAVING " + self.having.map { $0.query }.joined(separator: " AND "))
            binds.append(contentsOf: self.having.flatMap { $0.binds })
        }
        if let limit = self.limit {
            query.append(contentsOf: " LIMIT ?, ?")
            binds.append(contentsOf: [limit.offset, limit.rowCount])
        }
        
        return (query, binds)
    }
    
    mutating func add(structure: QueryStructure) {
        self.joins.append(contentsOf: structure.joins)
        self.filter.append(contentsOf: structure.filter)
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
}
