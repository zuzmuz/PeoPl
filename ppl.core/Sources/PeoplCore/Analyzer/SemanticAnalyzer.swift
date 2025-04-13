// enum Typed {
//     typealias FieldIdentifier = String
//     typealias TypeName = String
//     typealias FunctionIdentifier = String
//     typealias Argument = (name: String, value: Expression)
//     typealias ParamDefinition = (name: String, type: TypeId)
//
//     enum TypeId {
//         case nothing
//         case never
//         case nominal(TypeName)
//         case lambda
//         case unnamedTuple([TypeId])
//         case namedTuple([ParamDefinition])
//         case union([TypeId])
//     }
//
//     struct FunctionDefinition {
//         let inputType: TypeId
//         let identifier: FunctionIdentifier
//         let params: [ParamDefinition]
//         let outputType: TypeId
//         let body: Expression
//     }
//
//     struct OperatorOverloadDefinition {
//         let left: TypeId
//         let op: String
//         let right: TypeId
//         let output: TypeId
//         let body: Expression
//     }
//
//     enum TypeDefinition {
//         case simple(identifier: TypeName, params: [ParamDefinition])
//         case sum(
//             identifier: TypeName,
//             cases: [(identifier: TypeName, params: ParamDefinition)])
//     }
//
//     indirect enum Expression {
//         case nothing
//         case never
//         case intLiteral(value: UInt64)
//         case floatLiteral(value: Double)
//         case stringLiteral(value: String)
//         case boolLiteral(value: Bool)
//         case unary(Operator, expression: Expression, type: TypeId)
//         case binary(Operator, left: Expression, right: Expression, type: TypeId)
//         case unnamedTuple([Expression], type: TypeId)
//         case namedTuple([Argument], type: TypeId)
//         // case lambda(Expression, type: TypeIdentifier)
//         case call(Callable, type: TypeId)
//         // case access(Expression.Access, type: TypeIdentifier)
//         case field(FieldIdentifier, type: TypeId)
//         case branched([TypedBranch], type: TypeId)
//         case piped(left: Expression, right: Expression, type: TypeId)
//
//         var type: TypeId {
//             switch self {
//             case .nothing:
//                 return .nothing
//             case .never:
//                 return .never
//             case .intLiteral:
//                 return Builtins.i64
//             case .floatLiteral:
//                 return Builtins.f64
//             case .stringLiteral:
//                 return Builtins.string
//             case .boolLiteral:
//                 return Builtins.bool
//             case .unary(_, _, let type),
//                 .binary(_, _, _, let type),
//                 .unnamedTuple(_, let type),
//                 .namedTuple(_, let type),
//                 // .lambda(_, let type), // WARN: this might not be correct
//                 .call(_, let type),
//                 // .access(_, let type),
//                 .field(_, let type),
//                 .branched(_, let type),
//                 .piped(_, _, let type):
//                 return type
//             }
//         }
//     }
//
//     struct LocalScope {
//         let fields: [String: TypeId]
//     }
//
//     /// Contains the semantic context of a module
//     struct SemanticContext {
//         let types: [TypeName: TypeDefinition]
//         let functions: [String: FunctionDefinition] //TODO: Function identifier
//         let functionsIdentifiers: [FunctionIdentifier: [FunctionDefinition]]
//         let functionsInputTypeIdentifiers: [TypeName: [FunctionDefinition]]
//         let operators: [String: OperatorOverloadDefinition]
//
//         static let empty = SemanticContext(
//             types: [:],
//             functions: [:],
//             functionsIdentifiers: [:],
//             functionsInputTypeIdentifiers: [:],
//             operators: [:]
//         )
//     }
//
//     enum SemanticAnalysisResult {
//         case context(SemanticContext)
//         case errors([SemanticError])
//
//         func get() throws -> SemanticContext {
//             switch self {
//             case let .context(context):
//                 return context
//             case let .errors(errors):
//                 throw errors
//             }
//         }
//     }
//
//     protocol SemanticAnalyzer: TypeDeclarationChecker, FunctionDeclarationChecker {
//         func semanticCheck() -> SemanticAnalysisResult
//     }
//
// }
//
// extension Typed.SemanticAnalyzer {
//     func semanticCheck() -> Typed.SemanticAnalysisResult {
//
//         let builtins = Builtins.getBuiltinContext()
//         let (typesDefinitions, typeErrors) = self.resolveTypeDefinitions(builtins: builtins)
//
//         let (
//             functions,
//             functionsIdentifiers,
//             functionsInputTypeIdentifiers,
//             operators,
//             functionErrors
//         ) = self.resolveFunctionDefinitions(
//             typesDefinitions: typesDefinitions,
//             builtins: builtins)
//
//         let semanticContext = SemanticContext(
//             types: typesDefinitions,
//             functions: functions,
//             functionsIdentifiers: functionsIdentifiers,
//             functionsInputTypeIdentifiers: functionsInputTypeIdentifiers,
//             operators: operators)
//
//         // NOTE: this might be handy when generating IR. function bodies that didn't change don't need regeneration
//         let checkedFunctions = functions.mapValues { definition -> Result<FunctionDefinition, ExpressionSemanticError> in
//             do throws(ExpressionSemanticError) {
//                 guard let bodyWithInferredType = try definition.body?.checkType(
//                     with: definition.inputType,
//                     localScope: LocalScope(
//                         fields: definition.params.reduce(into: [:]) { $0[$1.name] = $1.type }
//                     ),
//                     context: semanticContext
//                 ) else { return .failure(.emptyFunctionBody(functionDefinition: definition)) }
//                 // WARN: currently returning error for empty bodies,
//                 // should handle template methods for contracts or interfaces
//                 if bodyWithInferredType.typeIdentifier != definition.outputType {
//                     return .failure(.returnTypeMismatch(
//                         functionDefinition: definition,
//                         expectedReturnType: definition.outputType,
//                         receivedType: bodyWithInferredType.typeIdentifier))
//                 } else {
//                     return .success(.init(
//                         inputType: definition.inputType,
//                         functionIdentifier: definition.functionIdentifier,
//                         params: definition.params,
//                         outputType: definition.outputType,
//                         body: bodyWithInferredType,
//                         location: definition.location))
//                 }
//             } catch {
//                 return .failure(error)
//             }
//         }
//
//         let functionBodyErrors = checkedFunctions.compactMap { _, result in
//             if case let .failure(error) = result {
//                 return error
//             } else {
//                 return nil
//             }
//         }
//         let allErrors = typeErrors.map { SemanticError.type($0) } +
//                         functionErrors.map { SemanticError.function($0) } +
//                         functionBodyErrors.map { SemanticError.expression($0) }
//
//         if allErrors.count > 0 {
//             return .errors(allErrors)
//         }
//
//         let verifiedFunctions = checkedFunctions.mapValues { result -> FunctionDefinition in
//             return try! result.get()
//         }
//
//         // TODO: type checking for operators also
//         return .context(
//             SemanticContext(
//                 types: typesDefinitions,
//                 functions: verifiedFunctions,
//                 functionsIdentifiers: functionsIdentifiers,
//                 functionsInputTypeIdentifiers: functionsInputTypeIdentifiers,
//                 operators: operators))
//     }
// }
//
// extension Project: SemanticAnalyzer {
//     func getTypeDeclarations() -> [TypeDefinition] {
//         return self.modules.flatMap { source, module in
//             return module.getTypeDeclarations()
//         }
//     }
//
//     func getFunctionDeclarations() -> [FunctionDefinition] {
//         return self.modules.flatMap { source, module in
//             return module.getFunctionDeclarations()
//         }
//     }
//
//     func getOperatorOverloadDeclarations() -> [OperatorOverloadDefinition] {
//         return self.modules.flatMap { source, module in
//             return module.getOperatorOverloadDeclarations()
//         }
//     }
// }
//
// extension Module: SemanticAnalyzer {
//     func getTypeDeclarations() -> [TypeDefinition] {
//         return self.statements.compactMap { statement in
//             if case let .typeDefinition(typeDefinition) = statement {
//                 return typeDefinition
//             } else {
//                 return nil
//             }
//         }
//     }
//
//     func getFunctionDeclarations() -> [FunctionDefinition] {
//         return self.statements.compactMap { statement in
//             if case let .functionDefinition(functionDefinition) = statement {
//                 return functionDefinition
//             } else {
//                 return nil
//             }
//         }
//     }
//
//     func getOperatorOverloadDeclarations() -> [OperatorOverloadDefinition] {
//         return self.statements.compactMap { statement in
//             if case let .operatorOverloadDefinition(definition) = statement {
//                 return definition
//             } else {
//                 return nil
//             }
//         }
//     }
// }
//
