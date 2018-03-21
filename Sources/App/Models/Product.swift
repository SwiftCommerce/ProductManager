/// A representation of a store's product.
/// A `Product` stores a SKU (stock-keeping unit) as a string, to identify the tangible product.
/// A product is connected to 0 or more `Category` models to organize them.
/// A product is connected to 0 or more user-defined `Attribute` models to store custom data about the product.
/// A product is connected to 0 or more `Translation` models, whicg are each connected to a price for the product
/// in the currency of the location for the given translation.
final class Product: Content, MySQLModel, Migration, Parameter {
    
    /// The database ID of the model.
    var id: Int?
    
    /// The SKU (stock-keeping unit) of the tangible product this model represents.
    let sku: String
    
    ///
    init(sku: String) { self.sku = sku }
    
    /// Gets all the `ProductTranslation` models connected to the current `Product` model through `ProductTranslationPivot`s.
    ///
    /// - Parameter executor: The object used to run the query to fetch the trsnlations from the database.
    /// - Returns: The related translations, wrapped in a future.
    func translations(with executor: DatabaseConnectable) -> Future<[ProductTranslation]> {
        
        // Confirm the model has in ID, return the results of the `.flatMap` callback.
        return self.assertID().flatMap(to: [ProductTranslation].self, { (id) in
            
            // Return all the `ProductTranslation`s connected to the current model through pivots.
            return try self.translations.query(on: executor).all()
        })
    }
    
    /// Gets all the `Category` model that are connected to the current `Product` model though `ProductCategory` pivots.
    ///
    /// - Parameter executor: The object that will run the query to get all connected categories.
    /// - Returns: The related `Category` models, wrapped in a future.
    func categories(with executor: DatabaseConnectable) -> Future<[Category]> {
        
        // Return the result of the `flatMap` method's callback.
        // We use this static `.flatMap` method so we don't need to throw errors out of the `categories(with:)` method.
        return Future.flatMap({
            
            // Return all the `Category` models connected to the current `Product` through pivots.
            return try self.categories.query(on: executor).all()
        })
    }
    
    /// Deletes all pivots to related models and deletes the current model.
    /// If the product's ID is `nil`, the returned future will automaticly complete
    /// because the model is assumed to have not been saved in the database.
    ///
    /// - Parameter executor: The object that will run the queries to delete the pivots and product.
    /// - Returns: A void future, which will complete when all deletions are complete.
    func delete(with executor: DatabaseConnectable) -> Future<Void> {
        
        // Verify the model has in ID, else return a completed void future.
        guard self.id != nil else { return Future(()) }
        
        // Delete all connections to related models (categories, attributes, translations).
        return Async.flatMap(
            to: Void.self,
            self.categories.deleteConnections(on: executor),
            self.attributes.deleteConnections(on: executor),
            self.translations.deleteConnections(on: executor)
        ) { _, _, _ in
            
            // Delete current product from database and return void,
            // signaling the product has been succesfuly deleted.
            return self.delete(on: executor).transform(to: ())
        }
    }
}

// MARK: - Public

/// A representation of a product model containing data from connected models.
/// This model is returned from a route instead of a raw product,
/// Giving the client more information then just the `sku`.
struct ProductResponseBody: Content {
    
    ///
    let id: Int?
    
    ///
    let sku: String
    
    ///
    let attributes: [Attribute]
    
    ///
    let translations: [TranslationResponseBody]
    
    ///
    let categories: [CategoryResponseBody]
}

/// Extend `Future` if it wraps a `ProductResponseBody`.
extension Future where T == ProductResponseBody {
    
    /// Creates a `ProductResponseBody` from a `Product`.
    /// We initialize it in a future because we have to run database
    /// queries to get data to populate the `ProductResponseBody`.
    ///
    /// - Parameters:
    ///   - product: The `Product` model to get the data to poulate the `ProductResponseBody` with.
    ///   - executor: The object that will run the queries to get the data connected to the product.
    init(product: Product, executedWith executor: DatabaseConnectable) {
        
        /// Wrap the whole body in a `flatMap` so the initializer doesn't have to throw.
        self = Future.flatMap({
            
            /// Get all the attributes connected to the product.
            let attributes = try product.attributes.query(on: executor).all()
            
            /// Get all the translations connected to the product and convert them to their response type.
            let translations = product.translations(with: executor).flatMap(to: [TranslationResponseBody].self) { $0.map({ translation in
                return translation.response(on: executor)
            }).flatten() }
            
            /// Get all the categories connected to the product and convert them to their resonse type.
            let categories = product.categories(with: executor).flatMap(to: [CategoryResponseBody].self) {
                $0.map({ Future<CategoryResponseBody>(category: $0, executedWith: executor) }).flatten()
            }
            
            /// Once all the queries have complete, take the data, create a `ProductResponseBody` from the data, and return it.
            return Async.map(to: ProductResponseBody.self, attributes, translations, categories, { (attributes, translations, categories) in
                return ProductResponseBody(id: product.id, sku: product.sku, attributes: attributes, translations: translations, categories: categories)
            })
        })
    }
}
