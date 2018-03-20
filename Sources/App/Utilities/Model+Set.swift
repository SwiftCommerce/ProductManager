import CodableKit

extension QueryBuilder {
    func set<Value>(_ key: KeyPath<Model, Value>, to value: Value) -> Future<Model> where Value: Encodable & KeyStringDecodable {
        self.query.data = [
            key.makeQueryField().name: value
        ]
        self.query.action = .update
        return self.first().unwrap(or: Abort(.notFound, reason: "No \(Model.entity) model found with given query"))
    }
    
    func set<Value>(_ key: KeyPath<Model, Value>, to value: Value) -> Future<[Model]> where Value: Encodable & KeyStringDecodable {
        self.query.data = [
            key.makeQueryField().name: value
        ]
        self.query.action = .update
        return self.all()
    }
    
    func set<Value>(_ key: KeyPath<Model, Value>, to value: Value) -> Future<Void> where Value: Encodable & KeyStringDecodable {
        self.query.data = [
            key.makeQueryField().name: value
        ]
        self.query.action = .update
        return self.execute()
    }
    
    @discardableResult
    public func filter<T>(_ field: KeyPath<Model, T>, in values: [Encodable]?) -> Future<[Model]> where T: KeyStringDecodable {
        guard let values = values else {
            return Future([])
        }
        
        let filter = QueryFilter<Model.Database>(
            entity: Model.entity,
            method: .subset(field.makeQueryField(), .in, .array(values))
        )
        self.addFilter(filter)
        return self.all()
    }
}
