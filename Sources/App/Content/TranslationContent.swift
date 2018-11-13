import Vapor

struct TranslationContent: Content {
    let name: String
    let language: String
    let description: String
}

extension Translation {
    init(content: TranslationContent, parent: Int) {
        self.init(name: content.name, description: content.description, languageCode: content.language, parentID: parent)
    }
}
