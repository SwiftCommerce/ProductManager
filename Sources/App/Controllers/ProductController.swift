import FluentMySQL
import FluentSQL

// MARK: - Request Body Type

/// A decoded request body used to
/// update a `Product` models connections to other models.
struct ProductUpdateBody: Content {
    
    /// A wrapper type, allowing the request's body to have a nested strcuture:
    ///
    ///     {
    ///       "attributes": {"attach": [], "detach": []}
    ///     }
    struct AttributeUpdate: Content {
        
        /// The IDs of the attributes to attach (create pivots) to the prodcut.
        let create: [AttributeContent]?
        
        /// The IDs of the attributes to detach (delete pivots) from the prodcut.
        let delete: [Attribute.ID]?
    }
    
    /// A decoded JSON object to get the IDs of `Attribute` models
    /// to attach to and detach from the product.
    let attributes: AttributeUpdate?
    
    
    /// A decoded JSON object to get the IDs of `Category` models
    /// to attach to and detach from the product.
    let categories: CategoryUpdateBody?
}

// MARK: - Controller

/// A controller for API endpoints that make operations on the `prodcuts` database table.
final class ProductController: RouteCollection {
    
    /// Required by the `RouteCollection` protocol.
    /// Allows you to run this to add your routes to a router:
    ///
    ///     router.register(collection: ProductController())
    ///
    /// - parameter router: The router that the controller's routes will be registered to.
    func boot(router: Router) throws {
        
        // We create a route group because all the routes for this controller
        // have the same parent path.
        let products = router.grouped("products")
        
        // Registers a POST route at `/prodcuts` with the router.
        // This route automatically decodes the request's body to a `Prodcut` object.
        products.post(Product.self, use: create)
        
        // Registers a GET route at `/prodcuts` with the router.
        products.get(use: index)
        
        // Registers a GET route at `/prodcuts/:product` with the router.
        products.get(Product.parameter, use: show)
        
        // Registers a GET route at `/products/categorized` with the router.
        products.get("categorized", use: categorized)
        
        // Registers a PATCH route at `/prodcuts/:prodcut` with the router.
        // This route automatically decodes the request's body to a `ProductUpdateBody` object.
        products.patch(ProductUpdateBody.self, at: Product.parameter, use: update)
        
        // Registers a DELETE route at `/products/:product` with the router.
        products.delete(Product.parameter, use: delete)
    }
    
    /// Creates a new `Prodcut` model from the request's body
    /// and saves it to the database.
    func create(_ request: Request, _ product: Product)throws -> Future<ProductResponseBody> {
        
        // Save the `Product` model to the database and convert it to a `ProductResponseBody`.
        return product.save(on: request).response(on: request)
    }
    
    /// Get all the prodcuts from the database.
    func index(_ request: Request)throws -> Future<[ProductResponseBody]> {
        
        // Create a non-assigned `QueryBuilder` constant.
        // This allows us to assign different queries depending on wheather the `filter` query string exists.
        let query: Future<QueryBuilder<Product, Product>>
        
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
        } else {
            
            // `filter` doesn't exist. Create a generic query builder instance.
            query = Future.map(on: request) { Product.query(on: request) }
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
        }.each(to: ProductResponseBody.self) { (product) in
            
            // For each product fetched from the database, create a `ProductResponseBody` from it.
            return Promise(product: product, on: request).futureResult
        }
    }
    
    /// Get the `Product` model from the database with a given ID.
    func show(_ request: Request)throws -> Future<ProductResponseBody> {
        
        // Get the specified model from the route's paramaters
        // and convert it to a `ProductResponseBody`
        return try request.parameter(Product.self).response(on: request)
    }
    
    /// Get all the `Product` models connected to specified categories.
    func categorized(_ request: Request)throws -> Future<[ProductResponseBody]> {
        
        // Get the category IDs from the request query and get all the `Category` models with the IDs.
        let categoryIDs = try request.query.get([Category.ID].self, at: "category_ids")
        let futureCategories = try Category.query(on: request).filter(\.id ~~ categoryIDs).sort(\.sort, .ascending).all()
        
        
        return futureCategories.flatMap(to: [[Product]].self) { (categories) in
            
            // Get all the `Product` models that are connected to the categories.
            try categories.map({ (category) in
                return try category.products.query(on: request).all()
            }).flatten(on: request)
            
        // Flatten the 2D array to products to a 1D array.
        }.map(to: [Product].self) { $0.flatMap({ $0 }) }
            
        // Convert each prodcut to a `ProductResponseBody` object.
        .each(to: ProductResponseBody.self) { (product) in
            return Promise(product: product, on: request).futureResult
        }
    }
    
    /// Updates to pivots that connect a `Product` model to other models.
    func update(_ request: Request, _ body: ProductUpdateBody)throws -> Future<ProductResponseBody> {
        
        // Get the model to update from the request's route parameters.
        let product = try request.parameter(Product.self)
        
        // Get all models that have an ID in any if the request bodies' arrays.
        let detachAttributes = Attribute.query(on: request).models(where: \Attribute.id, in: body.attributes?.delete)
        let attachAttributes = Future.map(on: request) { body.attributes?.create ?? [] }
        
        let detachCategories = Category.query(on: request).models(where: \Category.id, in: body.categories?.detach)
        let attachCategories = Category.query(on: request).models(where: \Category.id, in: body.categories?.attach)
        
        // Attach and detach the models fetched with the ID arrays.
        // This means we either create or delete a row in a pivot table.
        let attributes = Async.flatMap(to: Void.self, product, detachAttributes, attachAttributes) { (product, detach, attach) in
            let detached = try detach.map({ try product.attributes(on: request).detach($0, on: request) }).flatten(on: request)
            let attached = try attach.map({ try Attribute(name: $0.name, value: $0.value, productID: product.requireID()).save(on: request) }).flatten(on: request).transform(to: ())
            
            // This syntax allows you to complete the current future
            // when both of the futures in the array are complete.
            return [detached, attached].flatten(on: request)
        }
        
        
        let categories = Async.flatMap(to: Void.self, product, detachCategories, attachCategories) { (product, detach, attach) in
            let detached = detach.map({ product.categories.detach($0, on: request) }).flatten(on: request)
            let attached = try attach.map({ try ProductCategory(product: product, category: $0).save(on: request) }).flatten(on: request).transform(to: ())
            return [detached, attached].flatten(on: request)
        }
        
        // Once all the attaching/detaching is complete, convert the updated model to a `ProductResponseBody` and return it.
        return Async.flatMap(to: ProductResponseBody.self, attributes, categories, { _, _ in
            return product.response(on: request)
        })
    }
    
    // Deletes a `Product` model from that database and returns an HTTP status.
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        
        // Get the model from the route paramaters,
        // delete it from the database, and return HTTP status 204 (No Content).
        return try request.parameter(Product.self).delete(on: request).transform(to: .noContent)
    }
}
