import FluentMySQL

/// Connects a `Product` model to a `Price` model using their IDs.
final class ProductPrice: MySQLPivot {
    typealias Left = Product
    typealias Right = Price
    
    static var leftIDKey: WritableKeyPath<ProductPrice, Int> = \.productID
    static var rightIDKey: WritableKeyPath<ProductPrice, Int> = \.priceID
    static let entity: String = "productPrice"
    
    var id: Int?
    
    var productID: Product.ID
    var priceID: Price.ID
    
    init(product: Product, price: Price)throws {
        self.productID = try product.requireID()
        self.priceID = try price.requireID()
    }
}
