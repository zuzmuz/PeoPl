//
// protocol FunctionDeclarationChecker {
//     func getFunctionDeclarations() -> [FunctionDefinition]
//     func getOperatorOverloadDeclarations() -> [OperatorOverloadDefinition]
//
//     func resolveFunctionDefinitions(
//         typesDefinitions: borrowing [NominalType: TypeDefinition],
//         builtins: borrowing SemanticContext
//     ) -> (
//         functions: [FunctionDefinition: FunctionDefinition],
//         functionsIdentifiers: [FunctionIdentifier: [FunctionDefinition]],
//         functionsInputTypeIdentifiers: [TypeIdentifier: [FunctionDefinition]],
//         operators: [OperatorOverloadDefinition: OperatorOverloadDefinition],
//         errors: [FunctionSemanticError]
//     )
// }
//
// extension FunctionDeclarationChecker {
//     func resolveFunctionDefinitions(
//         typesDefinitions: borrowing [NominalType: TypeDefinition],
//         builtins: borrowing SemanticContext
//     ) -> (
//         functions: [FunctionDefinition: FunctionDefinition],
//         functionsIdentifiers: [FunctionIdentifier: [FunctionDefinition]],
//         functionsInputTypeIdentifiers: [TypeIdentifier: [FunctionDefinition]],
//         operators: [OperatorOverloadDefinition: OperatorOverloadDefinition],
//         errors: [FunctionSemanticError]
//     ) {
//
//         let functionDeclarations = self.getFunctionDeclarations()
//         let (functions, functionsRedeclarations) = resolveDefinitions(
//             declarations: functionDeclarations,
//             typesDefinitions: typesDefinitions)
//
//         let operatorsDeclarations = self.getOperatorOverloadDeclarations()
//         let (operators, operatorsRedeclarations) = resolveDefinitions(
//             declarations: operatorsDeclarations,
//             typesDefinitions: typesDefinitions)
//
//         
//         let functionsIdentifiers = functions.reduce(into: [:]) { acc, element in
//             acc[element.key.functionIdentifier] =
//                 (acc[element.key.functionIdentifier] ?? []) + [element.key]
//         }
//         let functionsInputTypeIdentifiers = functions.reduce(into: [:]) { acc, element in
//             acc[element.key.inputType] = (acc[element.key.inputType] ?? []) + [element.key]
//         }
//
//         let functionTypeCheckErrors = functions.flatMap { function, _ in
//             
//             let inputTypeNotInScopeErrors: [FunctionSemanticError] = function.inputType.getNominalTypesFromIdentifier().compactMap { type in
//                 if let _ = typesDefinitions[type] ?? builtins.types[type] {
//                     return nil
//                 } else {
//                     return FunctionSemanticError.typeNotInScope(
//                         location: type.location,
//                         type: type,
//                         typesInScope: typesDefinitions.keys)
//                 }
//             }
//
//             let paramsTypesNotInScopeErrors = function.params.flatMap { param in
//                 let errors: [FunctionSemanticError] = param.type.getNominalTypesFromIdentifier().compactMap { type in
//                     if let _ = typesDefinitions[type] ?? builtins.types[type] {
//                         return nil
//                     } else {
//                         return FunctionSemanticError.typeNotInScope(
//                             location: type.location,
//                             type: type,
//                             typesInScope: typesDefinitions.keys)
//                     }
//                 }
//                 return errors
//             }
//
//             let outputTypeNotInScopeErrors: [FunctionSemanticError] = function.outputType.getNominalTypesFromIdentifier().compactMap { type in
//                 if let _ = typesDefinitions[type] ?? builtins.types[type] {
//                     return nil
//                 } else {
//                     return FunctionSemanticError.typeNotInScope(
//                         location: type.location,
//                         type: type,
//                         typesInScope: typesDefinitions.keys)
//                 }
//             }
//
//             return inputTypeNotInScopeErrors + paramsTypesNotInScopeErrors + outputTypeNotInScopeErrors
//         }
//
//         let operatorTypeCheckErrors = operators.flatMap { function, _ in
//             let leftTypeNotInScopeErrors = function.left.getNominalTypesFromIdentifier().compactMap { type in
//                 if let _ = typesDefinitions[type] ?? builtins.types[type] {
//                     return FunctionSemanticError.typeNotInScope(
//                         location: function.location, // WARN: need to rethink node locations
//                         type: type,
//                         typesInScope: typesDefinitions.keys)
//                 } else {
//                     return nil
//                 }
//             }
//
//             let rightTypNotInScopeErrors = function.right.getNominalTypesFromIdentifier().compactMap { type in
//                 if let _ = typesDefinitions[type] ?? builtins.types[type] {
//                     return FunctionSemanticError.typeNotInScope(
//                         location: function.location, // WARN: need to rethink node locations
//                         type: type,
//                         typesInScope: typesDefinitions.keys)
//                 } else {
//                     return nil
//                 }
//             }
//
//             return leftTypeNotInScopeErrors + rightTypNotInScopeErrors
//         }
//
//         return (
//             functions: functions,
//             functionsIdentifiers: functionsIdentifiers,
//             functionsInputTypeIdentifiers: functionsInputTypeIdentifiers,
//             operators: operators,
//             errors: 
//                 functionsRedeclarations +
//                 functionTypeCheckErrors +
//                 operatorsRedeclarations +
//                 operatorTypeCheckErrors
//             )
//     }
//
//     private func resolveDefinitions<Declaration>(
//         declarations: [Declaration],
//         typesDefinitions: borrowing [NominalType: TypeDefinition]
//     ) -> (
//         definitions: [Declaration: Declaration],
//         errors: [FunctionSemanticError]
//     ) where Declaration: Hashable, Declaration: SyntaxNode {
//
//         let locations = declarations.reduce(into: [:]) { acc, declaration in
//             acc[declaration] = (acc[declaration] ?? []) + [declaration]
//         }
//
//         let redeclarations = locations.compactMap { _, locations in
//             if locations.count > 1 {
//                 return FunctionSemanticError.redeclaration(locations: locations.map { $0.location })
//             } else {
//                 return nil
//             }
//         }
//
//         // FIX: should handle builtin function redeclaration
//
//         let definitions = locations.compactMapValues { definitions in
//             return definitions.first
//         }
//
//         return (
//             definitions: definitions,
//             errors: redeclarations
//         )
//     }
// }
//
