import Foundation

final class Price: Content, MySQLModel, Migration {
    var id: Int?
    
    let price: Float
    let activeFrom: Date
    let activeTo: Date
    var active: Bool
    let translationId: Product.ID
    
    init(price: Float, activeFrom: Date?, activeTo: Date?, active: Bool?, translationId: ProductTranslation.ID) {
        let af = activeFrom ?? Date()
        let at: Date = activeTo ?? Date.distantFuture
        
        self.price = price
        self.activeFrom = af
        self.activeTo = at
        self.active = active ?? (Date() > af && Date() < at)
        self.translationId = translationId
    }
    
    convenience init(from decoder: Decoder)throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            price: container.decode(Float.self, forKey: .price),
            activeFrom: container.decodeIfPresent(Date.self, forKey: .activeFrom),
            activeTo: container.decodeIfPresent(Date.self, forKey: .activeTo),
            active: container.decodeIfPresent(Bool.self, forKey: .active),
            translationId: container.decode(Product.ID.self, forKey: .translationId)
        )
    }
}
