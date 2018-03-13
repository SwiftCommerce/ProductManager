protocol Translation: Content, MySQLModel, Migration {
    var name: String { get }
    var description: String { get }
    var languageCode: String { get }
    var parentId: Self.ID { get }
}

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
        let price = Price(price: price, activeFrom: nil, activeTo: nil, active: nil, productId: parentId)
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

