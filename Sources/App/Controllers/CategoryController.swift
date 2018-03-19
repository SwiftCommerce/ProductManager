final class CategoryController: RouteCollection {
    func boot(router: Router) throws {
        let categories = router.grouped("categories")
        
        categories.get(use: index)
        categories.get(Category.parameter, use: show)
        
        categories.post(use: create)
        
        categories.delete(Category.parameter, use: delete)
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
    
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        return try request.parameter(Category.self).flatMap(to: Category.self, { (category) in
            return category.subCategories.deleteConnections(on: request).transform(to: category)
        }).flatMap(to: HTTPStatus.self, { (cateogory) in
            return cateogory.delete(on: request).transform(to: .noContent)
        })
    }
}
