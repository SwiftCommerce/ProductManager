final class ProductAttribute: MySQLPivot, Migration {
    typealias Left = Product
    typealias Right = Attribute
    
    static var leftIDKey: WritableKeyPath<ProductAttribute, Int> = \.productId
    static var rightIDKey: WritableKeyPath<ProductAttribute, Int> = \.attributeId
    
    var id: Int?
    
    var productId: Int
    var attributeId: Int
    
    init(product: Product, attribute: Attribute)throws {
        guard let productId = product.id else {
            fatalError("FIXME: Use a `FluentError`")
        }
        guard let attributeId = attribute.id else {
            fatalError("FIXME: Use a `FluentError`")
        }
        
        self.productId = productId
        self.attributeId = attributeId
    }
}

extension Product {
    var attributes: Siblings<Product, Attribute, ProductAttribute> {
        return self.siblings()
    }
}

extension Attribute {
    var products: Siblings<Attribute, Product, ProductAttribute> {
        return self.siblings()
    }
}
