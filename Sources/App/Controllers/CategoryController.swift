final class CategoryController: RouteCollection {
    func boot(router: Router) throws {
        let categories = router.grouped("categories")
        
        categories.get(use: index)
        categories.get(Category.parameter, use: show)
        
        categories.post(use: create)
    }
    
    func index(_ request: Request)throws -> Future<[CategoryResponseBody]> {
        return Category.query(on: request).all().flatMap(to: [CategoryResponseBody].self, { (categories) in
            categories.map({ Future(category: $0, executedWith: request) }).flatten()
        })
    }
    
    func show(_ request: Request)throws -> Future<CategoryResponseBody> {
        return try request.parameter(Category.self).response(with: request)
    }
    
    func create(_ request: Request)throws -> Future<CategoryResponseBody> {
        let name = request.content.get(String.self, at: "name")
        return name.map(to: Category.self, { Category(name: $0) }).save(on: request).response(with: request)
    }
}
