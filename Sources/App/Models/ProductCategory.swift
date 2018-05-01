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

/// Extend `Siblings` model if the `Base` model's `Database` type conforms to `QuerySupporting` and the `Base` model's `ID` type conforms to `KeyStringDecodable`.
extension Siblings where Base.Database: QuerySupporting, Base.ID: ReflectionDecodable {
    
    /// Delets all pivot rows connecting `Base` model to any `Related` models.
    func deleteConnections(on request: Request) -> Future<Void> {
        
        // Wrap the query in a `flatMap` so the `deleteConnections` method doesn't throw.
        return Future.flatMap(on: request) {
            
            // Run `DELETE` query on all pivot rows that have the `Base` model's ID.
            return try Through.query(on: request).filter(self.basePivotField == self.base.requireID()).delete()
        }
    }
}
