import Vapor

struct AttributeConnection: Content {
    let value: String
    let language: String
    let attributeID: Attribute.ID
}

extension ProductAttribute {
    convenience init(_ data: AttributeConnection, product: Product.ID) {
        self.init(value: data.value, language: data.language, product: product, attribute: data.attributeID)
    }
}
