/// A decoded request body for updating a translation model's data.
struct TranslationUpdateBody: Content {
    
    /// The code for the language that translation is in.
    let languageCode: String?
    
    /// Some sort of description for the translation.
    let description: String?
    
    /// The ID of the `Price` model that is connected to the translation.
    let priceId: Int?
}

/// A parent controller for ` ModelTranslationController` and `TranslationPivotController`.
final class TranslationController: RouteCollection {
    
    /// Required by the `RouteCollection` protocol.
    /// Allows you to run this to add your routes to a router:
    ///
    ///     router.register(collection: TranslationController())
    ///
    /// - parameter router: The router that the controller's routes will be registered to.
    func boot(router: Router) throws {
        
        // Register the routes in the `ProductTranslationController` class with a root path `products`.
        try router.register(collection: ProductTranslationController(root: "products"))
        
        // Register the routes in the `CategoryTranslationController` class with a root path `categories`.
        try router.register(collection: CategoryTranslationController(root: "categories"))
        
        // Register the routes in `ModelTranslationController<CategoryTranslation, Category>` with a root path of `categories`.
        try router.register(collection: ModelTranslationController<CategoryTranslation, Category>(root: "categories"))
        
        // Register the routes in `ModelTranslationController<ProductTranslation, Product>` with a root path of `products`.
        try router.register(collection: ModelTranslationController<ProductTranslation, Product>(root: "products"))
    }
}

/// A controller for API endpoints that run operations on a model's translations.
///
/// - The `Translation` type must conform to `App.Translation` and `TranslationRequestInitializable`.
/// - The `Parent` type must conform to `MySQLModel`.
final class ModelTranslationController<Translation, Parent>: RouteCollection where Translation: App.Translation, Parent: MySQLModel {
    
    /// The top level path for all the controller's routes.
    let root: String
    
    /// Creates a `ModelTranslationController` instance with a top level path.
    ///
    /// - parameter root: The top level path for all the controller's routes.
    init(root: String) {
        
        self.root = root
    }
    
    /// Required by the `RouteCollection` protocol.
    /// Allows you to run this to add your routes to a router:
    ///
    ///     router.register(collection: TranslationPivotController<Parent, Translation>())
    ///
    /// - parameter router: The router that the controller's routes will be registered to.
    func boot(router: Router) throws {
        
        // Create a route group with tha path `/<root>/translation`
        // because all controller routes start with the same path.
        let translations = router.grouped(self.root, "translations")
        
        // Registers a POST route at `/<root>/translations` with the router.
        // This route automatically decodes the request body to a `TranslationRequestContent` object.
        translations.post(Translation.self, use: create)
        
        // Registers a GET route at `/<root>/translations` with the router.
        translations.get(use: index)
        
        // Registers a GET route at `/<root>/translations/:translation` with the router.
        translations.get(Translation.parameter, use: show)
        
        // Registers a PATCH route at `/<root>/translations/:translation` with the router.
        // This route automatically decodes the request's body to a `TranslationUpdateBody` object.
        translations.patch(TranslationUpdateBody.self, at: Translation.parameter, use: update)
        
        // Registers a DELETE route at `/<root>/translations/:translation` with the router.
        translations.delete(Translation.parameter, use: delete)
    }
    
    /// Creates a new `Translation` model and saves it to the database.
    func create(_ request: Request, _ translation: Translation)throws -> Future<TranslationResponseBody> {
        
        // Create a new `Translation` with the request and its body.
        return translation.save(on: request).response(on: request)
    }
    
    /// Gets all the `Translation` models from the database.
    func index(_ request: Request)throws -> Future<[TranslationResponseBody]> {
        
        // Fetch all `Translation` models from the database.
        return Translation.query(on: request).all().each(to: TranslationResponseBody.self, transform: { (translation) in
            
            // Iterate over each model and convert it to a `TranslationResponseBody`.
            return translation.response(on: request)
        })
    }
    
    /// Get a single `Translation` models with an ID from the route's parameters.
    func show(_ request: Request)throws -> Future<TranslationResponseBody> {
        
        // Get the `Translation` model from the route parameters and convert it to a `TranslationResponseBody`.
        return try request.parameters.next(Translation.self).response(on: request)
    }
    
    /// Updates the data of a ` Translation` model.
    func update(_ request: Request, _ body: TranslationUpdateBody)throws -> Future<TranslationResponseBody> {
        
        // Get the model from the route paramaters.
        return try request.parameters.next(Translation.self).flatMap(to: TranslationResponseBody.self, { (translation) in
            
            // Update the models properties from data in the request's body.
            translation.languageCode = body.languageCode ?? translation.languageCode
            translation.description = body.description ?? translation.description
            
            // Save the updated model to the database and convert it to a `TranslationResponseBody` object.
            return translation.save(on: request).response(on: request)
        })
    }
    
    /// Deletes a `Translation` model and its connections to other models.
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        
        // Get the model from the route parameters, delete the model, and return HTTP status 204 (No Content).
        return try request.parameters.next(Translation.self).delete(on: request).transform(to: .noContent)
    }
}
