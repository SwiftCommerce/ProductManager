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
            
            // Add `JWTVerificationMiddleware` to the middleware chain.
            return try JWTVerificationMiddleware().respond(to: request, chainingTo: next)
        } else {
            
            // Call the next responder. No auth necessary.
            return try next.respond(to: request)
        }
    }
}
