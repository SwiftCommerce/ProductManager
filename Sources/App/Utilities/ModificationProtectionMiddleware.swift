import JWTMiddleware
import Vapor

final class ModificationProtectionMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        let method = request.http.method
        if method == .PATCH || method == .PUT || method == .POST || method == .DELETE {
            return try JWTVerificationMiddleware().respond(to: request, chainingTo: next)
        } else {
            return try next.respond(to: request)
        }
    }
}
