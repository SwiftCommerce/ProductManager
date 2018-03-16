import FluentMySQL

final class ProductCategory: MySQLPivot, Migration {
    typealias Left = Product
    typealias Right = Category
    
    static var leftIDKey: WritableKeyPath<ProductCategory, Int> = \.productId
    static var rightIDKey: WritableKeyPath<ProductCategory, Int> = \.categoryId
    
    var productId: Product.ID
    var categoryId: Category.ID
    var id: Int?
    
    init(product: Product, category: Category)throws {
        guard let productId = product.id else {
            fatalError("FIXME: Use a `FluentError`")
        }
        guard let categoryId = category.id else {
            fatalError("FIXME: Use a `FluentError`")
        }
        
        self.productId = productId
        self.categoryId = categoryId
    }
}

extension Siblings where Base.Database: QuerySupporting, Base.ID: KeyStringDecodable {
    func deleteConnections(on executor: DatabaseConnectable) -> Future<Void> {
        return Future.flatMap {
            return try Through.query(on: executor).filter(self.basePivotField == self.base.requireID()).delete()
        }
    }
}
