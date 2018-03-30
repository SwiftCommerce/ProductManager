/// A custom, user-defined attribute for a product
final class Attribute: Content, MySQLModel, Migration, Parameter {
    
    /// The database ID of the model.
    var id: Int?
    
    /// The name of the attribute, given by the user.
    let name: String
    
    /// The value of the attribute, given by the user.
    var value: String
    
    /// The ID of the `Product` model that owns the attribute.
    let productID: Product.ID
    
    ///
    init(name: String, value: String, productID: Product.ID) {
        self.name = name
        self.value = value
        self.productID = productID
    }
}

/// Data used to create an `Attribute` for a `Product` model.
struct AttributeContent: Content {
    
    ///
    let name: String
    
    ///
    let value: String
}

extension Product {
    
    /// Creates a query that gets all `Attribute` model connected to the current product.
    ///
    /// - parameter executor: The object that gets a connection to the database
    ///   to run the query.
    /// - returns: A `QueryBuilder` that fetches `Attribute` models connected to the current product.
    func attributes(on executor: DatabaseConnectable)throws -> QueryBuilder<Attribute, Attribute> {
        return try Attribute.query(on: executor).filter(\.productID == self.id)
    }
}

extension QueryBuilder where Model == Attribute, Result == Attribute {
    func detach(_ attribute: Attribute, on executor: DatabaseConnectable)throws -> Future<Void> {
        return try self.filter(\.id == attribute.id).delete()
    }
}
