import FluentMySQL
import Vapor

/// The basic structure of a model in this service.
protocol ProductModel: Content, MySQLModel, Migration, Parameter, Timestampable, SoftDeletable {
    
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
    
    /// The date at which this model was created.
    /// nil if the model has not been created yet.
    static var createdAtKey: CreatedAtKey {
        return \.createdAt
    }
    
    /// The date at which this model was last updated.
    /// nil if the model has not been created yet.
    static var updatedAtKey: UpdatedAtKey {
        return \.updatedAt
    }
    
    /// The date at which this model was deleted.
    /// nil if the model has not been deleted yet.
    /// If this property is true, the model will not
    /// be included in any query results unless
    /// `.withSoftDeleted()` is used.
    static var deletedAtKey: DeletedAtKey {
        return \.deletedAt
    }
}
