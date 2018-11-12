import Vapor

struct ProductUpdateContent: Content {
    let name: String
    let description: String?
    let status: ProductStatus?
    
    @discardableResult
    func update(product: Product) -> Product {
        product.name = self.name
        product.status = self.status ?? product.status
        product.description = self.description
        
        return product
    }
}
