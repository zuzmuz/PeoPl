// protocol TypeDeclarationChecker {
//
//     /// Returns all declared types in context
//     /// Can contain duplicates, and illegal type definitions
//     func getTypeDeclarations() -> [Syntax.TypeDefinition]
//
//     /// Sanitize type definitions by removing duplicate declarations
//     /// Verify type definitions by detecting invalid types identifiers for members
//     /// Detect circular dependencies in type definitions,
//     /// because types are inline value types
//     /// Types do not support indirection (without wrappers)
//     /// - Paramerter environment: The existing semantic context,
//     /// contains builtin (for now) NOTE: extend with library packages
//     /// - Returns: A tuple containing the sanitized type definitions and any errors that occurred
//     func resolveTypeDefinitions(
//         builtins: borrowing SemanticContext // NOTE: builtins can be merged with expternals once we figure out namespacing
//         // externals: borrowing [String: SemanticContext]
//     ) -> (
//         typesDefinitions: [Syntax.NominalType: Syntax.TypeDefinition],
//         errors: [TypeSemanticError]
//     )
// }
// }
//
// fileprivate enum NodeState {
//     case visiting
//     case visited
// }
//
// extension TypeDeclarationChecker {
//
//     func resolveTypeDefinitions(
//         builtins: borrowing SemanticContext
//         // externals: borrowing [String: SemanticContext]
//     ) -> (
//         typesDefinitions: [NominalType: TypeDefinition],
//         errors: [TypeSemanticError]
//     ) {
//         let declarations = self.getTypeDeclarations()
//
//         let typesLocations = declarations.reduce(into: [:]) { acc, type in
//             acc[type.identifier] = (acc[type.identifier] ?? []) + [type]
//         }
//         
//         // detecting redeclarations
//         let redeclarations = typesLocations.compactMap { _, typeLocations in
//             if typeLocations.count > 1 {
//                 return TypeSemanticError.redeclaration(locations: typeLocations.map { $0.location })
//             } else {
//                 return nil
//             }
//         }
//
//         let types = typesLocations.compactMapValues { types in
//             return types.first
//         }
//
//         // detecting shadowings
//         let shadowings = types.compactMap { type, typeDefinition in
//             if let exisitingType = builtins.types[type] {
//                 return TypeSemanticError.shadowing(
//                     location: typeDefinition.location,
//                     module: "builtin",
//                     typeDefinition: exisitingType)
//             // } else if let exisitingType = externals.values.compactMap({ $0.types[type] }).first {
//             //     return TypeSemanticError.shadowing(
//             //         location: typeDefinition.location,
//             //         module: "someone", // NOTE: I need to fix this so that I get the module name
//             //         typeDefinition: exisitingType)
//             } else {
//                 return nil
//             }
//         }
//
//         // TODO: nominal type chain should not contain type arguments, only last one
//
//         // detecting invalid members types
//         let typesNotInScope = types.flatMap { type, definition in
//             return definition.allParams.flatMap { param in
//                 let errors: [TypeSemanticError] = param.type.getNominalTypesFromIdentifier().compactMap { paramType in
//                     if let _ = types[paramType] ?? builtins.types[paramType] {
//                         return nil
//                     } else {
//                     return TypeSemanticError.typeNotInScope(
//                         location: param.location,
//                         type: paramType,
//                         typesInScope: types.keys)
//                     }
//                 }
//                 return errors
//             }
//         }
//
//         let cyclicalDependencies = checkCyclicalDependencies(types: types, builtins: builtins)
//
//         return (
//             typesDefinitions: types,
//             errors: redeclarations + shadowings + typesNotInScope + cyclicalDependencies
//         )
//     }
//
//     private func checkCyclicalDependencies(
//         types: [NominalType: TypeDefinition],
//         builtins: SemanticContext
//     ) -> [TypeSemanticError] {
//         
//         var nodeStates: [NominalType: NodeState] = [:]
//         var cycles: [TypeSemanticError] = []
//
//         func checkCyclicalDependency(typeIdentifier: TypeIdentifier) {
//             switch typeIdentifier {
//             case let .nominal(nominal):
//                 checkCyclicalDependency(nominal: nominal)
//             case let .unnamedTuple(tuple):
//                 tuple.types.forEach { typeIdentifier in
//                     checkCyclicalDependency(typeIdentifier: typeIdentifier)
//                 }
//             case let .namedTuple(tuple):
//                 tuple.types.forEach { tupleParam in
//                     checkCyclicalDependency(typeIdentifier: tupleParam.type)
//                 }
//             case let .union(union):
//                 union.types.forEach { typeIdentifier in
//                     checkCyclicalDependency(typeIdentifier: typeIdentifier)
//                 }
//             default:
//                 break
//             }
//         }
//
//         func checkCyclicalDependency(nominal: NominalType) {
//             if nodeStates[nominal] == .visited {
//                 return
//             }
//             if nodeStates[nominal] == .visiting {
//                 cycles.append(.cyclicType(cyclicType: nominal))
//                 return 
//             }
//             nodeStates[nominal] = .visiting
//             guard let typeDefinition = types[nominal] ?? builtins.types[nominal] else { return /*type checker should catch this error*/ }
//
//             switch typeDefinition {
//             case let .simple(simple):
//                 simple.params.forEach { param in
//                     checkCyclicalDependency(typeIdentifier: param.type)
//                 }
//             case let .sum(sum):
//                 sum.cases.forEach { simpleCase in
//                     simpleCase.params.forEach { param in
//                         checkCyclicalDependency(typeIdentifier: param.type)
//                     }
//                 }
//             }
//             nodeStates[nominal] = .visited
//         }
//         
//         types.forEach { nominal, typeDefinition in
//             checkCyclicalDependency(nominal: nominal)
//         }
//
//         return cycles
//     }
// }
//
