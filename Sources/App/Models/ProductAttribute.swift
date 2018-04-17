import FluentMySQL

final class ProductAttribute: MySQLPivot, Migration {
    static var leftIDKey: WritableKeyPath<ProductAttribute, Int> = \.productID
    static var rightIDKey: WritableKeyPath<ProductAttribute, Int> = \.attributeID
    
    typealias Left = Product
    typealias Right = Attribute
    
    var id: Int?
    
    var productID: Product.ID
    var attributeID: Attribute.ID
    
    init(product: Product, attribute: Attribute)throws {
        self.productID = try product.requireID()
        self.attributeID = try attribute.requireID()
    }
}
