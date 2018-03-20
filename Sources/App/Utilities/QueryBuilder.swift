import CodableKit

extension QueryBuilder {
    
    /// Sets the value of the column on all the models matching the current query.
    ///
    /// - Parameters:
    ///   - key: The colunm to change the value of.
    ///   - value: The new value for the column.
    /// - Returns: The first model that was mutated (specific use for this service).
    func set<Value>(_ key: KeyPath<Model, Value>, to value: Value) -> Future<Model> where Value: Encodable & KeyStringDecodable {
        // Set the data for the query.
        // `UPDATE * SET key = value ...`
        self.query.data = [
            key.makeQueryField().name: value
        ]
        
        // Set the queries action to `UPDATE` (vs `SELECT`, etc.).
        self.query.action = .update
        
        // Run the query, get the first model and unwrap it.
        return self.first().unwrap(or: Abort(.notFound, reason: "No \(Model.entity) model found with given query"))
    }
    
    /// Gets all models from a table that have any one of a list of values in a specefied column.
    ///
    /// - Parameters:
    ///   - field: The column to check for a given value in.
    ///   - values: The values to check for in the columns.
    /// - Returns: All the models that match the given query, wrapped in a future.
    @discardableResult
    public func filter<T>(_ field: KeyPath<Model, T>, in values: [Encodable]?) -> Future<[Model]> where T: KeyStringDecodable {
        // This method is different because we allow `nil` to be passed in instead of an array.
        // If we get `nil` instead of an array, return an empty array immediately, it saves time.
        guard let values = values else {
            return Future([])
        }
        
        // Create a new filter to add to the query for the model's table, and the colunm and values passed in.
        let filter = QueryFilter<Model.Database>(
            entity: Model.entity,
            method: .subset(field.makeQueryField(), .in, .array(values))
        )
        
        // Add the filter to the query.
        self.addFilter(filter)
        
        // Run the query and return all the resulting models.
        return self.all()
    }
}
