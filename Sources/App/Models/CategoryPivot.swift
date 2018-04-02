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
        let left = try leftCategory.requireID()
        
        // Verify the right `category` model has been saved to the database.
        let right = try rightCategory.requireID()
        
        // Verfiy we aren't trying to create a pivot
        // with the same model on the both sides if the pivot.
        guard left != right else {
            throw FluentError(
                identifier: "identicalCategoryIDs",
                reason: "Can't create a `CategoryPivot` instance with with the same model for both the left and right categories.",
                source: .capture()
            )
        }
        
        self.right = right
        self.left = left
    }
}
