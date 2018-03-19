extension Model {
    func assertID() -> Future<Self.ID> {
        return Future.map({
            return try self.requireID()
        })
    }
}
