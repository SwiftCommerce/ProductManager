import FluentMySQL
import FluentSQL
import Vapor

final class ProductAttribute: MySQLPivot, Migration {
    static var leftIDKey: WritableKeyPath<ProductAttribute, Int> = \.productID
    static var rightIDKey: WritableKeyPath<ProductAttribute, Int> = \.attributeID
    
    typealias Left = Product
    typealias Right = Attribute
    
    var id: Int?
    
    var value: String
    var language: String
    var productID: Product.ID
    var attributeID: Attribute.ID
    
    init(value: String, language: String, product: Product, attribute: Attribute)throws {
        self.productID = try product.requireID()
        self.attributeID = try attribute.requireID()
        self.value = value
        self.language = language
    }
}

extension Product {
    var attributes: Siblings<Product, Attribute, ProductAttribute> {
        return self.siblings()
    }
}


extension Siblings where Base == Product, Related == Attribute, Through == ProductAttribute {
    func response(on request: Request, pivotQuery: QueryBuilder<ProductAttribute, ProductAttribute>? = nil)throws -> Future<[AttributeContent]> {
        let pivots = try (pivotQuery ?? self.pivots(on: request)).all()
        let attributes = pivots.flatMap(to: [Attribute].self) { pivots in
            let ids = pivots.map({ $0.attributeID })
            return try Attribute.query(on: request).filter(\.id ~~ ids).all()
        }
        
        return Async.map(to: [AttributeContent].self, pivots, attributes) { (pivots, attributes) in
            let ascendingPivots = pivots.sorted { first, second in return first.attributeID < second.attributeID }
            let ascendingAttributes = try attributes.sorted { first, second in return try first.requireID() < second.requireID() }
            return zip(ascendingPivots, ascendingAttributes).map { (response) in
                return AttributeContent(attribute: response.1, pivot: response.0)
            }
        }
    }
}
