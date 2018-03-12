final class Category: Content, MySQLModel, Migration {
    var id: Int?
    
    let name: String
    
    init(name: String) { self.name = name }
}
