import FluentMySQL
import FluentSQL
import Vapor

/// Connects a `Product` model to an `Attribute` model
/// using their IDs.
final class ProductAttribute: MySQLPivot, ProductModel {
    typealias Left = Product
    typealias Right = Attribute
    
    static var leftIDKey: WritableKeyPath<ProductAttribute, Int> = \.productID
    static var rightIDKey: WritableKeyPath<ProductAttribute, Int> = \.attributeID
    static var entity: String = "productAttributes"
    
    var id: Int?
    
    var value: String
    var language: String
    var productID: Product.ID
    var attributeID: Attribute.ID
    
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?
    
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
    
    /// Creates a public representation of the `Attribute` models
    /// connected to a `Product` through `ProductAttribute` pivots.
    ///
    /// - Parameters:
    ///   - request: A request object, which will be used as
    ///     the worker to run the neccesary database queries.
    ///   - pivotQuery: The query to use to get the pivots that
    ///     the `Attribute` models will be fetched with. If `nil`
    ///     is passed in, we default to getting all the pivots.
    ///
    /// - Returns: An array of `AttributeContent`, wrapped in a future.
    func response(on request: Request, pivotQuery: QueryBuilder<ProductAttribute.Database, ProductAttribute>? = nil)throws -> Future<[AttributeContent]> {
        
        // Get all the attributes models connected to the pivots
        // from the pivot query.
        let pivots = try (pivotQuery ?? self.pivots(on: request)).all()
        let attributes = pivots.flatMap(to: [Attribute].self) { pivots in
            let ids = pivots.map({ $0.attributeID })
            return Attribute.query(on: request).filter(\.id ~~ ids).all()
        }
        
        return Async.map(to: [AttributeContent].self, pivots, attributes) { (pivots, attributes) in
            
            // We can gurentee that we will have the same amount of pivots as atrributes.
            // Or organize them so when the sequences are zipped togeather, we will always access
            // the  pivot that is connected to the attributes,
            let ascendingPivots = pivots.sorted { first, second in return first.attributeID < second.attributeID }
            let ascendingAttributes = try attributes.sorted { first, second in return try first.requireID() < second.requireID() }
            
            // Convert each pivot/attribute pair to a `AttributeContent` instance.
            return zip(ascendingPivots, ascendingAttributes).map { (response) in
                return AttributeContent(attribute: response.1, pivot: response.0)
            }
        }
    }
}
