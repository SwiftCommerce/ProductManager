import Vapor

/// The public `Translation` model representation that
/// is received into, and returned from, a route handler.
struct TranslationContent: Content {
    
    /// The name of the translation
    let name: String
    
    /// The language code for the translation.
    let language: String
    
    /// The descripton of the trsnaltion
    let description: String
    
    /// Creates a `TranslationContent` instance from an object that conforms to `Translation`
    /// and a price (only used if the `translation` parameter type is `ProductTranslation`).
    init<T>(_ translation: T) where T: Translation {
        self.name = translation.name
        self.language = translation.languageCode
        self.description = translation.description
    }
}

extension Translation {
    
    /// Converts a request's body as a `TrnalsationContent` instance to a `Translation` instance
    ///
    /// - Parameters:
    ///   - content: The external content to populate the `Translation` with.
    ///   - parentID: The ID of the model that will own the `Translation` instance.
    init(content: TranslationContent, parent: Int) {
        self.init(name: content.name, description: content.description, languageCode: content.language, parentID: parent)
    }
}
