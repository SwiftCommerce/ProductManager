/// A pivot connecting a `Category` model to its sub-categories.
final class CategoryPivot: MySQLPivot, Migration {
    typealias Left = Category
    typealias Right = Category
    
    static var leftIDKey: WritableKeyPath<CategoryPivot, Int> = \.right
    static var rightIDKey: WritableKeyPath<CategoryPivot, Int> = \.left
    
    var id: Int?
    
    var right: Int
    var left: Int
    
    /// Create a pivot between two `Category` models.
    init(_ leftCategory: Category, _ rightCategory: Category)throws {
        
        // Verify the left `category` model has been saved to the database (by checking for an ID).
        guard let left = leftCategory.id else {
            fatalError("FIXME: Use a `FluentError`")
        }
        
        // Verify the right `category` model has been saved to the database.
        guard let right = rightCategory.id else {
            fatalError("FIXME: Use a `FluentError`")
        }
        
        self.right = right
        self.left = left
    }
}
