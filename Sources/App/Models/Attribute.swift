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
