import FluentMySQL
import Vapor

final class PriceController: RouteCollection {
    
    /// Required by the `RouteCollection` protocol,
    /// this method allows us to register our controller using:
    ///
    ///     route.register(collection: PriceController())
    ///
    /// - parameter router: The router to register all the controllers
    ///   with, using `/price` as their sub-path.
    func boot(router: Router) throws {
        
        // We create a router group with a root path of `/prices`
        // because all routes will start with the same path.
        let prices = router.grouped(Product.parameter, "prices")
        
        // Create a POST route at `/prices`
        prices.post(PriceContent.self, use: create)
        
        // Create a GET route at `/prices`
        prices.get(use: index)
        
        // Create a GET route at `/prices/:price`
        prices.get(Price.parameter, use: show)
        
        // Creates a PATCH route at `/prices.:price`.
        // The route will automaticlly decodes
        // the request body to a `PriceUpdateBody`
        prices.patch(PriceUpdateBody.self, at: Price.parameter, use: update)
        
        // Creates a DELETE route at `/prices/:price`.
        prices.delete(Price.parameter, use: delete)
    }
    
    /// Takes a `Price` model decoded from a request
    /// and saves it to the database
    func create(_ request: Request, _ contents: PriceContent)throws -> Future<Price> {
        let product = try request.parameters.id(for: Product.self)
        let price = try Price(content: contents, product: product)
        return price.save(on: request)
    }
    
    /// Gets all the `Price` models from the database
    func index(_ request: Request)throws -> Future<[Price]> {
        let product = try request.parameters.id(for: Product.self)
        return Price.query(on: request).filter(\.productID == product).all()
    }
    
    /// Gets a single `Price` model from the database,
    /// based on its ID
    func show(_ request: Request)throws -> Future<Price> {
        
        // Get the product the `Price` model is connected to.
        //
        // We can't extract the ID because the parameters won't advance and we won't be able to access the `Price` ID.
        return try request.parameters.next(Product.self).flatMap { product in
            
            // Get the ID of the `Price` model to fetch from the request paramaters.
            let price = try request.parameters.id(for: Price.self)
            
            // Get the `Price` model with a matching ID and `Product` ID from the databse and unwrap it. Throw a 404 if we get `nil`.
            return try Price.query(on: request).filter(\.productID == product.requireID()).filter(\.id == price).first().unwrap(or: Abort(.notFound))
        }
    }
    
    /// Updates tha values of a `Price` model that are found in the request body.
    func update(_ request: Request, _ content: PriceUpdateBody)throws -> Future<Price> {
        
        // Get the product the `Price` model is connected to.
        //
        // We can't extract the ID because the parameters won't advance and we won't be able to access the `Price` ID.
        return try request.parameters.next(Product.self).flatMap { product in
            
            // Get the ID of the `Price` model to fetch from the request paramaters.
            let id = try request.parameters.id(for: Price.self)
            
            // Get the `Price` model with a matching ID and `Product` ID from the databse and unwrap it. Throw a 404 if we get `nil`.
            let price = try Price.query(on: request).filter(
                \.productID == product.requireID()
            ).filter(
                \.id == id
            ).first().unwrap(or: Abort(.notFound))
            
            // Update the model's properties that have new values and save it.
            return price.map { $0.update(with: content) }.update(on: request)
        }
    }
    
    /// Deletes a `Price` model from the database with a given ID.
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        
        // Get the product the `Price` model is connected to.
        //
        // We can't extract the ID because the parameters won't advance and we won't be able to access the `Price` ID.
        return try request.parameters.next(Product.self).flatMap { product in
            
            // Get the ID of the `Price` model to fetch from the request paramaters.
            let price = try request.parameters.id(for: Price.self)
            
            return try Price.query(on: request).filter(\.productID == product.requireID()).filter(\.id == price).delete().transform(to: .noContent)
        }
    }
}
