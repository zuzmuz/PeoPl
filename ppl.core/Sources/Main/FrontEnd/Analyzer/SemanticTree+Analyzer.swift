public protocol SemanticChecker:
    TypeDeclarationsChecker
    // ValueDefinitionChecker
{
    func semanticCheck() -> Result<Semantic.Context, Semantic.ErrorList>
}

// extension SemanticChecker {
//     public func semanticCheck(
//     ) -> Result<Semantic.Context, Semantic.ErrorList> {
//         let intrinsicDeclarations = Semantic.getIntrinsicDeclarations()
//
//         // Getting type declarations
//         let (typeDeclarations, typeLookup, typeErrors) =
//             self.resolveTypeSymbols(
//                 contextTypeDeclarations: intrinsicDeclarations.typeDeclarations)
//
//         let allTypeDeclarations = intrinsicDeclarations.typeDeclarations
//             .merging(typeDeclarations) { $1 }
        // Getting value decalrations
        // let (valueDeclarations, valueLookup, functionExpressions, valueErrors) =
        //     self.resolveValueSymbols(
        //         typeDeclarations: allTypeDeclarations,
        //         contextValueDeclarations: intrinsicDeclarations
        //             .valueDeclarations)
        //
        // let allValueDeclarations = intrinsicDeclarations.valueDeclarations
        //     .merging(valueDeclarations) { $1 }
        //
        // let valueDefinitionsResults:
        //     [Result<
        //         (Semantic.FunctionSignature, Semantic.Expression),
        //         Semantic.Error
        //     >] =
        //         // TODO: reconsider functions expression, do we need for declarations to be function expressions
        //         functionExpressions.map { signature, expression in
        //             do throws(Semantic.Error) {
        //                 let inputExpression: Semantic.Expression
        //                 let localScope: [Semantic.Tag: Semantic.TypeSpecifier]
        //                 switch signature.inputType.tag {
        //                 case .input:
        //                     localScope = signature.arguments
        //                     inputExpression = .init(
        //                         expressionType: .input,
        //                         type: signature.inputType.type)
        //                 default:
        //                     localScope = signature.arguments.merging([
        //                         signature.inputType.tag: signature.inputType
        //                             .type
        //                     ]) { $1 }
        //                     inputExpression = .init(
        //                         expressionType: .input,
        //                         type: .nothing)
        //                 }
        //                 let checkedExpression =
        //                     try expression.checkType(
        //                         with: inputExpression,
        //                         localScope: localScope,
        //                         context: .init(
        //                             typeDeclarations: allTypeDeclarations,
        //                             valueDeclarations: allValueDeclarations,
        //                             operatorDeclarations:
        //                                 intrinsicDeclarations
        //                                 .operatorDeclarations
        //                         ))
        //                 return .success(
        //                     (
        //                         signature,
        //                         checkedExpression
        //                     ))
        //             } catch {
        //                 return .failure(error)
        //             }
        //         }
        //
        // let typeCheckingErrors = valueDefinitionsResults.compactMap { result in
        //     if case let .failure(error) = result {
        //         return error
        //     }
        //     return nil
        // }
        //
        // let allErrors = typeErrors + valueErrors + typeCheckingErrors
        // if allErrors.count > 0 {
        //     return .failure(.init(errors: allErrors))
        // }
        //
        // let valueDefinitions: Semantic.ValueDefinitionsMap =
        //     Dictionary(
        //         uniqueKeysWithValues:
        //             valueDefinitionsResults.compactMap { result in
        //                 if case let .success((signature, expression)) = result {
        //                     return (.function(signature), expression)
        //                 }
        //                 return nil
        //             })
        // NOTE: I might need to send only function to code gen
    //     return .success(
    //         .init(definitions: .init(valueDefinitions: valueDefinitions)))
    // }
// }

// extension Syntax.Module: SemanticChecker {}
// extension Syntax.Project: SemanticChecker {}
