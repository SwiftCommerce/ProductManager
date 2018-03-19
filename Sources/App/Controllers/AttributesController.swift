import Async

final class AttributesController: RouteCollection {
    func boot(router: Router) throws {
        let attributes = router.grouped("products", Product.parameter, "attributes")
        
        attributes.post(Attribute.self, use: create)
        
        attributes.get(use: index)
        attributes.get(Int.parameter, use: show)
        
        attributes.patch(Int.parameter, use: update)
        
        attributes.delete(Attribute.parameter, use: delete)
    }
    
    func create(_ request: Request, _ attribute: Attribute)throws -> Future<Attribute> {
        return Attribute.query(on: request).filter(\.name == attribute.name).count().flatMap(to: Attribute.self) { (attributeCount) in
            guard attributeCount < 1 else {
                throw Abort(.badRequest, reason: "Attribute already exists for product with name '\(attribute.name)'")
            }
            return attribute.save(on: request)
        }
    }
    
    func index(_ request: Request)throws -> Future<[Attribute]> {
        return try request.parameter(Product.self).flatMap(to: [Attribute].self, { try $0.attributes.query(on: request).all() })
    }
    
    func show(_ request: Request)throws -> Future<Attribute> {
        return try request.parameter(Product.self).flatMap(to: Attribute.self) { (product) in
            let id = try request.parameter(Int.self)
            return try product.attributes.query(on: request).filter(\.id == id).first().unwrap(or: Abort(.notFound, reason: "No attribute connected to product with ID '\(id)'"))
        }
    }
    
    func update(_ request: Request)throws -> Future<Attribute> {
        let product = try request.parameter(Product.self)
        let newValue = request.content.get(String.self, at: "value")
        
        return flatMap(to: Attribute.self, product, newValue, { (product, newValue) in
            let id = try request.parameter(Int.self)
            return try product.attributes.query(on: request).filter(\.id == id).set(\.value, to: newValue)
        })
    }
    
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self, request.parameter(Product.self), request.parameter(Attribute.self), { (product, attribute) in
            let attributes = product.attributes
            return attributes.detach(attribute, on: request).transform(to: .noContent)
        })
    }
}


