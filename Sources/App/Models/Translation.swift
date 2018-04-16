import Foundation

// MARK: - Declaration

/// A basic translation representation.
/// This protocol allows us to declare similar types with less code,
/// i.e. a single generic controller instead of two seperate controllers.
///
/// This protocol requires it's implementors to be a class, conform to `Content`, `Model`, `Migration`, and `Parameter`,
/// and that it's `Database` type is `MySQLDatabase`, that `ID` is `String`, and `ResolvedParameter` is `Future<Self>`.
protocol Translation: class, Content, Model, Migration, Parameter where Self.Database == MySQLDatabase, Self.ID == String, Self.ResolvedParameter == Future<Self> {
    
    /// The name of the translation.
    /// This property is used for the model's database ID, instead of an `Int`.
    var name: String? { get set }
    
    /// The description of the translation.
    var description: String { get set }
    
    /// The language code of the translation, i.e. 'en', 'es', etc.
    var languageCode: String { get set }
    
    /// The ID of the parent model for the translation.
    var parentID: Int { get }
}

/// Default implementations of methods and computed properties for the `Translation` protocol.
extension Translation {
    
    /// The default implementation of the `idKey` property required by the `Model` protocol.
    /// The keypath returned defaults to the model's `name` property.
    static var idKey: WritableKeyPath<Self, String?> {
        return \.name
    }
    
    /// Create a `TranslationResponseBody` from the current translation model.
    ///
    /// - Parameter executor: The object used to get models connected to the current translation.
    /// - Returns: A `TranslationResponseBody`, wrapped in a future.
    func response(on request: Request) -> Future<TranslationResponseBody> {
        return Future.map(on: request) { return TranslationResponseBody(self) }
    }
}

// MARK: - Implementations

/// An implementation for the `Translation` protocol that a `Product` model connects to.
final class ProductTranslation: Translation, TranslationRequestInitializable {
    
    static let entity: String = "productTranslations"
    
    /// The name of the translation.
    /// This property is used as the database identifier.
    var name: String?
    
    /// A description of the translation.
    var description: String
    
    /// The code of the language the translation is in.
    var languageCode: String
    
    /// The ID of the `Product` model that owns the translation.
    let parentID: Product.ID
    
    ///
    init(name: String, description: String, languageCode: String, parentID: Product.ID) {
        self.name = name
        self.description = description
        self.languageCode = languageCode
        self.parentID = parentID
    }
    
    /// Creates a `ProductTranslation` from a `TranslationRequestContent`,
    /// saves it to the database, and converts it to a `TranslationResponseBody`.
    ///
    /// - Parameters:
    ///   - content: A `TranslationRequestContent`, created from a request's body.
    ///   - request: The request that the body when fetched from.
    /// - Returns: A `TranslationResponseBody`, wrapped in a future.
    static func create(from content: TranslationRequestContent, with request: Request)throws -> Future<ProductTranslation> {
            
        // Create a new `ProductTranslation`, save it to the database, and convert it to a `TranslationResponseBody`.
        return ProductTranslation(name: content.name, description: content.description, languageCode: content.languageCode, parentID: content.parentID).save(on: request)
    }
}

/// An implementation for the `Translation` protocol that a `Category` model connects to.
final class CategoryTranslation: Translation, TranslationRequestInitializable {
    
    static let entity: String = "categoryTranslations"
    
    /// The name of the translation.
    /// This property is used as the database identifier.
    var name: String?
    
    /// A description of the translation.
    var description: String
    
    /// The code of the language the translation is in.
    var languageCode: String
    
    /// The ID of the `Category` that owns the translation.
    let parentID: Category.ID
    
    ///
    init(name: String, description: String, languageCode: String, parentID: Category.ID) {
        self.name = name
        self.description = description
        self.languageCode = languageCode
        self.parentID = parentID
    }
    
    /// Creates a `CategoryTranslation` from a `TranslationRequestContent`,
    /// saves it to the database, and converts it to a `TranslationResponseBody`.
    ///
    /// - Parameters:
    ///   - content: A `TranslationRequestContent`, created from a request's body.
    ///   - request: The request that the body when fetched from.
    /// - Returns: A `TranslationResponseBody`, wrapped in a future.
    static func create(from content: TranslationRequestContent, with request: Request) -> Future<CategoryTranslation> {
        
        // Create a `CategoryTranslation`, save it to the database, ans convert it to a `TranslationResponseBody`.
        return CategoryTranslation(
            name: content.name,
            description: content.description,
            languageCode: content.languageCode,
            parentID: content.parentID
        ).save(on: request)
    }
}

// MARK: - Public

/// Defines a type as being able to be created from a request body formatted as `TranslationRequestContent`
/// and getting converted to a `TranslationResponseBody`
protocol TranslationRequestInitializable {
    
    ///
    static func create(from content: TranslationRequestContent, with request: Request)throws -> Future<Self>
}

/// A representation of a request body, used to create a translation type.
struct TranslationRequestContent: Content {
    
    ///
    let name: String
    
    ///
    let description: String
    
    ///
    let languageCode: String
    
    ///
    let parentID: Int
}

/// A representation of a translation type that gets returned from a route handler.
struct TranslationResponseBody: Content {
    
    /// The name of the translation
    let name: String?
    
    /// The descripton of the trsnaltion
    let description: String
    
    /// The language code for the translation.
    let languageCode: String
    
    /// Creates a `TranslationResponseBody` from an object that conforms to `Translation`
    /// and a price (only used if the `translation` parameter type is `ProductTranslation`).
    init<Tran>(_ translation: Tran) where Tran: Translation {
        self.name = translation.name
        self.description = translation.description
        self.languageCode = translation.languageCode
    }
}
