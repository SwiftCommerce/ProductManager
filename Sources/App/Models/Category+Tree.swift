/// Represents a single `Cateogry` model in
/// a tree of related categories.
struct CategoryNode {
    
    /// The current category.
    let category: Category
    
    /// All the categories directly connected to
    /// the main category through `CategoryPivot` models.
    let children: [CategoryNode]
}
