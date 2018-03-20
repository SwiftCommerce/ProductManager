struct CategoryUpdateBody: Content {
    let attach: [Category.ID]?
    let detach: [Category.ID]?
}

final class CategoryController: RouteCollection {
    func boot(router: Router) throws {
        let categories = router.grouped("categories")
        
        categories.post(use: create)
        
        categories.get(use: index)
        categories.get(Category.parameter, use: show)
        
        categories.patch(CategoryUpdateBody.self, at: Category.parameter, use: update)
        
        categories.delete(Category.parameter, use: delete)
    }
    
    func create(_ request: Request)throws -> Future<CategoryResponseBody> {
        let name = request.content.get(String.self, at: "name")
        return name.map(to: Category.self, { Category(name: $0) }).save(on: request).response(with: request)
    }
    
    func index(_ request: Request)throws -> Future<[CategoryResponseBody]> {
        return Category.query(on: request).all().flatMap(to: [CategoryResponseBody].self, { (categories) in
            categories.map({ Future(category: $0, executedWith: request) }).flatten()
        })
    }
    
    func show(_ request: Request)throws -> Future<CategoryResponseBody> {
        return try request.parameter(Category.self).response(with: request)
    }
   
    func update(_ request: Request, _ categories: CategoryUpdateBody)throws -> Future<CategoryResponseBody> {
        let attach = Category.query(on: request).filter(\.id, in: categories.attach ?? []).all()
        let detach = Category.query(on: request).filter(\.id, in: categories.detach ?? []).all()
        let category = try request.parameter(Category.self)
        return Async.flatMap(to: Category.self, category, attach, detach) { (category, attach, detach) in
            let detached = detach.map({ category.subCategories.detach($0, on: request) }).flatten()
            let attached = try attach.map({ try CategoryPivot(category, $0).save(on: request) }).flatten().transform(to: ())
            return [detached, attached].flatten().transform(to: category)
        }.response(with: request)
    }
    
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        return try request.parameter(Category.self).flatMap(to: Category.self, { (category) in
            let detachCategories = category.subCategories.deleteConnections(on: request)
            let detachProducts = category.products.deleteConnections(on: request)
            return [detachCategories, detachProducts].flatten().transform(to: category)
        }).flatMap(to: HTTPStatus.self, { (cateogory) in
            return cateogory.delete(on: request).transform(to: .noContent)
        })
    }
}
