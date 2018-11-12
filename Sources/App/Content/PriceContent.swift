import Vapor

struct PriceContent: Content {
    let cents: Int
    let currency: String
    let activeFrom: Date?
    let activeTo: Date?
    let active: Bool?
    let productID: Product.ID?
}

extension Price {
    convenience init(content: PriceContent, product: Product.ID)throws {
        try self.init(
            productID: product,
            cents: content.cents,
            activeFrom: content.activeFrom,
            activeTo: content.activeTo,
            active: content.active,
            currency: content.currency
        )
    }
}
