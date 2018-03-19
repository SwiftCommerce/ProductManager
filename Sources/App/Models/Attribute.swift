final class Attribute: Content, MySQLModel, Migration, Parameter {
    var id: Int?
    
    let name: String
    var value: String
    
    init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}
