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
    
    /// That current state of the product.
    /// This could be `draft`, `published`, or one of other cases.
    var status: ProductStatus
    
    ///
    init(sku: String, status: ProductStatus) {
        self.sku = sku
        self.status = status
    }
    
    /// Gets all the `ProductTranslation` models connected to the current `Product` model through `ProductTranslationPivot`s.
    ///
    /// - Parameter executor: The object used to run the query to fetch the trsnlations from the database.
    /// - Returns: The related translations, wrapped in a future.
    func translations(with request: Request) -> Future<[ProductTranslation]> {
        
        // Confirm the model has in ID, return the results of the `.flatMap` callback.
        return self.assertID(on: request).flatMap(to: [ProductTranslation].self, { (id) in
            
            // Return all the `ProductTranslation`s connected to the current model through pivots.
            return try self.translations(on: request).all()
        })
    }
    
    /// Gets all the `Category` model that are connected to the current `Product` model though `ProductCategory` pivots.
    ///
    /// - Parameter executor: The object that will run the query to get all connected categories.
    /// - Returns: The related `Category` models, wrapped in a future.
    func categories(with request: Request) -> Future<[Category]> {
        
        // Return the result of the `flatMap` method's callback.
        // We use this static `.flatMap` method so we don't need to throw errors out of the `categories(with:)` method.
        return Future.flatMap(on: request, {
            
            // Return all the `Category` models connected to the current `Product` through pivots.
            return try self.categories.query(on: request).sort(\.sort, .ascending).all()
        })
    }
    
    /// Deletes all pivots to related models and deletes the current model.
    /// If the product's ID is `nil`, the returned future will automaticly complete
    /// because the model is assumed to have not been saved in the database.
    ///
    /// - Parameter executor: The object that will run the queries to delete the pivots and product.
    /// - Returns: A void future, which will complete when all deletions are complete.
    func delete(with request: Request) -> Future<Void> {
        
        // Verify the model has in ID, else return a completed void future.
        guard self.id != nil else { return Future.map(on: request, { () }) }
        
        // Wrap the deletion queries in a `flatMap` so the mehod doesn't have to throw.
        return Future.flatMap(on: request, { () in
            
            // Delete all connections to related models (categories, attributes, translations).
            return try Async.flatMap(
                to: Void.self,
                self.categories.deleteConnections(on: request),
                self.attributes.query(on: request).delete(),
                self.translations(on: request).delete()
            ) { _, _, _ in
                
                // Delete current product from database and return void,
                // signaling the product has been succesfuly deleted.
                return self.delete(on: request).transform(to: ())
            }
        })
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
    let status: ProductStatus
    
    ///
    let attributes: [Attribute]
    
    ///
    let translations: [TranslationResponseBody]
    
    ///
    let categories: [CategoryResponseBody]
    
    ///
    let prices: [Price]
}

/// Extend `Promise` if it wraps a `ProductResponseBody`.
extension Promise where T == ProductResponseBody {
    
    /// Creates a `ProductResponseBody` from a `Product`.
    /// We initialize it in a future because we have to run database
    /// queries to get data to populate the `ProductResponseBody`.
    ///
    /// - Parameters:
    ///   - product: The `Product` model to get the data to poulate the `ProductResponseBody` with.
    ///   - executor: The object that will run the queries to get the data connected to the product.
    init(product: Product, on request: Request) {
        let promise = request.eventLoop.newPromise(ProductResponseBody.self)
        
        // Wrap the whole body in a do/catch so the initializer doesn't have to throw.
        do {
            
            // Get all the attributes connected to the product.
            let attributes = try product.attributes.query(on: request).all()
            
            // Get all `Price` models connected to the product.
            let prices = try product.prices.query(on: request).all()
            
            // Get all the translations connected to the product and convert them to their response type.
            let translations = product.translations(with: request).flatMap(to: [TranslationResponseBody].self) { $0.map({ translation in
                return translation.response(on: request)
            }).flatten(on: request) }
            
            // Get all the categories connected to the product and convert them to their resonse type.
            let categories = product.categories(with: request).flatMap(to: [CategoryResponseBody].self) {
                $0.map({ Promise<CategoryResponseBody>(category: $0, on: request).futureResult }).flatten(on: request)
            }
            
            // Once all the queries have complete, take the data, create a `ProductResponseBody` from the data, and return it.
            Async.map(to: ProductResponseBody.self, attributes, translations, categories, prices) { (attributes, translations, categories, prices) in
                return ProductResponseBody(
                    id: product.id,
                    sku: product.sku,
                    status: product.status,
                    attributes: attributes,
                    translations: translations,
                    categories: categories,
                    prices: prices
                )
            }.do { (body) in
                
                // The `ProductResponseBody` was succesfuly created,
                // succeed the promise with it.
                promise.succeed(result: body)
            }.catch { (error) in
                
                // An error occured in the operation. Fail the promise.
                promise.fail(error: error)
            }
        } catch {
            
            // An error occured when getting the product's attributes
            // fail the promise with the error.
            promise.fail(error: error)
        }
        
        self = promise
    }
}
