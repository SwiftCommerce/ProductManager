import Foundation

// MARK: - Declaration

protocol Translation: Content, Model, Migration where Self.Database == MySQLDatabase, Self.ID == String {
    var name: String? { get set }
    var description: String { get }
    var languageCode: String { get }
    var parentId: Int { get }
}

extension Translation {
    static var idKey: WritableKeyPath<Self, String?> {
        return \.name
    }
}

extension Future where T: Translation {
    func response() -> Future<TranslationResponseBody> {
        return self.map(to: TranslationResponseBody.self, { TranslationResponseBody($0) })
    }
}

// MARK: - Implementations

final class ProductTranslation: Translation {
    var name: String?
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
    var name: String?
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

struct TranslationRequestContent: Content {
    let name: String
    let description: String
    let languageCode: String
    let price: Float?
    let priceActiveFrom: Date?
    let priceActiveTo: Date?
    let priceActive: Bool?
}

struct TranslationResponseBody: Content {
    let name: String?
    let description: String
    let languageCode: String
    let parentId: Int
    let price: Price?
    
    init<Tran>(_ translation: Tran, price: Price?) where Tran: Translation {
        self.name = translation.name
        self.description = translation.description
        self.languageCode = translation.languageCode
        self.parentId = translation.parentId
        
        if let prodTrans = translation as? ProductTranslation {
            self.price = prodTrans.price
        } else { self.price = nil }
    }
}

