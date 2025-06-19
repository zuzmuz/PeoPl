import cllvm
import Foundation

enum LLVM {}

extension LLVM {
    struct Builder: ~Copyable {
        let module: LLVMModuleRef
        let context: LLVMContextRef
        let builder: LLVMBuilderRef

        var functionTypes: [String: LLVMTypeRef]

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

        func generate() -> String {
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

    protocol StatementBuilder {
        func llvmBuildStatement(llvm: inout Builder) throws(LLVM.Error)
    }

    protocol TypeBuilder {
        // func llvmBuildType(llvm: inout Builder) -> LLVMTypeRef
        func llvmGetType(llvm: inout Builder) throws(LLVM.Error) -> LLVMTypeRef
    }

    protocol ValueBuilder {
        func llvmBuildValue(
            llvm: inout Builder,
            scope: borrowing [String: LLVMValueRef]
        ) throws(LLVM.Error) -> LLVMValueRef
    }

    enum Error: LocalizedError {
        case notImplemented
    }
}

    // -lc++ -stdlib=libc++  -L/opt/homebrew/Cellar/llvm/19.1.7/lib -Wl,-search_paths_first -Wl,-headerpad_max_install_names

