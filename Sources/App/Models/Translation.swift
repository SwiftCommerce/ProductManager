typealias ProductTranslation = Translation<Product>
typealias CategoryTranslation = Translation<Category>

final class Translation<Parent: Content & MySQLModel & Migration>: Content, MySQLModel, Migration {
    var id: Int?
    
    let name: String
    let description: String
    let languageCode: String
    let parentId: Parent.ID
    
    init(name: String, description: String, languageCode: String, parentId: Parent.ID) {
        self.name = name
        self.description = description
        self.languageCode = languageCode
        self.parentId = parentId
    }
}
