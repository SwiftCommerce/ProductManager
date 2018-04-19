/// Represents a single `Cateogry` model in
/// a tree of related categories.
struct CategoryNode {
    
    /// The current category.
    let category: Category
    
    /// All the categories directly connected to
    /// the main category through `CategoryPivot` models.
    let children: [CategoryNode]
}

extension Category {
    
    /// Gets the category's sub-categories, and their sub-categories, and so on.
    ///
    /// - Parameters:
    ///   - request: The request that will be used to both run the database queries and create new promises.
    ///   - fecthed: This parameter is used internaly for the mthod (because it's recursive).
    /// - Returns: A tree structure of categories, made up of nodes.
    func tree(with request: Request, fetched: [Category.ID] = []) -> Future<CategoryNode> {
        
        // Wrap the methods implementation in a `.flatMap` clsure, so the method doesn't have to throw.
        return Future.flatMap(on: request, { () -> EventLoopFuture<CategoryNode> in
            
            // Get all of the category's sub-categories.
            let children = try self.subCategories.query(on: request).sort(\.sort, .ascending).all()
            
            return children.flatMap(to: [CategoryNode].self) { (children) in
                
                // Get all the sub-categories' nodes.
                return try children.map({ (child: Category)throws -> Future<CategoryNode> in
                    
                    // Verify the the category has not been fetched in the same branch before.
                    // If it has, abort. We found a recursive pivot.
                    let id = try child.requireID()
                    guard !fetched.contains(id) else {
                        throw Abort(.internalServerError, reason: "Found recursive category/category pivot containing category with id '\(id)'")
                    }
                    
                    return child.tree(with: request, fetched: fetched + [id])
                }).flatten(on: request)
            }.map(to: CategoryNode.self) { (childNodes) in
                
                // Create the top node from the current categories and child nodes.
                return CategoryNode(category: self, children: childNodes)
            }
        })
    }
}
