import FluentMySQL

typealias ProductTranslationPivot = ModelTranslation<Product, ProductTranslation>
typealias CategoryTranslationPivot = ModelTranslation<Category, CategoryTranslation>

protocol TranslationParent: MySQLModel {
    associatedtype TranslationType: Translation
    
    var translations: Siblings<Self, TranslationType, ModelTranslation<Self, TranslationType>> { get }
}

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
