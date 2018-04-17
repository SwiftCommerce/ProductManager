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
    
    /// A wrapper type, allowing the request's body to have a nested strcuture:
    ///
    ///     {
    ///       "prices": {"attach": [], "detach": []}
    ///     }
    struct PricesUpdate: Content {
        
        /// The IDs of the `Price` model to attach to the `Product` model.
        let attach: [Price.ID]?
        
        /// The IDs of the `Price` model to dettach from the `Product` model.
        let detach: [Price.ID]?
    }
    
    /// A decoded JSON object to get the IDs of `Attribute` models
    /// to attach to and detach from the product.
    let attributes: AttributeUpdate?
    
    /// A decoded JSON object to get the IDs of `Category` models
    /// to attach to and detach from the product.
    let categories: CategoryUpdateBody?
    
    /// A decoded JSON object to get the IDs of `Price` models
    /// to attach to and detach from the product model.
    let prices: PricesUpdate?
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
        
        fatalError()
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
        
        return futureCategories.each(to: [Product].self) { (category) in
            
            // Get all the `Product` models that are connected to the categories.
            return try category.products.query(on: request).all()
        }
            
        // Flatten the 2D array to products to a 1D array.
        .map(to: [Product].self) { $0.flatMap({ $0 }) }
            
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
        
        let detachPrices = Price.query(on: request).models(where: \Price.id, in: body.prices?.detach)
        let attachPrices = Price.query(on: request).models(where: \Price.id, in: body.prices?.attach)
        
        // Attach and detach the models fetched with the ID arrays.
        // This means we either create or delete a row in a pivot table.
        let attributes = Async.flatMap(to: Void.self, product, detachAttributes, attachAttributes) { (product, detach, attach) in
            let detached = detach.map({ product.attributes.detach($0, on: request) }).flatten(on: request)
            let attached = try attach.map({ try Attribute(name: $0.name, type: $0.value).save(on: request) }).flatten(on: request).transform(to: ())
            
            // This syntax allows you to complete the current future
            // when both of the futures in the array are complete.
            return [detached, attached].flatten(on: request)
        }.transform(to: ())
        
        let categories = Async.flatMap(to: Void.self, product, detachCategories, attachCategories) { (product, detach, attach) in
            let detached = detach.map({ product.categories.detach($0, on: request) }).flatten(on: request)
            let attached = try attach.map({ try ProductCategory(product: product, category: $0).save(on: request) }).flatten(on: request).transform(to: ())
            return [detached, attached].flatten(on: request)
        }.transform(to: ())
        
        let prices = Async.flatMap(to: Void.self, product, detachPrices, attachPrices) { (product, detach, attach) in
            let detached = detach.map({ product.prices.detach($0, on: request) }).flatten(on: request)
            let attached = try attach.map({ try ProductPrice(product: product, price: $0).save(on: request) }).flatten(on: request).transform(to: ())
            return [detached, attached].flatten(on: request)
        }.transform(to: ())
        
        // Once all the attaching/detaching is complete, convert the updated model to a `ProductResponseBody` and return it.
        return [attributes, categories, prices].flatten(on: request).flatMap(to: ProductResponseBody.self) {
            return product.response(on: request)
        }
    }
    
    // Deletes a `Product` model from that database and returns an HTTP status.
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        
        // Get the model from the route paramaters,
        // delete it from the database, and return HTTP status 204 (No Content).
        return try request.parameter(Product.self).delete(on: request).transform(to: .noContent)
    }
}
