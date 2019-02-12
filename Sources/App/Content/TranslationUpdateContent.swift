import Vapor

struct TranslationUpdateContent: Content {
    let language: String?
    let description: String?
    
    func update<T>(translation: T) -> T where T: Translation {
        translation.languageCode = self.language ?? translation.languageCode
        translation.description = self.description ?? translation.description
        
        return translation
    }
}
