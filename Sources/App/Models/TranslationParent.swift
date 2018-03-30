/// Defines a model as being connected to `Translation` models through a `ModelTranslation` pivot.
protocol TranslationParent: MySQLModel {
    
    /// The translation model type that the parent model connects to.
    associatedtype Translation: App.Translation
    
    /// Creates a query to access connected translations by their `parentID` property.
    ///
    /// - parameter executor: The object that gets the connetion to the database,
    ///   which is used to run the query.
    func translations(on executor: DatabaseConnectable)throws -> QueryBuilder<Translation, Translation>
}

extension TranslationParent {
    
    /// Creates a query to access connected translations by their `parentID` property.
    ///
    /// - parameter executor: The object that gets the connetion to the database,
    ///   which is used to run the query.
    func translations(on executor: DatabaseConnectable)throws -> QueryBuilder<Self.Translation, Self.Translation> {
        
        // The parent model has to be saved to the daatbase to be connected to any translations,
        // so make sure it exists in the DB.
        let id = try self.requireID()
        
        // Get all the translation models twho's `parentID` is the ID of the current model.
        return try Translation.query(on: executor).filter(\.parentID == id)
    }
}
