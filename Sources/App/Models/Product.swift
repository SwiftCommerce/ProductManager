final class Product: Content, MySQLModel, Migration {
    var id: Int?
    let sku: String
    
    init(sku: String) { self.sku = sku }
}
