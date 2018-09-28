import FluentMySQL
import Vapor

/// The basic structure of a model in this service.
protocol ProductModel: Content, MySQLModel, Migration, Parameter {
    
    /// The date/time that the model was
    /// saved to the database.
    var createdAt: Date? { get set }
    
    /// The date/time that the model was
    /// last updated in that database at.
    var updatedAt: Date? { get set }
    
    /// The date/time that a delete
    /// operation was run on the model.
    ///
    /// By default, a model with this
    /// value set will not be returned
    /// from a query.
    var deletedAt: Date? { get set }
}

extension ProductModel {
    
    static var createdAtKey: WritableKeyPath<Self, Date?> {
        return \.createdAt
    }
    
    static var updatedAtKey: WritableKeyPath<Self, Date?> {
        return \.updatedAt
    }
    
    static var deletedAtKey: WritableKeyPath<Self, Date?> {
        return \.deletedAt
    }
}
