import Vapor

struct ProductContent: Content {
    let sku: String
    let name: String
    let description: String?
    let status: ProductStatus?
    let prices: [PriceContent]?
}

extension Product {
    convenience init(content: ProductContent) {
        self.init(
            sku: content.sku,
            name: content.name,
            description: content.description,
            status: content.status ?? .draft
        )
    }
}
