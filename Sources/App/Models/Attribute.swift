/// A custom, user-defined attribute for a product
final class Attribute: Content, MySQLModel, Migration, Parameter {
    
    /// The database ID of the model.
    var id: Int?
    
    /// The name of the attribute, given by the user.
    let name: String
    
    /// The value of the attribute, given by the user.
    var value: String
    
    ///
    init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}
