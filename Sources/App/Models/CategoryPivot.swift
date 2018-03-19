final class CategoryPivot: MySQLPivot {
    typealias Left = Category
    typealias Right = Category
    
    static var leftIDKey: WritableKeyPath<CategoryPivot, Int> = \.right
    static var rightIDKey: WritableKeyPath<CategoryPivot, Int> = \.left
    
    var id: Int?
    
    var right: Int
    var left: Int
    
    init(_ leftCategory: Category, _ rightCategory: Category)throws {
        guard let left = leftCategory.id else {
            fatalError("FIXME: Use a `FluentError`")
        }
        guard let right = rightCategory.id else {
            fatalError("FIXME: Use a `FluentError`")
        }
        
        self.right = right
        self.left = left
    }
}

extension Category {
    var subCategories: Siblings<Category, Category, CategoryPivot> {
        return self.siblings(related: Category.self, through: CategoryPivot.self, CategoryPivot.leftIDKey, CategoryPivot.rightIDKey)
    }
}
