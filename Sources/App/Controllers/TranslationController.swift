import Vapor

final class TranslationController: RouteCollection {
    func boot(router: Router) throws {
        try router.grouped("products", Product.parameter).register(collection: ProductTranslationController())
        try router.grouped("categories", Category.parameter).register(collection: CategoryTranslationController())
    }
}

final class ProductTranslationController: RouteCollection {
    func boot(router: Router) throws {
        router.get(use: index)
    }
    
    func index(_ request: Request)throws -> Future<[TranslationResponseBody]> {
        return try request.parameter(Product.self).flatMap(to: [ProductTranslation].self, { (product) in
            return try product.translations.query(on: request).all()
        }).flatMap(to: [TranslationResponseBody].self, { (tranlations) in
            return tranlations.map({ $0.response(on: request) }).flatten()
        })
    }
}

final class CategoryTranslationController: RouteCollection {
    func boot(router: Router) throws {}
}
