import FluentMySQL
import FluentSQL
import Vapor

// MARK: - Request Body Type

/// A decoded request body used to
/// update a `Product` models connections to other models.
struct ProductUpdateBody: Content {
    
    /// A wrapper type, allowing the request's body to have a nested strcuture:
    ///
    ///     {
    ///       "prices": {"create": [], "delete": []}
    ///     }
    struct PricesUpdate: Content {
        
        /// The stricttre of the new `Price` child models for the `Product` model.
        let create: [PriceContent]?
        
        /// The IDs of the `Price` model to dettach from the `Product` model.
        let delete: [Price.ID]?
    }
    
    /// A decoded JSON object to get the IDs of `Category` models
    /// to attach to and detach from the product.
    let categories: CategoryUpdateBody?
    
    /// A decoded JSON object to get the IDs of `Price` models
    /// to attach to and detach from the product model.
    let prices: PricesUpdate?
}

// MARK: - Controller

/// A controller for API endpoints that make operations on the `products` database table.
final class ProductController: RouteCollection {
    
    /// Required by the `RouteCollection` protocol.
    /// Allows you to run this to add your routes to a router:
    ///
    ///     router.register(collection: ProductController())
    ///
    /// - parameter router: The router that the controller's routes will be registered to.
    func boot(router: Router) throws {
        
        // Registers a POST route at `/products` with the router.
        // This route automatically decodes the request's body to a `Prodcut` object.
        router.post(ProductContent.self, use: create)
        
        // Registers a GET route at `/products` with the router.
        router.get(use: index)
        
        // Registers a GET route at `/products/:product` with the router.
        router.get(Product.parameter, use: show)
        
        // Registers a PATCH route at `/products/:prodcut` with the router.
        // This route automatically decodes the request's body to a `ProductUpdateBody` object.
        router.patch(ProductUpdateBody.self, at: Product.parameter, use: update)
        
        // Registers a DELETE route at `/products/:product` with the router.
        router.delete(Product.parameter, use: delete)
    }
    
    /// Creates a new `Prodcut` model from the request's body
    /// and saves it to the database.
    func create(_ request: Request, _ contents: ProductContent)throws -> Future<ProductResponseBody> {
        
        // Save the `Product` model to the database.
        return Product(content: contents).save(on: request).flatMap { product in
            
            // Save the `Price` child models to the database, conenected to the newly saved `Product`.
            let prices = try contents.prices?.map { try Price(content: $0, product: product.requireID()) } ?? []
            
            // Convert the newly saved `Product` model to a `ProductResponseBody`.
            return prices.map { $0.save(on: request) }.flatten(on: request).transform(to: product).response(on: request)
        }
    }
    
    /// Get all the products from the database.
    func index(_ request: Request)throws -> Future<[ProductResponseBody]> {
        return Product.search(on: request).flatMap() { products in
            return products.map { Promise(product: $0, on: request).futureResult }.flatten(on: request)
        }
    }
    
    /// Get the `Product` model from the database with a given ID.
    func show(_ request: Request)throws -> Future<ProductResponseBody> {
        
        // Get the specified model from the route's paramaters
        // and convert it to a `ProductResponseBody`
        return try request.parameters.next(Product.self).response(on: request)
    }
    
    /// Updates to pivots that connect a `Product` model to other models.
    func update(_ request: Request, _ body: ProductUpdateBody)throws -> Future<ProductResponseBody> {
        
        // Get the model to update from the request's route parameters.
        let product = try request.parameters.next(Product.self)
        
        // Get all models that have an ID in any if the request bodies' arrays.
        let categoryIds = body.categories?.detach ?? []
        let categoryIds2 = body.categories?.attach ?? []
        let pricesDelete = body.prices?.delete ?? []
        let pricesCreate = body.prices?.create ?? []
        let detachCategories = Category.query(on: request).filter(\Category.id ~~ categoryIds).all()
        let attachCategories = Category.query(on: request).filter(\Category.id ~~ categoryIds2).all()
        
        // Attach and detach the models fetched with the ID arrays.
        // This means we either create or delete a row in a pivot table.
        let categories = Async.flatMap(to: Void.self, product, detachCategories, attachCategories) { (product, detach, attach) in
            let detached = detach.map { product.categories.detach($0, on: request) }.flatten(on: request)
            let attached = try attach.map { try ProductCategory(product: product, category: $0).save(on: request) }.flatten(on: request)
            
            return [detached, attached.transform(to: ())].flatten(on: request)
        }.transform(to: ())
        
        let prices = product.flatMap { product -> Future<Void> in
            let id = try product.requireID()
            let deleted = Price.query(on: request).filter(\.id ~~ pricesDelete).delete()
            let created = try pricesCreate.map { try Price(content: $0, product: id).save(on: request) }.flatten(on: request)
            
            return [deleted, created.transform(to: ())].flatten(on: request)
        }.transform(to: ())
        
        // Once all the attaching/detaching is complete, convert the updated model to a `ProductResponseBody` and return it.
        return [categories, prices].flatten(on: request).flatMap(to: ProductResponseBody.self) {
            return product.response(on: request)
        }
    }
    
    // Deletes a `Product` model from that database and returns an HTTP status.
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        
        // Get the model from the route paramaters,
        // delete it from the database, and return HTTP status 204 (No Content).
        return try request.parameters.next(Product.self).delete(on: request).transform(to: .noContent)
    }
}
