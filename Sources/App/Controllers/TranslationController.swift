import Vapor

final class TranslationController: RouteCollection {
    func boot(router: Router) throws {
        try router.grouped("products", Product.parameter, "translations").register(collection: ProductTranslationController())
        try router.grouped("categories", Category.parameter, "translations").register(collection: CategoryTranslationController())
    }
}

final class ModelTranslationController<Translation>: RouteCollection where Translation: App.Translation {
    func boot(router: Router) throws {}
}
