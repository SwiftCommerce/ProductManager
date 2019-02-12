import FluentMySQL

/// The curremt working status of a product model.
enum ProductStatus: Int, CaseIterable, MySQLEnumType {
    
    /// The product is a draft and not show to customers.
    case draft
    
    /// The product is active and viewable by customers.
    case published
    
    /// The product was available for viewing, but currently it is not.
    case deactivated
}
