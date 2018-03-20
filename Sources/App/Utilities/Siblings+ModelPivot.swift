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

// MARK: - Translation Pivots

extension Product: TranslationParent {
    
    /// Gets the translations connected to the current `Product` model.
    var translations: Siblings<Product, ProductTranslation, ProductTranslationPivot> {
        return siblings()
    }
}

extension Category: TranslationParent {
    
    /// Gets the translations connected to the current `Category` model.
    var translations: Siblings<Category, CategoryTranslation, CategoryTranslationPivot> {
        return siblings()
    }
}

extension ProductTranslation {
    
    /// Gets the products connected to the current `ProductTranslation` model.
    var products: Siblings<ProductTranslation, Product, ProductTranslationPivot> {
        return siblings()
    }
}

extension CategoryTranslation {
    
    /// Gets the categories connected to the current `CategoryTranslation` model.
    var categories: Siblings<CategoryTranslation, Category, CategoryTranslationPivot> {
        return siblings()
    }
}
