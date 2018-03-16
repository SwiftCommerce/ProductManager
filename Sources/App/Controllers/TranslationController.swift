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
}

final class CategoryTranslationController: RouteCollection {
    func boot(router: Router) throws {}
}
