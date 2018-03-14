// MARK: - Declaration

protocol Translation: Content, MySQLModel, Migration {
    var name: String { get }
    var description: String { get }
    var languageCode: String { get }
    var parentId: Self.ID { get }
}

// MARK: - Implementations

final class ProductTranslation: Translation {
    var id: Int?

    let name: String
    let description: String
    let languageCode: String
    let parentId: Int
    let price: Price
    
    init(name: String, description: String, languageCode: String, parentId: Int, price: Price) {
        self.name = name
        self.description = description
        self.languageCode = languageCode
        self.parentId = parentId
        self.price = price
    }
    
    convenience init(name: String, description: String, languageCode: String, parentId: Int, price: Float) {
        let price = Price(price: price, activeFrom: nil, activeTo: nil, active: nil, translationId: parentId)
        self.init(name: name, description: description, languageCode: languageCode, parentId: parentId, price: price)
    }
}

final class CategoryTranslation: Translation {
    var id: Int?
    
    let name: String
    let description: String
    let languageCode: String
    let parentId: Int
    
    init(name: String, description: String, languageCode: String, parentId: Int) {
        self.name = name
        self.description = description
        self.languageCode = languageCode
        self.parentId = parentId
    }
}

// MARK: - Public

struct TranslationResponseBody: Content {
    let id: Int?
    let name: String
    let description: String
    let languageCode: String
    let parentId: Int
    let price: Price?
    
    init<Tran>(_ translation: Tran) where Tran: Translation {
        self.id = translation.id
        self.name = translation.name
        self.description = translation.description
        self.languageCode = translation.languageCode
        self.parentId = translation.parentId
        
        if let prodTrans = translation as? ProductTranslation {
            self.price = prodTrans.price
        } else { self.price = nil }
    }
}
