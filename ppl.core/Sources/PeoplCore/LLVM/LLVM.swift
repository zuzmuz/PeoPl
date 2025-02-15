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
        func llvmBuildStatement(llvm: inout Builder)
    }

    protocol TypeBuilder {
        func llvmBuildType(llvm: inout Builder) -> LLVMTypeRef
        func llvmGetType(llvm: inout Builder) -> LLVMTypeRef
    }

    protocol ValueBuilder {
        func llvmBuildValue(llvm: inout Builder) throws(EmitError) -> LLVMValueRef
    }

    enum EmitError: LocalizedError {
        case unsupportedExpression(Expression)
    }
    // -lc++ -stdlib=libc++  -L/opt/homebrew/Cellar/llvm/19.1.7/lib -Wl,-search_paths_first -Wl,-headerpad_max_install_names
}
extension Module: LLVM.StatementBuilder {
    func llvmBuildStatement(llvm: inout LLVM.Builder) {
        self.statements.forEach { statement in
            statement.llvmBuildStatement(llvm: &llvm)
        }
    }
}

extension Statement: LLVM.StatementBuilder {
    func llvmBuildStatement(llvm: inout LLVM.Builder) {
        switch self {
        case .functionDefinition(let definition):
            definition.llvmBuildStatement(llvm: &llvm)
        case .typeDefinition(let definition):
            definition.llvmBuildStatement(llvm: &llvm)
        }
    }
}

extension FunctionDefinition: LLVM.StatementBuilder {
    func llvmBuildStatement(llvm: inout LLVM.Builder) {
        if self.functionIdentifier.name == "main" {

        }
    }
}

extension TypeDefinition: LLVM.StatementBuilder {
    func llvmBuildStatement(llvm: inout LLVM.Builder) {

    }
}

extension TypeIdentifier: LLVM.TypeBuilder {
    func llvmBuildType(llvm: inout LLVM.Builder) -> LLVMTypeRef {
        // switch self {
        // case .nothing:
        //     return LLVMVoidTypeInContext(llvm.context)
        // case .nominal(nominal):
        //     return 
        // }
        return LLVMVoidTypeInContext(llvm.context)
    }

    func llvmGetType(llvm: inout LLVM.Builder) -> LLVMTypeRef {
        return LLVMVoidTypeInContext(llvm.context)
    }
}

extension Expression: LLVM.ValueBuilder {
    func llvmBuildValue(llvm: inout LLVM.Builder) throws(LLVM.EmitError) -> LLVMValueRef {
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
        case let .plus(left: leftExpression, right: rightExpression):
            let left = try leftExpression.llvmBuildValue(llvm: &llvm)
            let right = try rightExpression.llvmBuildValue(llvm: &llvm)
            return LLVMBuildAdd(llvm.builder, left, right, "")
        default:
            throw .unsupportedExpression(self)
        }
    }
}
