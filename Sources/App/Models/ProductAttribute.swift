/// A pivot model for connecting `Attribute` models to a `Product` model.
final class ProductAttribute: MySQLPivot, Migration {
    typealias Left = Product
    typealias Right = Attribute
    
    static var leftIDKey: WritableKeyPath<ProductAttribute, Int> = \.productId
    static var rightIDKey: WritableKeyPath<ProductAttribute, Int> = \.attributeId
    
    var id: Int?
    
    var productId: Int
    var attributeId: Int
    
    /// Create a pivot from a `Product` and `Attribute` model.
    init(product: Product, attribute: Attribute)throws {
        
        // Verfiy the `product` has been save to the database (that it has an ID).
        guard let productId = product.id else {
            fatalError("FIXME: Use a `FluentError`")
        }
        
        // Verify the `attribute` has been saved to the database.
        guard let attributeId = attribute.id else {
            fatalError("FIXME: Use a `FluentError`")
        }
        
        self.productId = productId
        self.attributeId = attributeId
    }
}
