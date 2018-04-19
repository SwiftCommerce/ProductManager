import Foundation
import Vapor

/// The price for a product.
/// A `Price` connects to a `Product` model through the
/// `ProductPrice` pivot model.
final class Price: Content, MySQLModel, Migration, Parameter {
    
    /// The database ID of the model.
    var id: Int?
    
    /// The amount of the translation's currency required for the product's purchase.
    var price: Float
    
    /// The date the price became valid on.
    var activeFrom: Date
    
    /// The date the price is no longer valid.
    var activeTo: Date
    
    /// Wheather or not the price is the current price of the product.
    var active: Bool
    
    /// The currency used for the price, i.e. EUR, USD, GBR.
    var currency: String
    
    
    /// Creates a new `Price` model from given data.
    /// Make sure you call `.save` on it to store it in the database.
    ///
    /// - Parameters:
    ///   - price: The amount of the owning translation's current is needed to purchase the given product.
    ///   - activeFrom: The date the price starts being valid. If you pass in `nil`, it defaults to the time the price is created (`Date()`).
    ///   - activeTo: The date the price becomes invalid. If you pass in `nil`, it defaults to some time in the distant future (`Date.distantFuture`).
    ///   - active: Wheather or not the price is valid. If you pass in `nil`, the value is calculated of the `activeFrom` and `activeTo` dates.
    ///   - translationName: The name of the translation that owns the price.
    init(price: Float, activeFrom: Date?, activeTo: Date?, active: Bool?, currency: String)throws {
        guard
            (currency.count == 3 && currency.replacingOccurrences(of: "\\d", with: "$1", options: .regularExpression) == currency) ||
            (currency == "1" || currency == "0")
        else {
            throw Abort(.badRequest, reason: "'currency' field must contain 3 characters. Found \(currency.count)")
        }
        
        let af = activeFrom ?? Date()
        let at: Date = activeTo ?? Date.distantFuture
        
        self.price = price
        self.activeFrom = af
        self.activeTo = at
        self.active = active ?? (Date() > af && Date() < at)
        self.currency = currency.uppercased()
    }
    
    // We have a custom decoding init so we can have the same default values as the ones in the main init.
    convenience init(from decoder: Decoder)throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            price: container.decode(Float.self, forKey: .price),
            activeFrom: container.decodeIfPresent(Date.self, forKey: .activeFrom),
            activeTo: container.decodeIfPresent(Date.self, forKey: .activeTo),
            active: container.decodeIfPresent(Bool.self, forKey: .active),
            currency: container.decode(String.self, forKey: .currency)
        )
        
        // This init method is used by Fluent to initailize an instance of the class,
        // so we need to assign all properties.
        // This method is also used by Fluent to create the tables in the datbase.
        self.id = try container.decodeIfPresent(Int.self, forKey: .id)
    }
    
    
    /// Updates the model with data from a request and saves it.
    ///
    /// - Parameters:
    ///   - body: The body of a request, decoded to a `PriceUpdateBody`.
    ///   - executor: The object that will be used to save the model to the database.
    /// - Returns: A void future, which will signal once the update is complete.
    func update(with body: PriceUpdateBody) -> Price {
        // Update all the properties if a value for it is found in the body, else use the old value.
        self.price = body.price ?? self.price
        self.activeFrom = body.activeFrom ?? self.activeFrom
        self.activeTo = body.activeTo ?? self.activeTo
        self.active = body.active ?? self.active
        
        return self
    }
}

/// A representation of a request's body when you need to update a `Price` model.
struct PriceUpdateBody: Content {
    
    ///
    let price: Float?
    
    ///
    let activeFrom: Date?
    
    ///
    let activeTo: Date?
    
    ///
    let active: Bool?
}
