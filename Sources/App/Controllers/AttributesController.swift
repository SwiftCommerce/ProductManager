final class AttributesController: RouteCollection {
    func boot(router: Router) throws {
        let attributes = router.grouped("products", Product.parameter, "attributes")
        
        attributes.get(use: index)
        
        attributes.post(Attribute.self, use: create)
    }
    
    func index(_ request: Request)throws -> Future<[Attribute]> {
        return try request.parameter(Product.self).flatMap(to: [Attribute].self, { $0.attributes(with: request) })
    }
    
    func create(_ request: Request, _ attribute: Attribute)throws -> Future<Attribute> {
        return attribute.save(on: request)
    }
}
