import FluentSQL

extension QueryBuilder {
    
    /// Gets all models from a table that have any one of a list of values in a specefied column.
    ///
    /// - Parameters:
    ///   - field: The column to check for a given value in.
    ///   - values: The values to check for in the columns.
    /// - Returns: All the models that match the given query, wrapped in a future.
    @discardableResult
    public func models<Model, Value>(where field: KeyPath<Model, Value>, in values: [Value]?) -> Future<[Result]> where Value: Encodable {
        
        // This method is different because we allow `nil` to be passed in instead of an array.
        // If we get `nil` instead of an array, return an empty array immediately, it saves time.
        guard let values = values else {
            return self.connection.eventLoop.newSucceededFuture(result: [])
        }
        
        // Wrap filter in `flatMap` so the method doesn't have to throw.
        // Since `value` is not `nil`, run the filter and get all the resulting models.
        return Future.flatMap(on: self.connection.eventLoop) { return self.filter(field ~~ values).all() }
    }
}

extension QueryBuilder where Database.Query: FluentSQLQuery {
    func groupBy<M, T>(_ field: KeyPath<M, T>) -> Self where M: SQLTable {
        self.query.groupBy.append(.groupBy(.column(.keyPath(field))))
        return self
    }
}
