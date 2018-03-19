import Foundation

// MARK: - Declaration

protocol Translation: Content, Model, Migration, Parameter where Self.Database == MySQLDatabase, Self.ID == String, Self.ResolvedParameter == Future<Self> {    
    var name: String? { get set }
    var description: String { get set }
    var languageCode: String { get set }
}

extension Translation {
    static var idKey: WritableKeyPath<Self, String?> {
        return \.name
    }
    
    func response(on executor: DatabaseConnectable) -> Future<TranslationResponseBody> {
        let price: Future<Price?>
        if let productTranslation = self as? ProductTranslation, let id = productTranslation.priceId {
            price = Price.find(id, on: executor)
        } else {
            price = Future(nil)
        }
        
        return price.map(to: TranslationResponseBody.self, { (price) in
            return TranslationResponseBody(self, price: price)
        })
    }
}

// MARK: - Implementations

final class ProductTranslation: Translation, TranslationRequestInitializable {
    var name: String?
    var description: String
    var languageCode: String
    var priceId: Price.ID?
    
    init(name: String, description: String, languageCode: String, priceId: Price.ID?) {
        self.name = name
        self.description = description
        self.languageCode = languageCode
        self.priceId = priceId
    }
    
    static func create(from content: TranslationRequestContent, with request: Request) -> Future<TranslationResponseBody> {
        guard let amount = content.price else {
            return Future(error: Abort(.badRequest, reason: "Request body must contain 'price' key"))
        }
        let price = Price(price: amount, activeFrom: content.priceActiveFrom, activeTo: content.priceActiveTo, active: content.priceActive, translationName: content.name)
        return price.save(on: request).flatMap(to: TranslationResponseBody.self) { (price) in
            return try ProductTranslation(name: content.name, description: content.description, languageCode: content.languageCode, priceId: price.requireID())
                .save(on: request).response(on: request)
        }
    }
}

final class CategoryTranslation: Translation, TranslationRequestInitializable {
    var name: String?
    var description: String
    var languageCode: String
    
    init(name: String, description: String, languageCode: String) {
        self.name = name
        self.description = description
        self.languageCode = languageCode
    }
    
    static func create(from content: TranslationRequestContent, with request: Request) -> Future<TranslationResponseBody> {
        return CategoryTranslation(name: content.name, description: content.description, languageCode: content.languageCode).save(on: request).response(on: request)
    }
}

// MARK: - Public

protocol TranslationRequestInitializable {
    static func create(from content: TranslationRequestContent, with request: Request) -> Future<TranslationResponseBody>
}

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
    let price: Price?
    
    init<Tran>(_ translation: Tran, price: Price?) where Tran: Translation {
        self.name = translation.name
        self.description = translation.description
        self.languageCode = translation.languageCode
        
        if translation as? ProductTranslation != nil {
            self.price = price
        } else { self.price = nil }
    }
}
