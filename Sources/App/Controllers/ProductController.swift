import Vapor

final class ProductController: RouteCollection {
    func boot(router: Router) throws {
        let products = router.grouped("products")
        
        products.get(use: index)
        products.get(Product.parameter, use: show)
        
        products.post(use: create)
        
        products.delete(Product.parameter, use: delete)
    }
    
    func index(_ request: Request)throws -> Future<[ProductResponseBody]> {
        return Product.query(on: request).all().flatMap(to: [ProductResponseBody].self, { (products) in
            return products.map({ (product) in
                return Future<ProductResponseBody>.init(product: product, executedWith: request)
            }).flatten()
        })
    }
    
    func show(_ request: Request)throws -> Future<ProductResponseBody> {
        return try request.parameter(Product.self).flatMap(to: ProductResponseBody.self, { (product) in
            return Future<ProductResponseBody>.init(product: product, executedWith: request)
        })
    }
    
    func create(_ request: Request)throws -> Future<ProductResponseBody> {
        let sku = request.content.get(String.self, at: "sku")
        let product = sku.map(to: Product.self, { (sku) in return Product(sku: sku) })
        return product.flatMap(to: ProductResponseBody.self, { (product) in Future(product: product, executedWith: request) })
    }
    
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        return try request.parameter(Product.self).delete(on: request).transform(to: .noContent)
    }
}
