enum ProductStatus: Int, Codable, ReflectionDecodable, MySQLDataConvertible, MySQLColumnDefinitionStaticRepresentable {
    case draft
    case published
    case deactivated
    
    static var keyStringTrue: ProductStatus = .published
    static var keyStringFalse: ProductStatus = .deactivated
    
    static var mySQLColumnDefinition: MySQLColumnDefinition = .smallInt()
    
    func convertToMySQLData() throws -> MySQLData {
        return .init(integer: self.rawValue)
    }
    
    static func convertFromMySQLData(_ mysqlData: MySQLData) throws -> ProductStatus {
        guard let rawValue = try mysqlData.integer(Int.self) else {
            throw MySQLError(identifier: "badType", reason: "A `ProdcutStatus` case must be initialized with an integer", source: .capture())
        }
        
        guard let status = ProductStatus(rawValue: rawValue) else {
            throw MySQLError(identifier: "badInt", reason: "No case exists for`ProductStatus` enum with the raw value \(rawValue)", source: .capture())
        }
        
        return status
    }
}

