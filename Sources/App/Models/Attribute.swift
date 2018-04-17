/// A custom, user-defined attribute for a product
final class Attribute: Content, MySQLModel, Migration, Parameter {
    
    /// The database ID of the model.
    var id: Int?
    
    /// The name of the attribute, given by the user.
    let name: String
    
    /// The value of the attribute, given by the user.
    var type: String
    
    ///
    init(name: String, type: String) {
        self.name = name
        self.type = type
    }
}

/// Data used to create an `Attribute` for a `Product` model.
struct AttributeContent: Content {
    let id: Attribute.ID?
    let name: String
    let type: String
    let value: String
    let language: String
}
