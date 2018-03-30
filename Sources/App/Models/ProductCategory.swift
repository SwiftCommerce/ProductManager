// A pivot model for connecting `Category` models to a `Product` model.
final class ProductCategory: MySQLPivot, Migration {
    typealias Left = Product
    typealias Right = Category
    
    static var leftIDKey: WritableKeyPath<ProductCategory, Int> = \.productId
    static var rightIDKey: WritableKeyPath<ProductCategory, Int> = \.categoryId
    
    var productId: Product.ID
    var categoryId: Category.ID
    var id: Int?
    
    /// Create a pivot from a `Product` and `Attribute` model.
    init(product: Product, category: Category)throws {
        
        // Verfiy the `product` has been save to the database (that it has an ID).
        guard let productId = product.id else {
            fatalError("FIXME: Use a `FluentError`")
        }
        
        // Verfiy the `category` has been save to the database.
        guard let categoryId = category.id else {
            fatalError("FIXME: Use a `FluentError`")
        }
        
        self.productId = productId
        self.categoryId = categoryId
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
