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
    
    func show(_ request: Request)throws -> Future<Attribute> {
        return try request.parameters.next(Attribute.self)
    }
    
    func update(_ request: Request, _ body: AttributeBody)throws -> Future<Attribute> {
        return try request.parameters.next(Attribute.self).flatMap(to: Attribute.self) { attribute in
            attribute.name = body.name ?? attribute.name
            attribute.type = body.type ?? attribute.type
            return attribute.update(on: request)
        }
    }
    
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        return try request.parameters.next(Attribute.self).delete(on: request).transform(to: .noContent)
    }
}

struct AttributeBody: Content {
    let name: String?
    let type: String?
}
