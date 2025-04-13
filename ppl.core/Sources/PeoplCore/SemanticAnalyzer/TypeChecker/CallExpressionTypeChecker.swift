// extension Expression.Call: ExpressionTypeChecker {
//
//     enum Callable {
//         case function(identifier: FunctionIdentifier, input: TypeIdentifier)
//         case type(name: NominalType)
//     }
//
//     func checkType(
//         with input: TypeIdentifier,
//         localScope: LocalScope,
//         context: borrowing SemanticContext
//     ) throws(ExpressionSemanticError) -> TypedExpression {
//
//         let callable: Callable
//         switch self.command {
//         case let .simple(expression):
//             switch expression.expressionType {
//             case let .field(functionName):
//                 callable = .function(
//                     identifier: FunctionIdentifier(scope: nil, name: functionName),
//                     input: input)
//             case let .access(access):
//                 switch access.accessed {
//                 case let .type(type):
//                     callable = .function(
//                         identifier: FunctionIdentifier(scope: type, name: access.field),
//                         input: input)
//                 case let .simple(accessedExpression):
//                     // NOTE: this is calling a lambda of an object
//                     throw .unsupportedYet("calling attributes of objects")
//                 }
//             case let .lambda(lambda):
//                 throw .unsupportedYet("Direct lambda calls")
//             default:
//                 throw .callingUncallable(
//                     expression: expression,
//                     type: try expression.checkType(
//                         with: input, localScope: localScope, context: context).type
//                 )
//             }
//         case let .type(type):
//             callable = .type(name: type)
//         }
//         
//         let typedArguments = try self.arguments.map { argument throws(ExpressionSemanticError) in
//             (name: argument.name, 
//             value: try argument.value.checkType(
//                     with: .nothing,
//                     localScope: localScope,
//                     context: context))
//         }
//         let paramDefinitions = try typedArguments.map { name, value throws(ExpressionSemanticError) in
//             ParamDefinition(
//                 name: name,
//                 type: value.type,
//                 location: .nowhere)
//         }
//
//         return switch callable {
//         case let .function(functionIdentifier, callee):
//             try self.typeCheckFunctionCall(
//                 functionIdentifier: functionIdentifier,
//                 callee: callee,
//                 paramDefinitions: paramDefinitions,
//                 typedArguments: typedArguments,
//                 localScope: localScope,
//                 context: context)
//         case let .type(nominalType):
//             try self.typeCheckTypeInitializer(
//                 nominalType: nominalType,
//                 paramDefinitions: paramDefinitions,
//                 typedArguments: typedArguments,
//                 localScope: localScope,
//                 context: context)
//         }
//     }
//
//     private func typeCheckFunctionCall(
//         functionIdentifier: FunctionIdentifier,
//         callee: TypeIdentifier,
//         paramDefinitions: [ParamDefinition],
//         typedArguments: [(name: String, value: TypedExpression)],
//         localScope: LocalScope,
//         context: borrowing SemanticContext
//     ) throws(ExpressionSemanticError) -> TypedExpression {
//
//         if functionIdentifier.scope == nil, 
//             let localFunction = localScope.fields[functionIdentifier.name],
//             case let .lambda(lambda) = localFunction
//         { // might be calling a local lambda
//             // TODO: implement lambda call type checking
//             throw .unsupportedYet("Calling a lambda")
//         }
//
//         let functionDefinition = FunctionDefinition(
//             inputType: callee,
//             functionIdentifier: functionIdentifier,
//             params: paramDefinitions,
//             outputType: .nothing,
//             body: .empty,
//             location: .nowhere)
//
//         if let function = context.functions[functionDefinition] {
//             return .call(.function(function, arguments: typedArguments), type: function.outputType)
//         }
//
//         // Handling different errors
//
//         guard let functionsWithSameIdentifier = context.functionsIdentifiers[functionIdentifier],
//             functionsWithSameIdentifier.count > 0 else 
//         {
//             throw .undefinedFunction(call: self, function: functionIdentifier)
//         }
//
//         if let inputTypeFunctions = context.functionsInputTypeIdentifiers[callee] {
//             let validFunctionsForInput = inputTypeFunctions.filter { 
//                 $0.functionIdentifier == functionDefinition.functionIdentifier
//             }
//
//             if validFunctionsForInput.count == 0 {
//                 throw .undefinedFunctionOnInput(
//                     call: self,
//                     input: callee,
//                     function: functionDefinition.functionIdentifier
//                 )
//             }
//             throw .argumentMismatch(
//                 call: self,
//                 givenArguments: paramDefinitions,
//                 inputType: callee,
//                 function: functionIdentifier)
//         } else {
//             throw .undefinedFunctionOnInput(
//                 call: self,
//                 input: callee,
//                 function: functionIdentifier)
//
//         }
//     }
//
//     private func typeCheckTypeInitializer(
//         nominalType: NominalType,
//         paramDefinitions: [ParamDefinition],
//         typedArguments: [TypedArgument],
//         localScope: LocalScope,
//         context: SemanticContext
//     ) throws(ExpressionSemanticError) -> TypedExpression {
//
//         guard let typeDefinition = context.types[nominalType] else {
//             throw .undefinedTypeInitializer(nominalType: nominalType)
//         }
//
//         guard paramDefinitions == typeDefinition.allParams else {
//             throw .typeInitializeArgumentMismatch(
//                 call: self,
//                 givenArguments: paramDefinitions,
//                 typeDefinition: typeDefinition)
//         }
//         return .call(
//             .typeInitialization(typeDefinition, arguments: typedArguments),
//             type: .nominal(nominalType))
//     }
// }
