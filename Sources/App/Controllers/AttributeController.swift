import FluentMySQL
import Vapor

final class AttributeController: RouteCollection {
    func boot(router: Router) throws {}
    
    func create(_ request: Request, _ attribute: Attribute)throws -> Future<Attribute> {
        return attribute.save(on: request)
    }
    
    func index(_ request: Request)throws -> Future<[Attribute]> {
        return Attribute.query(on: request).all()
    }
}
