import FluentMySQL
import Foundation
import FluentSQL
import Vapor

extension Product {
    static func search(on request: Request) -> Future<[Product]> {
        do {
            let search = try self.query(for: request)
            return request.withPooledConnection(to: .mysql) { conn -> Future<[Product]> in
                return conn.raw(search.query).binds(search.bindings).all(decoding: Product.self)
            }
        } catch let error {
            return request.future(error: error)
        }
    }
    
    private static func query(for request: Request)throws -> (query: String, bindings: [Encodable]) {
        var structre = QueryStructure()
        try structre.add(structure: self.priceFilter(for: request))
        try structre.add(structure: self.categoryFilter(on: request))
        try structre.add(structure: self.attributeFilter(on: request))
        let serelized = structre.serelize(afterFilter: .init(" GROUP BY " + Product.table + ".`id` ", []))
        
        let query = "SELECT " + Product.table + ".* FROM " + Product.table + " " + serelized.query + ";"
        return (query, serelized.binds)
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
    
    init(joins: [String] = [], filter: [Query] = [], having: [Query] = []) {
        self.joins = joins
        self.filter = filter
        self.having = having
    }
    
    func serelize(afterFilter intermediate: Query = Query("", [])) -> (query: String, binds: [Encodable]) {
        var query = ""
        
        if self.joins.count > 0 {
            query.append(self.joins.joined(separator: " ") + " ")
        }
        if self.filter.count > 0 {
            query.append("WHERE " + self.filter.map { $0.query }.joined(separator: " AND ") + " ")
        }
        query.append(intermediate.query)
        if self.having.count > 0 {
            query.append(contentsOf: " HAVING " + self.having.map { $0.query }.joined(separator: " AND "))
        }
        
        let binds = Array(self.filter.map { $0.binds }.joined()) + intermediate.binds + Array(self.having.map { $0.binds }.joined())
        
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
