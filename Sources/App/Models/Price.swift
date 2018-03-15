import Foundation

final class Price: Content, MySQLModel, Migration {
    var id: Int?
    
    let price: Float
    let activeFrom: Date
    let activeTo: Date
    var active: Bool
    let translationName: ProductTranslation.ID
    
    init(price: Float, activeFrom: Date?, activeTo: Date?, active: Bool?, translationName: ProductTranslation.ID) {
        let af = activeFrom ?? Date()
        let at: Date = activeTo ?? Date.distantFuture
        
        self.price = price
        self.activeFrom = af
        self.activeTo = at
        self.active = active ?? (Date() > af && Date() < at)
        self.translationName = translationName
    }
    
    convenience init(from decoder: Decoder)throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            price: container.decode(Float.self, forKey: .price),
            activeFrom: container.decodeIfPresent(Date.self, forKey: .activeFrom),
            activeTo: container.decodeIfPresent(Date.self, forKey: .activeTo),
            active: container.decodeIfPresent(Bool.self, forKey: .active),
            translationName: container.decode(ProductTranslation.ID.self, forKey: .translationName)
        )
        
        self.id = try container.decodeIfPresent(Int.self, forKey: .id)
    }
}
