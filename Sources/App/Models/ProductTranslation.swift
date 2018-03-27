///// A static type declaration of `ModelTranslation` with `Parent` and `ParentTransltion` models.
//typealias ProductTranslationPivot = ModelTranslation<Product, ProductTranslation>
//
///// A static type declaration of `ModelTranslation` with `Category` and `CategoryTransltion` models.
//typealias CategoryTranslationPivot = ModelTranslation<Category, CategoryTranslation>

/// Defines a model as being connected to `Translation` models through a `ModelTranslation` pivot.
protocol TranslationParent: MySQLModel {
    
    /// The translation model type that the parent model connects to.
    associatedtype Translation: App.Translation
    
    /// Creates a query to access connected translations by their `parentID` property.
    ///
    /// - parameter executor: The object that gets the connetion to the database,
    ///   which is used to run the query.
    func translations(on executor: DatabaseConnectable) -> QueryBuilder<Translation, Translation>
}

extension TranslationParent {
    
    /// Creates a query to access connected translations by their `parentID` property.
    ///
    /// - parameter executor: The object that gets the connetion to the database,
    ///   which is used to run the query.
    func translations(on executor: DatabaseConnectable)throws -> QueryBuilder<Translation, Translation> {
        
        // The parent model has to be saved to the daatbase to be connected to any translations,
        // so make sure it exists in the DB.
        let id = try self.requireID()
        
        // Get all the translation models twho's `parentID` is the ID of the current model.
        return try Translation.query(on: executor).filter(\.parentID == id)
    }
}

///// A generic pivot type for connecting a model to a `Translation` model.
//final class ModelTranslation<Parent: MySQLModel, Translation: App.Translation>: MySQLPivot, Migration {
//    typealias Left = Parent
//    typealias Right = Translation
//
//    static var leftIDKey: WritableKeyPath<ModelTranslation, Int> {
//        return \.parentId
//    }
//
//    static var rightIDKey: WritableKeyPath<ModelTranslation, String> {
//        return \.translationName
//    }
//
//    var parentId: Parent.ID
//    var translationName: Translation.ID
//    var id: Int?
//
//    /// Create a pivot from the defined `Parent` and `Trans` types.
//    init(parent: Parent, translation: Translation)throws {
//
//        // Verify the `parent` model has been saved to the database (by checking for the ID).
//        guard let parentId = parent.id else {
//            fatalError("FIXME: Use a `FluentError`")
//        }
//
//        // Verify the `translation` model has been saved to the database.
//        guard let translationName = translation.name else {
//            fatalError("FIXME: Use a `FluentError`")
//        }
//
//        self.parentId = parentId
//        self.translationName = translationName
//    }
//}
