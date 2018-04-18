import Vapor

/// The curremt working status of a product model.
enum ProductStatus: Int, Codable, ReflectionDecodable {
    
    /// The product is a draft and not show to customers.
    case draft
    
    /// The product is active and viewable by customers.
    case published
    
    /// The product was available for viewing, but currently it is not.
    case deactivated
}

//extension ProductStatus: URLEncodedFormDataConvertible {
//    
//}

extension ProductStatus: MySQLColumnDefinitionStaticRepresentable {
    
    /// The type a column should be in the database when a model
    /// has a property of type `ProductStatus`.
    static var mySQLColumnDefinition: MySQLColumnDefinition = .smallInt()
}

extension ProductStatus: MySQLDataConvertible {
    
    /// Creates a `MySQLData` representation of the current case.
    func convertToMySQLData() throws -> MySQLData {
        return .init(integer: self.rawValue)
    }
    
    /// Creates `ProductStatus` case from a `MySQLData` object.
    static func convertFromMySQLData(_ mysqlData: MySQLData) throws -> ProductStatus {
        
        // Get the raw value as an `Int`. If the value is enot an int, throw.
        guard let rawValue = try mysqlData.integer(Int.self) else {
            throw MySQLError(identifier: "badType", reason: "A `ProdcutStatus` case must be initialized with an integer", source: .capture())
        }
        
        // Create a status from the raw value. If the value is invalid, throw.
        guard let status = ProductStatus(rawValue: rawValue) else {
            throw MySQLError(identifier: "badInt", reason: "No case exists for`ProductStatus` enum with the raw value \(rawValue)", source: .capture())
        }
        
        return status
    }
}
