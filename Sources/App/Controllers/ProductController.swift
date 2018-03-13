final class ProductController: RouteCollection {
    func boot(router: Router) throws {
        let products = router.grouped("products")
        
        products.get(use: index)
    }
    
    func index(_ request: Request)throws -> Future<[ProductResponseBody]> {
        return Product.query(on: request).all().flatMap(to: [ProductResponseBody].self, { (products) in
            return products.map({ (product) in
                return Future<ProductResponseBody>.init(product: product, executedWith: request)
            }).flatten()
        })
    }
}
