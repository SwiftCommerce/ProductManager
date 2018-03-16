import Vapor

final class TranslationController: RouteCollection {
    func boot(router: Router) throws {
        try router.grouped("products", Product.parameter).register(collection: ProductTranslationController())
        try router.grouped("categories", Category.parameter).register(collection: CategoryTranslationController())
    }
}

final class ProductTranslationController: RouteCollection {
    func boot(router: Router) throws {}
}

final class CategoryTranslationController: RouteCollection {
    func boot(router: Router) throws {}
}
