import FluentMySQL
import FluentSQL
import Vapor

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
        router.patch(ProductUpdateContent.self, at: Product.parameter, use: update)
        
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
    func index(_ request: Request)throws -> Future<SearchResult> {
        return Product.search(on: request)
    }
    
    /// Get the `Product` model from the database with a given ID.
    func show(_ request: Request)throws -> Future<ProductResponseBody> {
        
        // Get the specified model from the route's paramaters
        // and convert it to a `ProductResponseBody`
        return try request.parameters.next(Product.self).response(on: request)
    }
    
    /// Updates to pivots that connect a `Product` model to other models.
    func update(_ request: Request, _ body: ProductUpdateContent)throws -> Future<ProductResponseBody> {
        
        // Get the model to update from the request's route parameters.
        let product = try request.parameters.next(Product.self)
        
        // Update the product with the request body and save it.
        return product.map(body.update).save(on: request).response(on: request)
    }
    
    // Deletes a `Product` model from that database and returns an HTTP status.
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        
        // Get the model from the route paramaters,
        // delete it from the database, and return HTTP status 204 (No Content).
        return try request.parameters.next(Product.self).delete(on: request).transform(to: .noContent)
    }
}
