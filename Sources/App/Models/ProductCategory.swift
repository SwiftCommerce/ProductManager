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

extension Product {
    var categories: Siblings<Product, Category, ProductCategory> {
        return self.siblings()
    }
}

extension Category {
    var products: Siblings<Category, Product, ProductCategory> {
        return self.siblings()
    }
}
