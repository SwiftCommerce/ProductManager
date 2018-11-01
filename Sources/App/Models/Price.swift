import Foundation
import Vapor

/// The price for a product.
/// A `Price` connects to a `Product` model through the
/// `ProductPrice` pivot model.
final class Price: Content, MySQLModel, Parameter {
    static let entity: String = "prices"
    
    /// The database ID of the model.
    var id: Int?
    
    /// The amount the model's currency in cents
    /// required to purchase the connected product.
    /// - Note: We store cents because we avoid decimal
    ///   inaccuracies by not using `Float` or `Double`.
    var cents: Int
    
    /// The date the price became valid on.
    var activeFrom: Date
    
    /// The date the price is no longer valid.
    var activeTo: Date
    
    /// Wheather or not the price is the current price of the product.
    var active: Bool
    
    /// The currency used for the price, i.e. EUR, USD, GBR.
    var currency: String
    
    /// The parent product model that owns the price model.
    let productID: Product.ID
    
    /// Creates a new `Price` model from given data.
    /// Make sure you call `.save` on it to store it in the database.
    ///
    /// - Parameters:
    ///   - price: The amount of the owning translation's current is needed to purchase the given product.
    ///   - activeFrom: The date the price starts being valid. If you pass in `nil`, it defaults to the time the price is created (`Date()`).
    ///   - activeTo: The date the price becomes invalid. If you pass in `nil`, it defaults to some time in the distant future (`Date.distantFuture`).
    ///   - active: Wheather or not the price is valid. If you pass in `nil`, the value is calculated of the `activeFrom` and `activeTo` dates.
    init(productID: Product.ID, cents: Int, activeFrom: Date?, activeTo: Date?, active: Bool?, currency: String)throws {
        
        // Use some odd verification fot the 'currency' value.
        // It should be a three lettter character string.
        
        // We check for 0 and 1 so `RefletionDecodable` works.
        guard
            (currency.count == 3 && currency.replacingOccurrences(of: "[^a-zA-Z]", with: "", options: .regularExpression) == currency) ||
            (currency == "1" || currency == "0")
        else {
            let count = currency.replacingOccurrences(of: "[^a-zA-Z]", with: "", options: .regularExpression).count
            throw Abort(.badRequest, reason: "'currency' field must contain 3 letter characters. Found \(count)")
        }
        
        let af = activeFrom ?? Date.distantPast
        let at: Date = activeTo ?? Date.distantFuture
        let currentDate = Date()
        
        self.cents = cents
        self.activeFrom = af
        self.activeTo = at
        self.active = active ?? (currentDate > af && currentDate < at)
        self.currency = currency.uppercased()
        self.productID = productID
    }
    
    // We have a custom decoding init so we can have the same default values as the ones in the main init.
    convenience init(from decoder: Decoder)throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            productID: container.decode(Product.ID.self, forKey: .productID),
            cents: container.decode(Int.self, forKey: .cents),
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
        self.cents = body.cents ?? self.cents
        self.activeFrom = body.activeFrom ?? self.activeFrom
        self.activeTo = body.activeTo ?? self.activeTo
        self.active = body.active ?? self.active
        
        return self
    }
}

extension Price: Migration {
    
    /// See `Migration.prepare(on:)`.
    ///
    /// We create a custom implementation of this method so we can have a foreign-key constraint
    /// between the `Price.productID` property and the `Product.id` property.
    static func prepare(on conn: MySQLConnection) -> Future<Void> {
        return MySQLDatabase.create(self, on: conn) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.productID, to: \Product.id)
        }
    }
}

/// A representation of a request's body when you need to update a `Price` model.
struct PriceUpdateBody: Content {
    
    ///
    let cents: Int?
    
    ///
    let activeFrom: Date?
    
    ///
    let activeTo: Date?
    
    ///
    let active: Bool?
}
