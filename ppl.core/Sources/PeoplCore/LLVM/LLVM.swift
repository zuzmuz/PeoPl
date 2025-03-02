import cllvm
import Foundation

enum LLVM {}

extension LLVM {
    struct Builder: ~Copyable {
        let module: LLVMModuleRef
        let context: LLVMContextRef
        let builder: LLVMBuilderRef

        init(name: String) {
            context = LLVMContextCreate()
            // initializing llvm
            LLVMInitializeAllTargets()
            LLVMInitializeAllTargetInfos()
            LLVMInitializeAllAsmPrinters()
            LLVMInitializeAllAsmParsers()
            LLVMInitializeAllTargetMCs()
            LLVMInitializeAllDisassemblers()

            module = LLVMModuleCreateWithNameInContext(name, context)
            builder = LLVMCreateBuilderInContext(context)

        }

        deinit {
            LLVMDisposeBuilder(builder)
            LLVMDisposeModule(module)
            LLVMContextDispose(context)
        }
    }

    protocol StatementBuilder {
        func llvmBuildStatement(llvm: inout Builder) throws(LLVM.Error)
    }

    protocol TypeBuilder {
        // func llvmBuildType(llvm: inout Builder) -> LLVMTypeRef
        func llvmGetType(llvm: inout Builder) throws(LLVM.Error) -> LLVMTypeRef
    }

    protocol ValueBuilder {
        func llvmBuildValue(llvm: inout Builder) throws(LLVM.Error) -> LLVMValueRef
    }

    enum Error: LocalizedError {
        case unsupportedExpression(Expression)
        case notImplemented
    }
    // -lc++ -stdlib=libc++  -L/opt/homebrew/Cellar/llvm/19.1.7/lib -Wl,-search_paths_first -Wl,-headerpad_max_install_names
}
extension Module: LLVM.StatementBuilder {
    func llvmBuildStatement(llvm: inout LLVM.Builder) throws(LLVM.Error) {
        for statement in self.statements {
            try statement.llvmBuildStatement(llvm: &llvm)
        }
    }
}

extension Statement: LLVM.StatementBuilder {
    func llvmBuildStatement(llvm: inout LLVM.Builder) throws(LLVM.Error) {
        switch self {
        case .functionDefinition(let definition):
            try definition.llvmBuildStatement(llvm: &llvm)
        case .typeDefinition(let definition):
            try definition.llvmBuildStatement(llvm: &llvm)
        case .operatorOverloadDefinition(let definition):
            try definition.llvmBuildStatement(llvm: &llvm)
        }
    }
}

extension OperatorOverloadDefinition: LLVM.StatementBuilder {
    func llvmBuildStatement(llvm: inout LLVM.Builder) throws(LLVM.Error) {

    }
}

extension FunctionDefinition: LLVM.StatementBuilder {
    func llvmBuildStatement(llvm: inout LLVM.Builder) throws(LLVM.Error) {
        // TODO: well consider scope (maybe generate string from identifier

        let functionName = self.functionIdentifier.fullName
        var paramTypes = 
            ([try self.inputType.llvmGetType(llvm: &llvm)] +
            (try self.params.map { param throws(LLVM.Error) in
                try param.type.llvmGetType(llvm: &llvm) 
            })).map { $0 as Optional }
        // NOTE: should consider variadics (yeah there's those)
        let outputType = try self.outputType.llvmGetType(llvm: &llvm)
        let functionType = paramTypes.withUnsafeMutableBufferPointer { buffer in
            return LLVMFunctionType(outputType, buffer.baseAddress, UInt32(buffer.count), 0)
        }

        let function = LLVMAddFunction(llvm.builder, functionName, functionType)

        if let body {
            let entryBlock = LLVMAppendBasicBlockInContext(llvm.context, function, "entry")
            LLVMPositionBuilderAtEnd(llvm.builder, entryBlock)

            for (index, param) in params.enumerated() {
                let paramValue = LLVMGetParam(function, UInt32(index))
                LLVMSetValueName2(paramValue, param.name, param.name.utf8.count)
            }
            let returnValue = try body.llvmBuildValue(llvm: &llvm) //, function: function)
            LLVMBuildRet(llvm.builder, returnValue)
        }
    }
}

extension TypeDefinition: LLVM.StatementBuilder {
    func llvmBuildStatement(llvm: inout LLVM.Builder) throws(LLVM.Error) {

    }
}

extension TypeIdentifier: LLVM.TypeBuilder {
    func llvmGetType(llvm: inout LLVM.Builder) throws(LLVM.Error) -> LLVMTypeRef {
        switch self {
        case .unkown:
            // Default to a generic pointer type
            // FIX: should throw error here (should not get to this point
            return LLVMPointerType(LLVMInt8TypeInContext(llvm.context), 0)
            
        case .nothing:
            return LLVMVoidTypeInContext(llvm.context)
        case .never:
            // Never is typically represented as void or a special token type
            // WARN: not really sure about this
            return LLVMVoidTypeInContext(llvm.context)
        case let .nominal(nominal):
            // Look up the struct type by name
            let typeName = nominal.typeName
            if let structType = LLVMGetTypeByName(llvm.module, typeName) {
                return structType
            }
            // If not found, create a placeholder struct
            let structType = LLVMStructCreateNamed(llvm.context, typeName)
            return structType! // WARN: don't know if I should force unwrap
        default:
            throw .notImplemented
        }
            
        // case .lambda(let lambda):
        //     // Function type
        //     let inputTypes = lambda.input.map { $0.toLLVMType(llvm: &llvm) }
        //     let outputTypes = lambda.output.map { $0.toLLVMType(llvm: &llvm) }
        //     
        //     // For multiple output values, create a struct
        //     let returnType: LLVMTypeRef
        //     if outputTypes.isEmpty {
        //         returnType = LLVMVoidTypeInContext(llvm.context)
        //     } else if outputTypes.count == 1 {
        //         returnType = outputTypes[0]
        //     } else {
        //         returnType = LLVMStructTypeInContext(llvm.context, outputTypes, UInt32(outputTypes.count), 0)
        //     }
        //     
        //     return LLVMPointerType(LLVMFunctionType(returnType, inputTypes, UInt32(inputTypes.count), 0), 0)
        //     
        // case .namedTuple(let namedTuple):
        //     // Create a struct for named tuples
        //     let fieldTypes = namedTuple.types.map { $0.type.toLLVMType(llvm: &llvm) }
        //     return LLVMStructTypeInContext(llvm.context, fieldTypes, UInt32(fieldTypes.count), 0)
        //     
        // case .unnamedTuple(let unnamedTuple):
        //     // Create a struct for unnamed tuples
        //     let elementTypes = unnamedTuple.types.map { $0.toLLVMType(llvm: &llvm) }
        //     return LLVMStructTypeInContext(llvm.context, elementTypes, UInt32(elementTypes.count), 0)
        //     
        // case .union(let unionType):
        //     // For union types, find the largest type
        //     let types = unionType.types.map { $0.toLLVMType(llvm: &llvm) }
        //     var maxSize: UInt64 = 0
        //     
        //     for type in types {
        //         let typeSize = LLVMABISizeOfType(LLVMModuleGetDataLayout(llvm.module), type)
        //         maxSize = max(maxSize, typeSize)
        //     }
        //     
        //     // Create a tagged union struct (tag + union data)
        //     let tagType = LLVMInt32TypeInContext(llvm.context)
        //     let dataType = LLVMArrayType(LLVMInt8TypeInContext(llvm.context), UInt32(maxSize))
        //     
        //     let unionElements = [tagType, dataType]
        //     return LLVMStructTypeInContext(llvm.context, unionElements, 2, 0)
        // }
    }
}

extension Expression: LLVM.ValueBuilder {
    func llvmBuildValue(llvm: inout LLVM.Builder) throws(LLVM.Error) -> LLVMValueRef {
        // TODO: generate typeref for builtins to use in literals,
        // also consider using the generic undefined literals (getting type from expression rather assuming the literal)
        switch expressionType {
        case .nothing:
            return LLVMConstNull(LLVMVoidTypeInContext(llvm.context))
        case .never:
            return LLVMBuildUnreachable(llvm.builder)
        case let .intLiteral(value):
            return LLVMConstInt(
                LLVMInt64TypeInContext(llvm.context),
                UInt64(value < 0 ? -value : value),
                value < 0 ? 1 : 0)
        case let .floatLiteral(value):
            return LLVMConstReal(
                LLVMDoubleTypeInContext(llvm.context),
                Double(value))
        case let .stringLiteral(value):
            // WARN: not sure about this one
            return LLVMBuildGlobalStringPtr(llvm.builder, value, "str")
        case let .boolLiteral(value):
            return LLVMConstInt(
                LLVMInt1TypeInContext(llvm.context),
                value ? 1 : 0,
                0)
        // case let .binary(op, left, right):
        //     let leftBuildValue = try left.llvmBuildValue(llvm: &llvm)
        //     let rightBuildValue = try right.llvmBuildValue(llvm: &llvm)
        //
        //     let method = switch op

        default:
            throw .unsupportedExpression(self)
        }
    }
}
