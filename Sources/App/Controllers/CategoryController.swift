final class CategoryController: RouteCollection {
    func boot(router: Router) throws {
        let categories = router.grouped("categories")
        
        categories.get(use: index)
        categories.get(Category.parameter, use: show)
    }
    
    func index(_ request: Request)throws -> Future<[CategoryResponseBody]> {
        return Category.query(on: request).all().flatMap(to: [CategoryResponseBody].self, { (categories) in
            categories.map({ Future(category: $0, executedWith: request) }).flatten()
        })
    }
    
    func show(_ request: Request)throws -> Future<CategoryResponseBody> {
        return try request.parameter(Category.self).response(with: request)
    }
}
