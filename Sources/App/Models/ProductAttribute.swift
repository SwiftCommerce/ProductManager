import FluentMySQL

final class ProductAttribute: MySQLPivot, Migration {
    static var leftIDKey: WritableKeyPath<ProductAttribute, Int> = \.productID
    static var rightIDKey: WritableKeyPath<ProductAttribute, Int> = \.attributeID
    
    typealias Left = Product
    typealias Right = Attribute
    
    var id: Int?
    
    var value: String
    var productID: Product.ID
    var attributeID: Attribute.ID
    
    init(value: String, product: Product, attribute: Attribute)throws {
        self.productID = try product.requireID()
        self.attributeID = try attribute.requireID()
        self.value = value
    }
}
