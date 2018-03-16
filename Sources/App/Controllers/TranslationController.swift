import Vapor

final class TranslationController: RouteCollection {
    func boot(router: Router) throws {
        try router.grouped("products", Product.parameter, "translations").register(collection: ProductTranslationController())
        try router.grouped("categories", Category.parameter, "translations").register(collection: CategoryTranslationController())
    }
}

final class ProductTranslationController: RouteCollection {
    func boot(router: Router) throws {
        router.get(use: index)
        router.post(use: add)
        router.delete(ProductTranslation.parameter, use: remove)
    }
    
    func index(_ request: Request)throws -> Future<[TranslationResponseBody]> {
        return try request.parameter(Product.self).flatMap(to: [ProductTranslation].self, { (product) in
            return try product.translations.query(on: request).all()
        }).flatMap(to: [TranslationResponseBody].self, { (tranlations) in
            return tranlations.map({ $0.response(on: request) }).flatten()
        })
    }
    
    func add(_ request: Request)throws -> Future<TranslationResponseBody> {
        let product = try request.parameter(Product.self)
        let translation = request.content.get(String.self, at: "translation_name").flatMap(to: ProductTranslation.self) { (name) in
            return ProductTranslation.find(name, on: request).unwrap(or: Abort(.badRequest, reason: "No translation found with name '\(name)'"))
        }
        
        return flatMap(to: TranslationResponseBody.self, product, translation) { (product, translation) in
            return try ProductTranslationPivot(parent: product, translation: translation).save(on: request).transform(to: translation).response(on: request)
        }
    }
    
    func remove(_ request: Request)throws -> Future<HTTPStatus> {
        let product = try request.parameter(Product.self)
        let translation = try request.parameter(ProductTranslation.self)
        
        return flatMap(to: HTTPStatus.self, product, translation, { (product, translation) in
            let detached = product.translations.detach(translation, on: request)
            return detached.transform(to: .noContent)
        })
    }
}

final class CategoryTranslationController: RouteCollection {
    func boot(router: Router) throws {
        router.get(use: index)
        router.post(use: add)
        router.delete(CategoryTranslation.parameter, use: remove)
    }
    
    func index(_ request: Request)throws -> Future<[TranslationResponseBody]> {
        return try request.parameter(Category.self).flatMap(to: [CategoryTranslation].self, { (category) in
            return try category.translations.query(on: request).all()
        }).flatMap(to: [TranslationResponseBody].self, { (tranlations) in
            return tranlations.map({ $0.response(on: request) }).flatten()
        })
    }
    
    func add(_ request: Request)throws -> Future<TranslationResponseBody> {
        let category = try request.parameter(Category.self)
        let translation = request.content.get(String.self, at: "translation_name").flatMap(to: CategoryTranslation.self) { (name) in
            return CategoryTranslation.find(name, on: request).unwrap(or: Abort(.badRequest, reason: "No translation found with name '\(name)'"))
        }
        
        return flatMap(to: TranslationResponseBody.self, category, translation) { (category, translation) in
            return try CategoryTranslationPivot(parent: category, translation: translation).save(on: request).transform(to: translation).response(on: request)
        }
    }
    
    func remove(_ request: Request)throws -> Future<HTTPStatus> {
        let category = try request.parameter(Category.self)
        let translation = try request.parameter(CategoryTranslation.self)
        
        return flatMap(to: HTTPStatus.self, category, translation, { (category, translation) in
            let detached = category.translations.detach(translation, on: request)
            return detached.transform(to: .noContent)
        })
    }
}
