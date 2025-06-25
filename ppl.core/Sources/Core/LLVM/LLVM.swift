import cllvm
import Foundation

public enum LLVM {}

extension LLVM {
    public struct Builder: ~Copyable {
        let module: LLVMModuleRef
        let context: LLVMContextRef
        let builder: LLVMBuilderRef

        var functions: [String: Function]

        public init(name: String) {
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

            functions = [:]

        }

        public func generate() -> String {
            return String(cString: LLVMPrintModuleToString(module))
        }

        func save(to path: String) {
            LLVMPrintModuleToFile(module, path, nil)
        }

        func verify() -> Bool {
            return  LLVMVerifyFunction(module, LLVMReturnStatusAction) != 0
        }

        deinit {
            LLVMDisposeBuilder(builder)
            LLVMDisposeModule(module)
            LLVMContextDispose(context)
        }
    }

    public protocol StatementBuilder {
        func llvmBuildStatement(llvm: inout Builder) throws(LLVM.Error)
    }

    protocol TypeBuilder {
        // func llvmBuildType(llvm: inout Builder) -> LLVMTypeRef
        func llvmGetType(llvm: inout Builder) throws(LLVM.Error) -> LLVMTypeRef
    }

    protocol ValueBuilder {
        func llvmBuildValue(
            llvm: inout Builder,
            // function: LLVM.Function,
            scope: borrowing [LLVM.ParamTag: LLVMValueRef?]
        ) throws(LLVM.Error) -> LLVMValueRef?
    }

    public enum Error: LocalizedError {
        case notImplemented
        case unreachable
    }

    struct Function {
        let name: String
        let paramTypes: [LLVMTypeRef?]
        let paramNames: [LLVM.ParamTag: Int]
        let outputType: LLVMTypeRef
        let functionType: LLVMTypeRef
        let functionValue: LLVMValueRef
        // Mayby Body Expression
    }

    enum ParamTag: Hashable {
        case named(String)
        case unnamed(UInt64)
        case input

        var value: String {
            switch self {
            case .input:
                "_in_" // FIXME: should be unique
            case let .named(value):
                value
            case let .unnamed(value):
                "_\(value)"
            }
        }
    }
}

    // -lc++ -stdlib=libc++  -L/opt/homebrew/Cellar/llvm/19.1.7/lib -Wl,-search_paths_first -Wl,-headerpad_max_install_names

