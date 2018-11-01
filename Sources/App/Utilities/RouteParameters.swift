import Fluent
import Vapor

extension ParametersContainer {
    
    /// Gets the ID values for model request paramaters.
    ///
    /// - Note: This method _does note_ advance the paramaters, so the model is still availible from the container.
    ///
    /// - Parameter model: The model type to get the ID for.
    /// - Returns: The ID from the request paramaters.
    func id<M>(for model: M.Type = M.self)throws -> M.ID where M: Model & Parameter, M.ID: LosslessStringConvertible {
        guard let raw = self.rawValues(for: model).first else {
            throw RoutingError(identifier: "badParameterType", reason: "No parameter values found for type `\(M.self)`")
        }
        guard let id = M.ID(raw) else {
            throw RoutingError(identifier: "badParameterValue", reason: "Unable to convert value `\(raw)` to ID type `\(M.ID.self)`")
        }
        
        return id
    }
}
