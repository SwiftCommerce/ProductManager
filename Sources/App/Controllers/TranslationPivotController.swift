/// A static type declaration of `TranslationPivotController`,
/// with `Product` as the `Parent` type and `ProductTranslation` as the `Translation` type.
typealias ProductTranslationController = TranslationPivotController<Product, ProductTranslation>

/// A static type declaration of `TranslationPivotController`,
/// with `Category` as the `Parent` type and `CategoryTranslation` as the `Translation` type.
typealias CategoryTranslationController = TranslationPivotController<Category, CategoryTranslation>

/// A controller for connections between a parent type and its connected translations type.
///
/// - The `Parent` type must conform to `MySQLModel`, `Parameter`, and `TranslationParent`.
/// - The `Parent.ResolvedParameter` type must be equal to `Future<Parent>`.
/// - The `Translation` type must be equal to `Parent.Translation` and conform to `TranslationRequestInitializable`.
final class TranslationPivotController<Parent, Translation>: RouteCollection
where Parent: MySQLModel & Parameter & TranslationParent, Parent.ResolvedParameter == Future<Parent>, Translation == Parent.Translation, Translation: TranslationRequestInitializable {
    
    /// The root path element of the router group for the controller instance.
    let root: String
    
    ///
    init(root: String) { self.root = root }
    
    /// Required by the `RouteCollection` protocol.
    /// Allows you to run this to add your routes to a router:
    ///
    ///     router.register(collection: TranslationPivotController<Parent, Translation>())
    ///
    /// - parameter router: The router that the controller's routes will be registered to.
    func boot(router: Router) throws {
        let translations = router.grouped(self.root, Parent.parameter, "translations")
        
        // Registers a GET route at `/` with the router.
        translations.get(use: index)
        
        // Registers a POST route at `/` with the router.
        translations.post(TranslationRequestContent.self, at: self.root, "translations", use: add)
        
        // Registers a DELETE route at /:tranalation` with the router.
        translations.delete(Translation.parameter, use: remove)
    }
    
    /// Gets all `Translation` models connected to the `Parent` model.
    func index(_ request: Request)throws -> Future<[TranslationResponseBody]> {
        
        // Get `Parent` model from request route paramaters.
        return try request.parameter(Parent.self).flatMap(to: [Translation].self, { (parent) in
            
            // Get all translations connected to the parent.
            let translations = try parent.translations(on: request)
            return translations.all()
        }).flatMap(to: [TranslationResponseBody].self, { (tranlations) in
            
            // Loop over all translations, converting each one to a `TranslationResponseBody`.
            return tranlations.map({ $0.response(on: request) }).flatten(on: request)
        })
    }
    
    /// Add a new `Translation` model with a given name to a `Product` model.
    func add(_ request: Request, _ content: TranslationRequestContent)throws -> Future<TranslationResponseBody> {
        
        // Create a `Translation` instance from the request's body,
        // save it to the database, and convert it to a `TranslationResponseBody`.
        return try Translation.create(from: content, with: request).save(on: request).response(on: request)
    }
    
    /// Detach a `Translation` model from a `Parent` model.
    func remove(_ request: Request)throws -> Future<HTTPStatus> {
        
        // Get the models from the request route parameters.
        let product = try request.parameter(Parent.self)
        let translation = try request.parameter(Translation.self)
        
        return flatMap(to: HTTPStatus.self, product, translation, { (product, translation) in
            
            // Detach the translation from the prodcut (by deleteing the pivot).
            let detached = try product.translations(on: request).filter(\.name == translation.name).delete()
            
            // Once the model are detahced, return HTTP status 204 (No Content)
            // signalling succesful deltetion.
            return detached.transform(to: .noContent)
        })
    }
}
