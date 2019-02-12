import Vapor

extension Product {
    
    /// What property the products from a response should be sorted by.
    enum Sort: String, Content, Hashable {
        case price
        case category
        case name
    }
    
    /// The direction the product property will be sorted.
    enum SortDirection: String, Content, Hashable {
        
        /// Causes products to appear wth the smallest property first.
        ///
        /// 0...
        /// a...
        case ascending
        
        /// Causes products to appear wth the largest property first.
        ///
        /// 100...
        /// z...
        case descending
    }
}
