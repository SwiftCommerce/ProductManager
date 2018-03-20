/// Used for categorizing a product.
final class Category: Content, MySQLModel, Migration, Parameter {
    
    /// The database ID of the model.
    var id: Int?
    
    /// The name of the category.
    let name: String
    
    ///
    init(name: String) { self.name = name }
    
    /// Gets all the categories translations.
    ///
    /// - parameter executor: The object used to run the query for getting the translations.
    /// - returns: All the translations that are connected to the category through pivot models.
    func translations(with executor: DatabaseConnectable) -> Future<[CategoryTranslation]> {
        
        // Verfiy the model has an ID.
        return self.assertID().flatMap(to: [CategoryTranslation].self, { (id) in
            
            // Fetch and return connected translations.
            return try self.translations.query(on: executor).all()
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
    let subcategories: [CategoryResponseBody]
    
    ///
    let translations: [TranslationResponseBody]
}

/// Extend `Future` if it wrapps a `CategoryResponseBody`.
extension Future where T == CategoryResponseBody {
    
    /// Creates a `CategoryResponseBody` from a `Category`.
    /// The result is wrapped in a future because we run database queries in the `init`.
    ///
    /// - parameters:
    ///   - category: The category model to get the information to populate the struct with.
    ///   - executor: The object to use to run the queries that will fetch the models connected to the category.
    /// - returns: A `CategoryResponseBody` populated with data from the category passed in, wrapped in a `Future`.
    init(category: Category, executedWith executor: DatabaseConnectable) {
        
        /// Wrap the body of the method in a flat map to remove the need for the method to throw.
        self = Future.flatMap({
            
            /// Get all the sub-categories connected to the category passed in.
            let categories = try category.subCategories.query(on: executor).all().flatMap(to: [CategoryResponseBody].self) { (categories) in
                
                /// Convert the sub-categories to `CategoryResponseBody`s.
                return categories.map({ Future(category: $0, executedWith: executor) }).flatten()
            }
            
            /// Get the sub-categories and translations, convert them to a `CategoryResponseBody`, and assign self.
            return Async.map(to: CategoryResponseBody.self, categories, category.translations(with: executor)) { (subCategories, translations) in
                
                /// Actually create the `CategoryResponseBody` with the data passed in.
                return CategoryResponseBody(
                    id: category.id,
                    name: category.name,
                    subcategories: subCategories,
                    translations: translations.map({ TranslationResponseBody($0, price: nil) })
                )
            }
        })
    }
}
