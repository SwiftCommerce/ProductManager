import Async

final class AttributesController: RouteCollection {
    func boot(router: Router) throws {
        let attributes = router.grouped("products", Product.parameter, "attributes")
        
        attributes.get(use: index)
        attributes.get(Int.parameter, use: show)
        
        attributes.post(Attribute.self, use: create)
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
    
    func create(_ request: Request, _ attribute: Attribute)throws -> Future<Attribute> {
        return Attribute.query(on: request).filter(\.name == attribute.name).count().flatMap(to: Attribute.self) { (attributeCount) in
            guard attributeCount < 1 else {
                throw Abort(.badRequest, reason: "Attribute already exists for product with name '\(attribute.name)'")
            }
            return attribute.save(on: request)
        }
    }
}


