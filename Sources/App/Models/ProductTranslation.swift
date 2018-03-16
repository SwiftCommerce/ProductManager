typealias ProductTranslationPivot = ModelTranslation<Product, ProductTranslation>
typealias CategoryTranslationPivot = ModelTranslation<Category, CategoryTranslation>

final class ModelTranslation<Parent: MySQLModel, Trans: Translation>: MySQLPivot, Migration {
    typealias Left = Parent
    typealias Right = Trans
    
    static var leftIDKey: WritableKeyPath<ModelTranslation, Int> {
        return \.parentId
    }
    
    static var rightIDKey: WritableKeyPath<ModelTranslation, String> {
        return \.translationName
    }
    
    var parentId: Parent.ID
    var translationName: Trans.ID
    var id: Int?
    
    init(parent: Parent, translation: Trans)throws {
        guard let parentId = parent.id else {
            fatalError("FIXME: Use a `FluentError`")
        }
        guard let translationName = translation.name else {
            fatalError("FIXME: Use a `FluentError`")
        }
        
        self.parentId = parentId
        self.translationName = translationName
    }
}

extension Product {
    var translations: Siblings<Product, ProductTranslation, ProductTranslationPivot> {
        return siblings()
    }
}

extension Category {
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
