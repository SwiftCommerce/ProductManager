/// Used for categorizing a product.
final class Category: Content, MySQLModel, Migration, Parameter {
    
    /// The database ID of the model.
    var id: Int?
    
    /// How high in a list of categories
    /// this instance should appear.
    var sort: Int
    
    /// A flag that declares the category being
    /// a top-level category and not a sub-category.
    var isMain: Bool
    
    /// The name of the category.
    let name: String
    
    ///
    init(name: String, sort: Int, isMain: Bool) {
        self.name = name
        self.sort = sort
        self.isMain = isMain
    }
    
    /// Gets all the categories translations.
    ///
    /// - parameter executor: The object used to run the query for getting the translations.
    /// - returns: All the translations that are connected to the category through pivot models.
    func translations(with executor: DatabaseConnectable) -> Future<[CategoryTranslation]> {
        
        // Verfiy the model has an ID.
        return self.assertID(on: executor).flatMap(to: [CategoryTranslation].self, { (id) in
            
            // Fetch and return connected translations.
            return try self.translations(on: executor).all()
        })
    }
}

// MARK: - Public

/// A representation of a `Category` model including sub-categories and translations.
/// Returned from a route handler instead of a raw category for full data representation.
struct CategoryResponseBody: Content {
    
    ///
    let id: Int?
    
    ///
    let name: String
    
    ///
    let sort: Int
    
    ///
    let isMain: Bool
    
    ///
    let subcategories: [CategoryResponseBody]
    
    ///
    let translations: [TranslationResponseBody]
}

/// Extend `Promise` if it wraps a `CategoryResponseBody`.
extension Promise where T == CategoryResponseBody {
    
    /// Creates a `CategoryResponseBody` from a `Category`.
    /// The result is wrapped in a promise because we run database queries in the `init`.
    ///
    /// - parameters:
    ///   - category: The category model to get the information to populate the struct with.
    ///   - executor: The object to use to run the queries that will fetch the models connected to the category.
    /// - returns: A `CategoryResponseBody` populated with data from the category passed in, wrapped in a `Promise`.
    init(category: Category, on request: Request) {
        
        // Create a new promise from the request's event loop.
        // We don't assign to self yet because we can't call `.succeed` on `self`.
        let result = request.eventLoop.newPromise(CategoryResponseBody.self)
        
        // Wrap the body of the method in a do/catch to remove the need for the method to throw.
        do {
            
            // Get all the sub-categories connected to the category passed in.
            let categories = try category.subCategories.query(on: request).sort(\.sort, .ascending).all().each(to: CategoryResponseBody.self) { category in
                return Promise(category: category, on: request).futureResult
            }
            
            // Get the sub-categories and translations, convert them to a `CategoryResponseBody`, and assign self.
            Async.map(to: CategoryResponseBody.self, categories, category.translations(with: request)) { (subCategories, translations) in
                
                // Actually create the `CategoryResponseBody` with the data passed in.
                return CategoryResponseBody(
                    id: category.id,
                    name: category.name,
                    sort: category.sort,
                    isMain: category.isMain,
                    subcategories: subCategories,
                    translations: translations.map({ TranslationResponseBody($0) })
                )
            }.do { (body) in
                
                // `CategoryResponseBody` creation succeded.
                // Succeed the promise with the new value.
                result.succeed(result: body)
            }.catch { (error) in
                
                // An error occured somewhere. Fail the promise.
                result.fail(error: error)
            }
        } catch {
            
            // An error occured while getting the categories sub-categories.
            // Fail the promise.
            result.fail(error: error)
        }
        
        self = result
    }
}
