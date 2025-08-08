import Foundation

extension Semantic {
    public struct Error: LocalizedError {
        let location: Syntax.NodeLocation
        let errorChoice: ErrorType

        enum ErrorType {
            case notImplemented(String)
            case cyclicType(stack: [Syntax.Definition])
            case typeRedeclaration(
                identifier: Semantic.QualifiedIdentifier,
                otherLocations: [Syntax.NodeLocation])
            case typeShadowing(
                identifier: Semantic.QualifiedIdentifier)
            case typeNotInScope(identifier: Syntax.QualifiedIdentifier)
            case homogeneousTypeProductInSum
            case duplicateFieldName
            case functionRedeclaration(
                signature: Semantic.FunctionSignature,
                otherLocations: [Syntax.NodeLocation])
            case functionRedeclaringType(
                identifier: Semantic.QualifiedIdentifier,
                typeLocation: Syntax.NodeLocation,
            )
            case taggedTypeSpecifierRequired
            case inputMismatch(
                expected: Semantic.TypeSpecifier,
                received: Semantic.TypeSpecifier)
            case invalidOperation(
                leftType: Semantic.TypeSpecifier,
                op: Operator,
                rightType: Semantic.TypeSpecifier)
            // case undefinedField(field: String)
            // case undefinedType(identifier: Semantic.QualifiedIdentifier)
            case undefinedCall(signature: Semantic.FunctionSignature)
            case duplicatedExpressionFieldName
            case consecutiveUnary
            case bindingNotAllowed
            case bindingMismatch
            case guardShouldReturnBool(
                received: Semantic.TypeSpecifier)
            case functionBodyOutputTypeMismatch(
                expected: Semantic.TypeSpecifier,
                received: Semantic.TypeSpecifier)
        }

        public var errorDescription: String? {
            switch self.errorChoice {
            case let .notImplemented(message):
                return "Feature not implemented: \(message), at \(location)"
            default:
                return ""
            }
        }
    }

    public struct ErrorList: LocalizedError {
        public let errors: [Error]
    }
}
