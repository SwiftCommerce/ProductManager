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
        let prices = router.grouped("prices")
        
        // Create a POST route at `/prices`
        prices.post(Price.self, use: create)
        
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
    func create(_ request: Request, _ price: Price)throws -> Future<Price> {
        return price.save(on: request)
    }
    
    /// Gets all the `Price` models from the database
    func index(_ request: Request)throws -> Future<[Price]> {
        return Price.query(on: request).all()
    }
    
    /// Gets a single `Price` model from the database,
    /// based on its ID
    func show(_ request: Request)throws -> Future<Price> {
        
        // Gets the `Price` models ID from the route parameters
        // and get the model with that ID from the database
        return try request.parameter(Price.self)
    }
    
    /// Updates tha values of a `Price` model that are found in the request body.
    func update(_ request: Request, _ content: PriceUpdateBody)throws -> Future<Price> {
        
        // Gets the `Price` with the ID that is in the route's parameters
        return try request.parameter(Price.self).flatMap(to: Price.self) { price in
            
            // Update the model's properties that have new values and save it.
            return price.update(with: content).save(on: request)
        }
    }
    
    /// Deletes a `Price` model from the database with a given ID.
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        
        // Find the model with the ID in the route paramaters, delete it, and return a 204 (No Content) status code.
        return try request.parameter(Price.self).delete(on: request).transform(to: .noContent)
    }
}
