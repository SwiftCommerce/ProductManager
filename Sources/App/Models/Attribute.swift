/// A custom, user-defined attribute for a product
final class Attribute: ProductModel {
    static let entity: String = "attributes"
    
    /// The database ID of the model.
    var id: Int?
    
    /// The name of the attribute, given by the user.
    var name: String
    
    /// The value of the attribute, given by the user.
    var type: String
    
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?
    
    init(name: String, type: String) {
        self.name = name
        self.type = type
    }
}

/// Data used to create an `Attribute` for a `Product` model.
struct AttributeContent: Content {
    let id: Attribute.ID?
    let name, type, value, language: String
    let createdAt, updatedAt, deletedAt: Date?
    
    init(attribute: Attribute, pivot: ProductAttribute) {
        self.id = attribute.id
        self.name = attribute.name
        self.type = attribute.type
        self.value = pivot.value
        self.language = pivot.language
        self.createdAt = attribute.createdAt
        self.updatedAt = attribute.updatedAt
        self.deletedAt = attribute.deletedAt
    }
}
