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
}
