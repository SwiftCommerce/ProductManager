extension Model {
    func assertID() -> Future<Self.ID> {
        do {
            return try Future(self.requireID())
        } catch {
            return Future(error: error)
        }
    }
}
