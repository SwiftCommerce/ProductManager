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
}
