import Vapor
import Fluent
import FluentSQL

import Foundation

extension Product {
    func filter(on request: Request)throws -> Future<[Product]> {
        
        // Create a non-assigned `QueryBuilder` constant.
        // This allows us to assign different queries depending on wheather the `filter` query string exists.
        var query: Future<QueryBuilder<Product, Product>> = Future.map(on: request) { Product.query(on: request) }
        
        // Try to got the `filter` query string from the request.
        if let filters = try request.query.get([String: String]?.self, at: "filter") {
            
            // We use parameters instead of injecting data
            // into the query to prevent SQL injection attacks.
            var parameters: [MySQLDataConvertible] = []
            
            let filter = filters.map({ (filter) in
                
                // Add the filter's name and value to the parameters
                // so thet can be access by the query.
                parameters.append(filter.key)
                parameters.append(filter.value)
                
                // For each filter, we need a SQL `AND` statement.
                return "(`name` = ? AND `value` = ?)"
                
                // Join the array of filters with `OR` to get all attributes.
            }).joined(separator: " OR ")
            
            // Run the raw query with the filter parameters
            let attributes = Attribute.raw("SELECT * FROM attributes WHERE \(filter)", with: parameters, on: request)
            
            query = attributes.map(to: QueryBuilder<Product, Product>.self) { (attributes) in
                
                // Group the attributes togeather by their `productID` property.
                let keys = attributes.group(by: \.productID).filter({ (id, attributes) -> Bool in
                    
                    // If we have the same amount of filters as attributes, we have a match!
                    return attributes.count == filters.count
                }).keys
                
                // Get all products that have the correct amount of attributes.
                let ids = Array(keys)
                return try Product.query(on: request).filter(\.id ~~ ids)
            }
        }
        
        // Try to get the `status` query string from the request.
        if let status = try request.query.get(ProductStatus?.self, at: "status") {
            
            // A `status` value was found. Add a filter to the quesy that gets all models with that status.
            query = query.map(to: QueryBuilder<Product, Product>.self) { try $0.filter(\Product.status == status) }
        }
        
        return query.flatMap(to: [Product].self) { (query) in
            
            // If query parameters where passed in for pagination, limit the amount of models we fetch.
            if let page = try request.query.get(Int?.self, at: "page"), let results = try request.query.get(Int?.self, at: "results_per_page") {
                
                // Get all the models in the range specified by the query parameters passed in.
                return query.range(lower: (results * page) - results, upper: (results * page)).all()
            } else {
                
                // Run the query to fetch all the rows from the `products` database table.
                return query.all()
            }
        }
    }
}
