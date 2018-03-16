import Vapor

final class TranslationController: RouteCollection {
    func boot(router: Router) throws {
        try router.grouped("products", Product.parameter, "translations").register(collection: ProductTranslationController())
        try router.grouped("categories", Category.parameter, "translations").register(collection: CategoryTranslationController())
    }
}

final class ModelTranslationController<Translation>: RouteCollection where Translation: App.Translation & TranslationRequestInitializable {
    let root: PathComponent
    
    init(root: String) {
        self.root = .constants([.string(root)])
    }
    
    func boot(router: Router) throws {
        let translations = router.grouped(self.root, "translations")
        
        translations.get(use: index)
        translations.get(Translation.parameter, use: show)
    }
    
    func index(_ request: Request)throws -> Future<[TranslationResponseBody]> {
        return Translation.query(on: request).all().loop(to: TranslationResponseBody.self, transform: { (translation) in
            return translation.response(on: request)
        })
    }
    
    func show(_ request: Request)throws -> Future<TranslationResponseBody> {
        return try request.parameter(Translation.self).response(on: request)
    }
}
