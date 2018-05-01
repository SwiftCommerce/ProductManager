import FluentMySQL
import Foundation
import FluentSQL
import Vapor

extension Product {
    
    /// Gets all `Product` models from the database,
    /// filtering them based on the query-strings from a request.
    ///
    /// If there are no query-strings, all the models will be returned.
    ///
    /// Valid query-strings and what they do are the following:
    /// - `minPrice` (`Float`): Restricts results to `Product` moedls that are conected to
    ///   a `Price` model who's `.price` value is equal to, or more than, the value.
    /// - `maxPrice` (`Float`): Restricts results to `Product` moedls that are conected to
    ///   a `Price` model who's `.price` value is equal to, or less than, the value.
    /// - `filter` (`[String: String]`): Restricts results to `Product` models that are connected
    ///   to `Attribute` models with the `name` equal to `key` and `value` equal to `value`.
    /// - `categories` (`[String]`): Restricts results to Product` models that are connected to
    ///   `Category` models with `name` values equal the the array elements.
    /// - `status` (`Int`): Restricts results to models with a `status` property who's `rawValue` is
    ///   equal to the query value.
    ///
    /// - Parameter request: The request to get the query-strings and database connection from.
    ///
    /// - Throws: Errors that occur when creating database queries.
    /// - Returns: All the `Product` model that match the query-strings from the request.
    static func filter(on request: Request)throws -> Future<QueryBuilder<Product, Product>> {
        
        // Get valid IDs for the `Product` models we fetch.
        let productIDs = try [
            idsConstrainedWithPrice(with: request),
            idsConstrainedWithAttributes(with: request),
            idsConstrainedWithCategories(with: request)
            ].flatten(on: request)
        
        let cleanedIDs = productIDs.map(to: [Product.ID]?.self) { ids in
            
            // Verify not all arrays are `nil`.
            guard ids.compactMap({ $0 }).count > 0 else { return nil }
            
            // Get values to only occur in all arrays passed in.
            let cleanedIDs: [Product.ID] = ids.compactMap { $0 }.reduce(into: []) { (result, ids) in
                
                // Set the inital array to the base result.
                if result == [] { result = ids; return }
                
                // If a value in the result is not in another array
                // it does not exist in all the arrays and should be removed.
                // Complexity: `O(n*m^2)`
                result.forEach { id in
                    if !ids.contains(id) {
                        let index = result.index(of: id)!
                        result.remove(at: index)
                    }
                }
            }
            
            // Remove duplicate values.
            return Array(Set(cleanedIDs))
        }
        
        // Construct base query for getting `Product` models.
        let query = cleanedIDs.map(to: QueryBuilder<Product, Product>.self) { validIDs in
            let query = Product.query(on: request)
            
            if let ids = validIDs {
                try query.filter(\.id ~~ ids)
            }
            if let status = try request.query.get(ProductStatus?.self, at: "status") {
                try query.filter(\.status == status)
            }
            
            return query
        }
        
        return query.map(to: QueryBuilder<Product, Product>.self) { query in
            
            // If query parameters where passed in for pagination, limit the amount of models we fetch.
            if let page = try request.query.get(Int?.self, at: "page"), let results = try request.query.get(Int?.self, at: "results_per_page") {
                
                // Get all the models in the range specified by the query parameters passed in.
                return query.range(lower: (results * page) - results, upper: (results * page))
            } else {
                
                // Run the query to fetch all the rows from the `products` database table.
                return query
            }
        }
    }
    
    private static func idsConstrainedWithPrice(with request: Request)throws -> Future<[Product.ID]?> {
        
        // Setup base query, along with logical constrainst and paramaters storage.
        let priceQuery = "SELECT * FROM `\(Price.entity)` INNER JOIN `\(ProductPrice.entity)` ON `\(ProductPrice.entity)`.`priceID` = `\(Price.entity)`.`id`"
        var constraints: [String] = []
        var paramaters: [MySQLDataConvertible] = []
        var priceConstraints: Int = 0
        
        // See if a `minPrice` query was passed in. If so,
        // update the query data stores and logival checks.
        if let min = try request.query.get(Int?.self, at: "minPrice") {
            constraints.append("`\(Price.entity)`.`cents` >= ?")
            paramaters.append(min)
            priceConstraints += 1
        }
        
        if let max = try request.query.get(Int?.self, at: "maxPrice") {
            constraints.append("`\(Price.entity)`.`cents` <= ?")
            paramaters.append(max)
            priceConstraints += 1
        }
        
        // If no price constraints where passed in, return nil.
        // This will not restrict the `Propduct` models that are fetched.
        if priceConstraints < 1 { return Future.map(on: request) { nil } }
        
        // Construct the full query, then run it, passing in the query paramaters.
        return ProductID.raw(priceQuery + " WHERE " + constraints.joined(separator: " AND "), with: paramaters, on: request).map(to: [Product.ID]?.self) { pivots in
            return pivots.map { $0.productID }
        }
    }
    
    private static func idsConstrainedWithAttributes(with request: Request)throws -> Future<[Product.ID]?> {
        let futureAttributes: Future<[ProductID]>
        let filterCount: Int
        
        if let attributes = try request.query.get([String: String]?.self, at: "filter") {
            
            // `OR` query groups are broken in Fluent 3, so we create and run a raw query.
            var attributeQuery = "SELECT * FROM `\(Attribute.entity)` INNER JOIN `\(ProductAttribute.entity)` ON `\(ProductAttribute.entity)`.attributeID = `\(Attribute.entity)`.id"
            var paraneters: [MySQLDataConvertible] = []
            
            let whereClause = attributes.map { attribute in
                paraneters.append(attribute.key)
                paraneters.append(attribute.value)
                
                // The querstion-marks are placeholders in the query.
                // They are replaced with the `parameters` values passed into the `.raw` method.
                return "(`\(Attribute.entity)`.`name` = ? AND `\(ProductAttribute.entity)`.`value` = ?)"
                }.joined(separator: " OR ")
            attributeQuery += " WHERE \(whereClause)"
            
            futureAttributes = ProductID.raw(attributeQuery, with: paraneters, on: request)
            filterCount = attributes.count
        } else {
            return Future.map(on: request) { nil }
        }
        
        return futureAttributes.map(to: [Product.ID]?.self) { (pivots) in
            
            // 1. Create a dictionary, where the `productID` is the key
            //    and the pivots that have an equal `productID` value
            //    are the elements of the array value.
            // 2. Get all the key/value pairs where the length of the array
            //    value is equal to the amount of attribute filters in the query-string
            // 3. Get the keys of the key/value pairs that made it through the filter.
            //    These are the IDs of the products that match the filter.
            let keys = pivots.group(by: \.productID).filter { _, pivots in
                return pivots.count == filterCount
            }.keys
            return Array(keys)
        }
    }
    
    private static func idsConstrainedWithCategories(with request: Request)throws -> Future<[Product.ID]?> {
        let futureCategories: Future<[ProductID]>
        let categoryCount: Int
        
        if let categories = try request.query.get([String]?.self, at: "categories") {
            let categoriesQuery = "SELECT * FROM `\(Category.entity)` INNER JOIN `\(ProductCategory.entity)` ON `\(ProductCategory.entity)`.`categoryID` = `\(Category.entity)`.`id`"
            let parameters: [MySQLDataConvertible] = categories
            let whereCaluse = Array(repeating: "`\(Category.entity)`.`name` = ?", count: categories.count).joined(separator: " OR ")
            let query = categoriesQuery + " WHERE " + whereCaluse
            
            futureCategories = ProductID.raw(query, with: parameters, on: request)
            categoryCount = categories.count
        } else {
            return Future.map(on: request) { nil }
        }
        
        return futureCategories.map(to: [Product.ID]?.self) { pivots in
            let keys = pivots.group(by: \.productID).filter { _, pivots in
                return pivots.count == categoryCount
            }.keys
            return Array(keys)
        }
    }
}

struct ProductID: MySQLModel {
    var id: Int?
    let productID: Product.ID
}

