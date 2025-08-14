import cllvm

extension Semantic.Tag {
    func llvmTag() -> LLVM.ParamTag {
        switch self {
        case .input:
            return .input
        case let .named(value):
            return .named(value)
        case let .unnamed(value):
            return .unnamed(value)
        }
    }
}
extension Semantic.FunctionSignature {
    var llvmName: String {
        // FIXME: this is stupid should think about main function
        if self.identifier.chain == ["main"] {
            "main"
        } else {
            self.display()
        }
    }

    func llvmFunction(
        body: borrowing Semantic.Expression,
        llvm: inout LLVM.Builder
    ) throws(LLVM.Error) -> LLVM.FunctionDefinition {
        var paramTypes: [LLVMTypeRef?] = []
        var paramNames: [LLVM.ParamTag: Int] = [:]

        let inputCount = self.inputType.type != .nothing ? 1 : 0

        if inputCount == 1 {
            paramTypes.append(try self.inputType.type.llvmGetType(llvm: &llvm))
            paramNames[self.inputType.tag.llvmTag()] = 0
        }

        for (index, argument) in self.arguments.enumerated() {
            // input alwas first param
            paramNames[argument.key.llvmTag()] = index + inputCount
            paramTypes.append(try argument.value.llvmGetType(llvm: &llvm))
        }

        let outputType = try body.type.llvmGetType(llvm: &llvm)

        let functionType = paramTypes.withUnsafeMutableBufferPointer { buffer in
            LLVMFunctionType(
                outputType, buffer.baseAddress, UInt32(buffer.count), 0)
        }

        let functionValue = LLVMAddFunction(
            llvm.module,
            llvmName,
            functionType)

        return .init(
            name: self.llvmName,
            paramTypes: paramTypes,
            paramNames: paramNames,
            outputType: outputType,
            functionType: functionType!,
            functionValue: functionValue!)
    }
}
extension Semantic.DefinitionsContext {
    static func llvmBuildFunctionDeclaration(
        signature: Semantic.FunctionSignature,
        body: borrowing Semantic.Expression,
        llvm: inout LLVM.Builder
    ) throws(LLVM.Error) -> LLVM.FunctionDefinition {
        let functionName = signature.llvmName

        var arguments = signature.arguments
        if signature.inputType.type != .nothing {
            arguments[signature.inputType.tag] =  signature.inputType.type
        }

        var (paramTypes, paramNames) =
            try arguments.llvmBuildParams(llvm: &llvm)

        let outputType = try body.type.llvmGetType(llvm: &llvm)

        let functionType = paramTypes.withUnsafeMutableBufferPointer { buffer in
            LLVMFunctionType(
                outputType, buffer.baseAddress, UInt32(buffer.count), 0)
        }

        let functionValue = LLVMAddFunction(
            llvm.module,
            functionName,
            functionType)
        return .init(
            name: functionName,
            paramTypes: paramTypes,
            paramNames: paramNames,
            outputType: outputType,
            functionType: functionType!,
            functionValue: functionValue!)
    }

    func llvmBuildFunctions(
        llvm: inout LLVM.Builder
    ) throws(LLVM.Error) {
        for (signature, expression) in self.functionDefinitions {
            llvm.functions[signature.llvmName] =
                try Self.llvmBuildFunctionDeclaration(
                    signature: signature,
                    body: expression,
                    llvm: &llvm)
        }
        for (signature, expression) in self.functionDefinitions {
            let function = llvm.functions[signature.llvmName]!
            let entryBlock = LLVMAppendBasicBlockInContext(
                llvm.context, function.functionValue, "entry")

            LLVMPositionBuilderAtEnd(llvm.builder, entryBlock)

            var paramValues: [LLVM.ParamTag: LLVMValueRef?] = [:]

            for (tag, index) in function.paramNames {
                let paramValue = LLVMGetParam(function.functionValue, UInt32(index))
                paramValues[tag] = paramValue
                let paramName = "p_\(index)"
                LLVMSetValueName2(paramValue, paramName, paramName.utf8.count)
            }

            let returnValue = try expression.llvmBuildValue(
                llvm: &llvm, scope: paramValues)
            LLVMBuildRet(llvm.builder, returnValue)
        }
    }
}
