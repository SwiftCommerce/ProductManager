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


extension Product: TranslationParent {
    var translations: Siblings<Product, ProductTranslation, ProductTranslationPivot> {
        return siblings()
    }
}

extension Category: TranslationParent {
    var translations: Siblings<Category, CategoryTranslation, CategoryTranslationPivot> {
        return siblings()
    }
}

extension ProductTranslation {
    var prodcuts: Siblings<ProductTranslation, Product, ProductTranslationPivot> {
        return siblings()
    }
}

extension CategoryTranslation {
    var categories: Siblings<CategoryTranslation, Category, CategoryTranslationPivot> {
        return siblings()
    }
}
