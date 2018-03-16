typealias ProductTranslationController = TranslationPivotController<Product, ProductTranslation>
typealias CategoryTranslationController = TranslationPivotController<Category, CategoryTranslation>

final class TranslationPivotController<Parent, Translation>: RouteCollection
where Parent: MySQLModel & Parameter & TranslationParent, Parent.ResolvedParameter == Future<Parent>, Translation == Parent.TranslationType {
    typealias Pivot = ModelTranslation<Parent, Translation>
    
    func boot(router: Router) throws {
        router.get(use: index)
        router.post(use: add)
        router.delete(Translation.parameter, use: remove)
    }
    
    func index(_ request: Request)throws -> Future<[TranslationResponseBody]> {
        return try request.parameter(Parent.self).flatMap(to: [Translation].self, { (parent) in
            let translations = parent.translations
            return try translations.query(on: request).all()
        }).flatMap(to: [TranslationResponseBody].self, { (tranlations) in
            return tranlations.map({ $0.response(on: request) }).flatten()
        })
    }
    
    func add(_ request: Request)throws -> Future<TranslationResponseBody> {
        let parent = try request.parameter(Parent.self)
        let translation = request.content.get(String.self, at: "translation_name").flatMap(to: Translation.self) { (name) in
            return Translation.find(name, on: request).unwrap(or: Abort(.badRequest, reason: "No translation found with name '\(name)'"))
        }
        
        return flatMap(to: TranslationResponseBody.self, parent, translation) { (parent, translation) in
            return try Pivot(parent: parent, translation: translation).save(on: request).transform(to: translation).response(on: request)
        }
    }
    
    func remove(_ request: Request)throws -> Future<HTTPStatus> {
        let product = try request.parameter(Parent.self)
        let translation = try request.parameter(Translation.self)
        
        return flatMap(to: HTTPStatus.self, product, translation, { (product, translation) in
            let detached = product.translations.detach(translation, on: request)
            return detached.transform(to: .noContent)
        })
    }
}
