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
        
        // Registers a PATCH route at `/products/translations/:product_translation/price` with the router.
        // This route automatically decodes the request's body to a `PriceUpdateBody` instance.
        router.patch(PriceUpdateBody.self, at: "products", "translations", ProductTranslation.parameter, "price", use: updatePrice)
    }
    
    /// Updates the data of the `Price` model connected to a `ProdcutTranslation`.
    /// We place this handler in the `TranslationController` because we only want one route with this action.
    func updatePrice(_ request: Request, _ body: PriceUpdateBody)throws -> Future<Price> {
        
        // Get the translation model from the route's parameters.
        return try request.parameter(ProductTranslation.self).flatMap(to: Price.self, { (translation) in
            
            // Verfiy that the translation has a price ID.
            guard let price = translation.priceId else {
                throw Abort(.notFound, reason: "The given translation does not have a price conected to it")
            }
            
            // Get the `Price` model with the ID from the translation.
            return try Price.query(on: request).filter(\.id == price).first().unwrap(or: Abort(.internalServerError, reason: "Bad price ID connected to translation"))
        }).flatMap(to: Price.self, { (price) in
            
            // Updated the `Prioce` model's data and return the object.
            return price.update(with: body, on: request).transform(to: price)
        })
    }
}

/// A controller for API endpoints that run operations on a model's translations.
///
/// - The `Translation` type must conform to `App.Translation` and `TranslationRequestInitializable`.
/// - The `Parent` type must conform to `MySQLModel`.
final class ModelTranslationController<Translation, Parent>: RouteCollection where Translation: App.Translation & TranslationRequestInitializable, Parent: MySQLModel {
    
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
        translations.post(TranslationRequestContent.self, use: create)
        
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
    func create(_ request: Request, _ body: TranslationRequestContent)throws -> Future<TranslationResponseBody> {
        
        // Create a new `Translation` with the request and its body.
        return try Translation.create(from: body, with: request).response(on: request)
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
        return try request.parameter(Translation.self).response(on: request)
    }
    
    /// Updates the data of a ` Translation` model.
    func update(_ request: Request, _ body: TranslationUpdateBody)throws -> Future<TranslationResponseBody> {
        
        // Get the model from the route paramaters.
        return try request.parameter(Translation.self).flatMap(to: TranslationResponseBody.self, { (translation) in
            
            // Update the models properties from data in the request's body.
            translation.languageCode = body.languageCode ?? translation.languageCode
            translation.description = body.description ?? translation.description
            
            // If the model we are updating is a `ProductTranslation`, update its `priceId` property.
            if let productTranslation = translation as? ProductTranslation {
                productTranslation.priceId = body.priceId            
            }
            
            // Save the updated model to the database and convert it to a `TranslationResponseBody` object.
            return translation.save(on: request).response(on: request)
        })
    }
    
    /// Deletes a `Translation` model and its connections to other models.
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        
        // Get the model from the route parameters
        let translation = try request.parameter(Translation.self)
        return translation.flatMap(to: Translation.self) { (translation) in
            
            // Place the resulting futures of deletions in this array,
            // so we can call `.flatten` and know when all the futures have complete.
            var deletions: [Future<Void>] = []
            
            // Delete the connections to the model's respective parent models.
            // If the model is a `ProductTranslation` model, delete its connection to its `Price` model.
            if let productTranslation = translation as? ProductTranslation {
                if let price = productTranslation.priceId {
                    try deletions.append(Price.query(on: request).filter(\.id == price).delete())
                }
            }
            
            // Once the connection deletions have complete, return the `Translation` model.
            return deletions.flatten(on: request).transform(to: translation)
        }.flatMap(to: HTTPStatus.self, { translation in
            
            // Delete the model and return HTTP status 204 (No Content).
            return translation.delete(on: request).transform(to: .noContent)
        })
    }
}
