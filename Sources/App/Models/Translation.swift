import Foundation

// MARK: - Declaration

/// A basic translation representation.
/// This protocol allows us to declare similar types with less code,
/// i.e. a single generic controller instead of two seperate controllers.
///
/// This protocol requires it's implementors to be a class, conform to `Content`, `Model`, `Migration`, and `Parameter`,
/// and that it's `Database` type is `MySQLDatabase`, that `ID` is `String`, and `ResolvedParameter` is `Future<Self>`.
protocol Translation: class, Content, MySQLModel, Migration, Parameter
    where Self.ResolvedParameter == Future<Self>
{
    
    /// The name of the translation.
    var name: String { get }
    
    /// The description of the translation.
    var description: String { get set }
    
    /// The language code of the translation, i.e. 'en', 'es', etc.
    var languageCode: String { get set }
    
    /// The ID of the parent model for the translation.
    var parentID: Int { get }
    
    /// Creates a new instance of `Self`.
    init(name: String, description: String, languageCode: String, parentID: Int)
}

/// Default implementations of methods and computed properties for the `Translation` protocol.
extension Translation {
    
    /// Create a `TranslationResponseBody` from the current translation model.
    ///
    /// - Parameter executor: The object used to get models connected to the current translation.
    /// - Returns: A `TranslationResponseBody`, wrapped in a future.
    func response(on request: Request) -> Future<TranslationContent> {
        return Future.map(on: request) { return TranslationContent(self) }
    }
    
    /// Generates the database table for the model
    ///
    /// We use a custom implementation so we can have a uniques `name` property.
    public static func prepare(on connection: Database.Connection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.unique(on: \.name)
        }
    }
}

// MARK: - Implementations

/// An implementation for the `Translation` protocol that a `Product` model connects to.
final class ProductTranslation: Translation {
    
    static let entity: String = "productTranslations"
    
    /// The unique ID for the model.
    var id: Int?
    
    /// The name of the translation.
    let name: String
    
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
}

/// An implementation for the `Translation` protocol that a `Category` model connects to.
final class CategoryTranslation: Translation {
    
    static let entity: String = "categoryTranslations"
    
    /// The unique ID for the model.
    var id: Int?
    
    /// The name of the translation.
    /// This property is used as the database identifier.
    let name: String
    
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
}
