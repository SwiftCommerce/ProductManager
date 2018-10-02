// A pivot model for connecting `Category` models to a `Product` model.
final class ProductCategory: MySQLPivot, ProductModel {
    typealias Left = Product
    typealias Right = Category
    
    static var leftIDKey: WritableKeyPath<ProductCategory, Int> = \.productID
    static var rightIDKey: WritableKeyPath<ProductCategory, Int> = \.categoryID
    static let entity: String = "productCategories"
    
    var id: Int?
    var productID: Product.ID
    var categoryID: Category.ID
    
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?
    
    /// Create a pivot from a `Product` and `Attribute` model.
    init(product: Product, category: Category)throws {
        
        // Verfiy the `product` has been save to the database (that it has an ID).
        let productID = try product.requireID()
        
        // Verfiy the `category` has been save to the database.
        let categoryID = try category.requireID()
        
        self.productID = productID
        self.categoryID = categoryID
    }
}
