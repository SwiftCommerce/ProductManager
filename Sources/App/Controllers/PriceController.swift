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
        
        // Create a GET route at `/prices`
        prices.get(use: index)
    }
    
    /// Gets all the `Price` models from the database
    func index(_ request: Request)throws -> Future<[Price]> {
        return Price.query(on: request).all()
    }
}
