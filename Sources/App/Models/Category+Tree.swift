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
    /// - Parameter request: The request that will be used to both run the database queries and create new promises.
    /// - Returns: A tree structure of categories, made up of nodes.
    func tree(with request: Request) -> Future<CategoryNode> {
        
        // Wrap the methods implementation in a `.flatMap` clsure, so the method doesn't have to throw.
        return Future.flatMap(on: request, { () -> EventLoopFuture<CategoryNode> in
            
            // Get all of the category's sub-categories.
            let children = try! self.subCategories.query(on: request).all()
            
            return children.flatMap(to: [CategoryNode].self) { (children) in
                
                // Get all the sub-categories' nodes.
                return children.map({ $0.tree(with: request) }).flatten(on: request)
            }.map(to: CategoryNode.self) { (childNodes) in
                
                // Create the top node from the current categories and child nodes.
                return CategoryNode(category: self, children: childNodes)
            }
        })
    }
}
