// Computed properties for models to access their siblings that are connected with pivots.

// MARK: - Main Model Pivots

extension Product {
    
    /// Gets the categories connected to the current `Product` model.
    var categories: Siblings<Product, Category, ProductCategory> {
        return self.siblings()
    }
}

extension Category {
    
    /// Gets the products connected to the current `Category` model.
    var products: Siblings<Category, Product, ProductCategory> {
        return self.siblings()
    }
}

extension Product {
    
    /// Gets the attributes connected to the current `Product` model.
    var attributes: Siblings<Product, Attribute, ProductAttribute> {
        return self.siblings()
    }
}

extension Category {
    
    /// Gets the categories connected to the current `Category` model.
    var subCategories: Siblings<Category, Category, CategoryPivot> {
        return self.siblings(related: Category.self, through: CategoryPivot.self, CategoryPivot.rightIDKey, CategoryPivot.leftIDKey)
    }
}


// MARK: - Translation Pivots

extension Product: TranslationParent {
    typealias Translation = ProductTranslation
}

extension Category: TranslationParent {
    typealias Translation = CategoryTranslation
}
