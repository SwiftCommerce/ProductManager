import Vapor

struct ProductUpdateBody: Content {
    struct AttributeUpdate: Content {
        let attach: [Attribute.ID]?
        let detach: [Attribute.ID]?
    }
    struct TranslationUpdate: Content {
        let attach: [ProductTranslation.ID]?
        let detach: [ProductTranslation.ID]?
    }
    
    let attributes: AttributeUpdate?
    let translations: TranslationUpdate?
    let categories: CategoryUpdateBody?
}

final class ProductController: RouteCollection {
    func boot(router: Router) throws {
        let products = router.grouped("products")
        
        products.post(use: create)
        
        products.get(use: index)
        products.get(Product.parameter, use: show)
        
        products.patch(ProductUpdateBody.self, at: Product.parameter, use: update)
        
        products.delete(Product.parameter, use: delete)
    }
    
    func create(_ request: Request)throws -> Future<ProductResponseBody> {
        let sku = request.content.get(String.self, at: "sku")
        return sku.map(to: Product.self, { (sku) in return Product(sku: sku) }).save(on: request).response(with: request)
    }
    
    func index(_ request: Request)throws -> Future<[ProductResponseBody]> {
        return Product.query(on: request).all().flatMap(to: [ProductResponseBody].self, { (products) in
            return products.map({ (product) in
                return Future<ProductResponseBody>.init(product: product, executedWith: request)
            }).flatten()
        })
    }
    
    func show(_ request: Request)throws -> Future<ProductResponseBody> {
        return try request.parameter(Product.self).response(with: request)
    }
    
    func update(_ request: Request, _ body: ProductUpdateBody)throws -> Future<ProductResponseBody> {
        let product = try request.parameter(Product.self)
        
        let detachAttributes = Attribute.query(on: request).filter(\.name, in: body.attributes?.detach)
        let attachAttributes = Attribute.query(on: request).filter(\.name, in: body.attributes?.attach)
        
        let detachTranslations = ProductTranslation.query(on: request).filter(\.name, in: body.translations?.detach)
        let attachTranslations = ProductTranslation.query(on: request).filter(\.name, in: body.translations?.attach)
        
        let detachCategories = Category.query(on: request).filter(\.id, in: body.categories?.detach)
        let attachCategories = Category.query(on: request).filter(\.id, in: body.categories?.attach)
        
        let attributes = Async.flatMap(to: Void.self, product, detachAttributes, attachAttributes) { (product, detach, attach) in
            let detached = detach.map({ product.attributes.detach($0, on: request) }).flatten()
            let attached = try attach.map({ try ProductAttribute(product: product, attribute: $0).save(on: request) }).flatten().transform(to: ())
            return [detached, attached].flatten()
        }
        
        let translations = Async.flatMap(to: Void.self, product, detachTranslations, attachTranslations) { (product, detach, attach) in
            let detached = detach.map({ product.translations.detach($0, on: request) }).flatten()
            let attached = try attach.map({ try ProductTranslationPivot(parent: product, translation: $0).save(on: request) }).flatten().transform(to: ())
            return [detached, attached].flatten()
        }
        
        let categories = Async.flatMap(to: Void.self, product, detachCategories, attachCategories) { (product, detach, attach) in
            let detached = detach.map({ product.categories.detach($0, on: request) }).flatten()
            let attached = try attach.map({ try ProductCategory(product: product, category: $0).save(on: request) }).flatten().transform(to: ())
            return [detached, attached].flatten()
        }
        
        return Async.flatMap(to: ProductResponseBody.self, attributes, translations, categories, { _, _, _ in
            return product.response(with: request)
        })
    }
    
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        return try request.parameter(Product.self).delete(on: request).transform(to: .noContent)
    }
}
