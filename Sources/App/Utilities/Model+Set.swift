import CodableKit

extension QueryBuilder {
    func set<Value>(_ key: KeyPath<Model, Value>, to value: Value) -> Future<Void> where Value: Encodable & KeyStringDecodable {
        self.query.data = [
            key.makeQueryField().name: value
        ]
        self.query.action = .update
        return self.execute()
    }
}
