final class Attribute: Content, MySQLModel, Migration {
    var id: Int?
    
    let name: String
    var value: String
    let productId: Product.ID
    
    init(name: String, value: String, productId: Product.ID) {
        self.name = name
        self.value = value
        self.productId = productId
    }
}
