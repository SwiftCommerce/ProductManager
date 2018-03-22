struct TranslationUpdateBody: Content {
    let languageCode: String?
    let description: String?
    let priceId: Int?
}

final class TranslationController: RouteCollection {
    func boot(router: Router) throws {
        try router.grouped("products", Product.parameter, "translations").register(collection: ProductTranslationController())
        try router.grouped("categories", Category.parameter, "translations").register(collection: CategoryTranslationController())
        try router.register(collection: ModelTranslationController<CategoryTranslation, Category>(root: "categories"))
        try router.register(collection: ModelTranslationController<ProductTranslation, Product>(root: "products"))
        
        router.patch(PriceUpdateBody.self, at: "products", "translations", ProductTranslation.parameter, "price", use: updatePrice)
    }
    
    func updatePrice(_ request: Request, _ body: PriceUpdateBody)throws -> Future<Price> {
        return try request.parameter(ProductTranslation.self).flatMap(to: Price.self, { (translation) in
            guard let price = translation.priceId else {
                throw Abort(.notFound, reason: "The given translation does not have a price conected to it")
            }
            return Price.query(on: request).filter(\.id == price).first().unwrap(or: Abort(.internalServerError, reason: "Bad price ID connected to translation"))
        }).flatMap(to: Price.self, { (price) in
            return price.update(with: body, on: request).transform(to: price)
        })
    }
}

final class ModelTranslationController<Translation, Parent>: RouteCollection where Translation: App.Translation & TranslationRequestInitializable, Parent: MySQLModel {
    let root: PathComponent
    
    init(root: String) {
        self.root = .constants([.string(root)])
    }
    
    func boot(router: Router) throws {
        let translations = router.grouped(self.root, "translations")
        
        translations.post(TranslationRequestContent.self, use: create)
        
        translations.get(use: index)
        translations.get(Translation.parameter, use: show)
        
        translations.patch(TranslationUpdateBody.self, at: Translation.parameter, use: update)
        
        translations.delete(Translation.parameter, use: delete)
    }
    
    func create(_ request: Request, _ body: TranslationRequestContent)throws -> Future<TranslationResponseBody> {
        return Translation.create(from: body, with: request)
    }
    
    func index(_ request: Request)throws -> Future<[TranslationResponseBody]> {
        return Translation.query(on: request).all().loop(to: TranslationResponseBody.self, transform: { (translation) in
            return translation.response(on: request)
        })
    }
    
    func show(_ request: Request)throws -> Future<TranslationResponseBody> {
        return try request.parameter(Translation.self).response(on: request)
    }
    
    func update(_ request: Request, _ body: TranslationUpdateBody)throws -> Future<TranslationResponseBody> {
        return try request.parameter(Translation.self).flatMap(to: TranslationResponseBody.self, { (translation) in
            translation.languageCode = body.languageCode ?? translation.languageCode
            translation.description = body.description ?? translation.description
            if let productTranslation = translation as? ProductTranslation {
                productTranslation.priceId = body.priceId            
            }
            return translation.save(on: request).response(on: request)
        })
    }
    
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        let translation = try request.parameter(Translation.self)
        return translation.flatMap(to: Void.self) { (translation) in
            var deletions: [Future<Void>] = []
            
            if let productTranslation = translation as? ProductTranslation {
                deletions.append(productTranslation.products.deleteConnections(on: request))
                if let price = productTranslation.priceId {
                    deletions.append(Price.query(on: request).filter(\.id == price).delete())
                }
            } else if let categoryTranslation = translation as? CategoryTranslation {
                deletions.append(categoryTranslation.categories.deleteConnections(on: request))
            } else {
                throw Abort(.internalServerError, reason: "Unsupported translation type found")
            }
            deletions.append(translation.delete(on: request).transform(to: ()))
            
            return deletions.flatten()
        }.transform(to: .noContent)
    }
}
