import Fluent
import CodableKit

extension QueryBuilder {
    
    /// Gets all models from a table that have any one of a list of values in a specefied column.
    ///
    /// - Parameters:
    ///   - field: The column to check for a given value in.
    ///   - values: The values to check for in the columns.
    /// - Returns: All the models that match the given query, wrapped in a future.
    @discardableResult
    public func all<T>(where field: KeyPath<Model, T>, in values: [Model.Database.QueryDataConvertible]?) -> Future<[Result]> where T: KeyStringDecodable {
        
        // This method is different because we allow `nil` to be passed in instead of an array.
        // If we get `nil` instead of an array, return an empty array immediately, it saves time.
        guard let values = values else {
            let emptyResult = self.connection.eventLoop.newPromise([Result].self)
            emptyResult.succeed(result: [])
            return emptyResult.futureResult
        }
        
        // Wrap filter in `flatMap` so the method doesn't have to throw.
        return Future.flatMap(on: self.connection.eventLoop) { () -> EventLoopFuture<[Result]> in
            
            // Since `value` is not `nil`, run the filter and get all the resulting models.
            return try self.filter(field, in: values).all()
        }
    }
}

// TODO: - This extension is here until it is added to `FluentMySQL`.
extension Bool: MySQLColumnDefinitionStaticRepresentable {
    public static var mySQLColumnDefinition: MySQLColumnDefinition {
        return .tinyInt()
    }
}
