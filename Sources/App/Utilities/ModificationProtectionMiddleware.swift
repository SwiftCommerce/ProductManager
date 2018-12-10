import JWTMiddleware
import Vapor

/// Requires JWT authorization of a route if it has a
/// `PATCH`, `PUT`, `POST`, or `DELETE` method.
/// This means any request used to modify a model or collection to
/// must be authorized.
final class ModificationProtectionMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        
        // Check the request method
        let method = request.http.method
        if method == .PATCH || method == .PUT || method == .POST || method == .DELETE {
            
            guard let token = request.http.headers.bearerAuthorization?.token else {
                throw Abort(.unauthorized, reason: "'Authorization' header with bearer token is missing")
            }
            
            let jwt = try request.make(JWTService.self)
            let payload = try JWT<Payload>(from: Data(token.utf8), verifiedUsing: jwt.signer).payload
            
            guard payload.status == Payload.adminStatus else {
                throw Abort(.forbidden, reason: "You must be an administrator to modify the Product Manager resources.")
            }
        }
        
        return try next.respond(to: request)
    }
}

struct Payload: JWTPayload {
    static let adminStatus = 0
    
    let exp: Date
    let status: Int
    
    func verify(using signer: JWTSigner) throws {
        try ExpirationClaim(value: self.exp).verifyNotExpired()
    }
}
