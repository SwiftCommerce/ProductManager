import Fluent
import Vapor

typealias ProductTranslationController = TranslationController<Product, ProductTranslation>
typealias CategoryTranslationController = TranslationController<Category, CategoryTranslation>

final class TranslationController<Parent, Translation>: RouteCollection where
    Parent: TranslationParent & Parameter, Translation == Parent.Translation, Parent.ResolvedParameter == Future<Parent>
{
    let root: String?
    
    init(root: String? = nil) {
        self.root = root
    }
    
    func boot(router: Router) throws {
        let translations: Router
        if let root = self.root {
            translations = router.grouped(root, Parent.parameter, "translations")
        } else {
            translations = router.grouped(Parent.parameter, "translations")
        }
        
        translations.post(TranslationContent.self, use: create)
        translations.get(use: index)
        translations.get(Translation.parameter, use: get)
        translations.patch(TranslationUpdateContent.self, at: Translation.parameter, use: update)
        translations.delete(Translation.parameter, use: delete)
    }
    
    func create(_ request: Request, content: TranslationContent)throws -> Future<TranslationContent> {
        let parent = try request.parameters.id(for: Parent.self)
        return Translation(content: content, parent: parent).create(on: request).response(on: request)
    }
    
    func index(_ request: Request)throws -> Future<[TranslationContent]> {
        let parent = try request.parameters.id(for: Parent.self)
        return Translation.query(on: request).filter(\.parentID == parent).all().flatMap { translations in
            return translations.map { $0.response(on: request) }.flatten(on: request)
        }
    }
    
    func get(_ request: Request)throws -> Future<TranslationContent> {
        let parent = try request.parameters.id(for: Parent.self)
        let id = try request.parameters.id(for: Translation.self)
        let translation = Translation.query(on: request).filter(\.parentID == parent).filter(\.id == id).first()
        
        return translation.unwrap(or: Abort(.notFound)).response(on: request)
    }
    
    func update(_ request: Request, content: TranslationUpdateContent)throws -> Future<TranslationContent> {
        let parent = try request.parameters.id(for: Parent.self)
        let id = try request.parameters.id(for: Translation.self)
        let translation = Translation.query(on: request).filter(\.parentID == parent).filter(\.id == id).first()
        
        return translation.unwrap(or: Abort(.notFound)).map(content.update).save(on: request).response(on: request)
    }
    
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        let parent = try request.parameters.id(for: Parent.self)
        let id = try request.parameters.id(for: Translation.self)
        
        return Translation.query(on: request).filter(\.parentID == parent).filter(\.id == id).delete().transform(to: .noContent)
    }
}
