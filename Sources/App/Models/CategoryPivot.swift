import Async

/// A pivot connecting a `Category` model to its sub-categories.
final class CategoryPivot: MySQLPivot, Migration {
    typealias Left = Category
    typealias Right = Category
    
    static var leftIDKey: WritableKeyPath<CategoryPivot, Int> = \.right
    static var rightIDKey: WritableKeyPath<CategoryPivot, Int> = \.left
    static let entity: String = "categoryPivots"
    
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

extension Category {
    
    /// Creates a `CategorPivot` connecting the current category
    /// with another category if it is not already attached.
    ///
    /// - Parameters:
    ///   - category: The category model to attach.
    ///   - executor: The object to create a connection to the database with.
    /// - Returns: A future which succedes with `Void` when the pivot is created.
    /// - Throws: Errors that occur when querying the current pivots or creating the new pivot.
    func attachWithoutDuplication(_ category: Category, on executor: DatabaseConnectable)throws -> Future<Void> {
        
        // Create the pivot that will be save if the category IDs are valid.
        let pivot = try CategoryPivot(self, category)
        
        // Get the number of pivots that the current category is already connected to.
        let leftCount = try CategoryPivot.query(on: executor).filter(\.left == self.id).filter(\.right == category.id).count()
        let rightCount = try CategoryPivot.query(on: executor).filter(\.right == self.id).filter(\.left == category.id).count()
        
        return flatMap(to: Void.self, leftCount, rightCount) { (left, right) in
            guard left < 1 && right < 1 else {
                
                // The current category and the one passed in are already connected.
                // Exit to prevent a recursive or duplicate pivot from being created.
                return executor.eventLoop.newSucceededFuture(result: ())
            }
            
            // Save the pivot to the database.
            return pivot.save(on: executor).transform(to: ())
        }
    }
}
