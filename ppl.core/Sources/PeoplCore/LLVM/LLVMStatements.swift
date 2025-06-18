import cllvm

//
// extension Module: LLVM.StatementBuilder {
//     func llvmBuildStatement(llvm: inout LLVM.Builder) throws(LLVM.Error) {
//         for statement in self.statements {
//             try statement.llvmBuildStatement(llvm: &llvm)
//         }
//     }
// }
//
// extension SemanticContext: LLVM.StatementBuilder {
//     func llvmBuildStatement(llvm: inout LLVM.Builder) throws(LLVM.Error) {
//         for type in self.types.values {
//             try type.llvmBuildStatement(llvm: &llvm)
//         }
//         for function in self.functions.values {
//             try function.llvmBuildStatement(llvm: &llvm)
//         }
//         for op in self.operators.values {
//             try op.llvmBuildStatement(llvm: &llvm)
//         }
//     }
//
// }
//
// extension Statement: LLVM.StatementBuilder {
//     func llvmBuildStatement(llvm: inout LLVM.Builder) throws(LLVM.Error) {
//         switch self {
//         case .functionDefinition(let definition):
//             try definition.llvmBuildStatement(llvm: &llvm)
//         case .typeDefinition(let definition):
//             try definition.llvmBuildStatement(llvm: &llvm)
//         case .operatorOverloadDefinition(let definition):
//             try definition.llvmBuildStatement(llvm: &llvm)
//         }
//     }
// }
//
// extension OperatorOverloadDefinition: LLVM.StatementBuilder {
//     func llvmBuildStatement(llvm: inout LLVM.Builder) throws(LLVM.Error) {
//
//     }
// }
//
// extension TypeDefinition: LLVM.StatementBuilder {
//     func llvmBuildStatement(llvm: inout LLVM.Builder) throws(LLVM.Error) {
//         switch self {
//         case let .simple(simple):
//             let typeName = simple.identifier.typeName
//             var paramTypes = try simple.params.map { param throws(LLVM.Error) in
//                 try param.type.llvmGetType(llvm: &llvm) as Optional
//             }
//             let structType = LLVMStructCreateNamed(llvm.context, typeName)
//
//             // LLVMStructSetBody(structType, &paramTypes, UInt32(paramTypes.count), 0)
//
//             paramTypes.withUnsafeMutableBufferPointer { buffer in
//                 LLVMStructSetBody(structType, buffer.baseAddress, UInt32(buffer.count), 0)
//             }
//
//         case let .sum(sum):
//             throw .notImplemented
//             // Claude shit
//             // // For sum types (enums/unions), we need to create a tagged union
//             // // This typically involves a struct with a tag field and a union field
//             // let name = sum.identifier.chain.map { $0.typeName }.joined(separator: ".")
//             //
//             // // First, create a discriminator (tag) type - typically i32
//             // let tagType = LLVMInt32TypeInContext(llvm.context)
//             //
//             // // Find the largest case to determine union size
//             // var maxCaseSize: UInt64 = 0
//             // var caseTypes: [LLVMTypeRef] = []
//             //
//             // for caseType in sum.cases {
//             //     let caseParamTypes = caseType.params.map { $0.type.toLLVMType(llvm: &llvm) }
//             //     let caseStructType = LLVMStructTypeInContext(llvm.context, caseParamTypes, UInt32(caseParamTypes.count), 0)
//             //     caseTypes.append(caseStructType)
//             //
//             //     // Calculate size of this case
//             //     let typeSize = LLVMABISizeOfType(LLVMModuleGetDataLayout(llvm.module), caseStructType)
//             //     maxCaseSize = max(maxCaseSize, typeSize)
//             // }
//             //
//             // // Create a union type using an array of i8 with the size of the largest case
//             // let unionType = LLVMArrayType(LLVMInt8TypeInContext(llvm.context), UInt32(maxCaseSize))
//             //
//             // // Create the final tagged union struct (tag + union data)
//             // let sumTypeElements = [tagType, unionType]
//             // let sumType = LLVMStructCreateNamed(llvm.context, name)
//             // LLVMStructSetBody(sumType, sumTypeElements, 2, 0)
//         }
//     }
// }
//
// extension FunctionDefinition: LLVM.StatementBuilder {
//     func llvmBuildStatement(llvm: inout LLVM.Builder) throws(LLVM.Error) {
//         // TODO: well consider scope (maybe generate string from identifier
//
//         // let functionName = self.functionIdentifier.fullName
//         // var paramTypes: [LLVMTypeRef?] = []
//         // if self.inputType != .nothing() {
//         //     paramTypes.append(try self.inputType.llvmGetType(llvm: &llvm))
//         // }
//         // for param in self.params {
//         //     paramTypes.append(try param.type.llvmGetType(llvm: &llvm))
//         // }
//         // // NOTE: should consider variadics (yeah there's those)
//         // let outputType = try self.outputType.llvmGetType(llvm: &llvm)
//         // // let functionType = LLVMFunctionType(outputType, &paramTypes, UInt32(paramTypes.count), 0)
//         // let functionType = paramTypes.withUnsafeMutableBufferPointer { buffer in
//         //     return LLVMFunctionType(outputType, buffer.baseAddress, UInt32(buffer.count), 0)
//         // }
//         //
//         // let function = LLVMAddFunction(llvm.module, functionName, functionType)
//         //
//         // if let body {
//         //     let entryBlock = LLVMAppendBasicBlockInContext(llvm.context, function, "entry")
//         //     LLVMPositionBuilderAtEnd(llvm.builder, entryBlock)
//         //     var paramValues: [String: LLVMValueRef] = [:]
//         //     for (index, param) in params.enumerated() {
//         //         let paramValue = LLVMGetParam(function, UInt32(index))
//         //         LLVMSetValueName2(paramValue, param.name, param.name.utf8.count)
//         //         paramValues[param.name] = paramValue
//         //     }
//         //     let returnValue = try body.llvmBuildValue(llvm: &llvm, scope: paramValues) //, function: function)
//         //
//         //     LLVMBuildRet(llvm.builder, returnValue)
//         // }
//     }
// }
//

extension Semantic.Context: LLVM.StatementBuilder {
    func llvmBuildFunction(
        llvm: inout LLVM.Builder,
        signature: Semantic.FunctionSignature,
        body: Semantic.Expression
    ) throws(LLVM.Error) {

        let functionName = signature.identifier.chain.joined(
            separator: "_")
        var paramTypes: [LLVMTypeRef?] = []

        if signature.inputType != .nothing {
            paramTypes.append(
                try signature.inputType.llvmGetType(llvm: &llvm))
        }

        for argument in signature.arguments {
            paramTypes.append(try argument.value.llvmGetType(llvm: &llvm))
        }

        let outputType = try body.type.llvmGetType(llvm: &llvm)

        let functionType = paramTypes.withUnsafeMutableBufferPointer { buffer in
            LLVMFunctionType(
                outputType, buffer.baseAddress, UInt32(buffer.count), 0)
        }

        let function = LLVMAddFunction(llvm.module, functionName, functionType)
    }

    func llvmBuildStatement(llvm: inout LLVM.Builder) throws(LLVM.Error) {
        for (signature, expression) in self.definitions.valueDefinitions {
            switch signature {
            case let .function(function):
                try self.llvmBuildFunction(
                    llvm: &llvm,
                    signature: function,
                    body: expression)

            case .value:
                fatalError("code gen for value not supported")
            }
        }
    }
}
