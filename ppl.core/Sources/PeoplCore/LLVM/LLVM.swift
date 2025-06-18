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

// extension TypeIdentifier: LLVM.TypeBuilder {
//     func llvmGetType(llvm: inout LLVM.Builder) throws(LLVM.Error) -> LLVMTypeRef {
//         switch self {
//         case .nothing:
//             return LLVMVoidTypeInContext(llvm.context)
//         case .never:
//             // Never is typically represented as void or a special token type
//             // WARN: not really sure about this
//             return LLVMVoidTypeInContext(llvm.context)
//         case let .nominal(nominal):
//             // Look up the struct type by name
//             let typeName = nominal.typeName
//
//             switch typeName {
//             // Signed integers
//             case "I8":
//                 return LLVMInt8TypeInContext(llvm.context)
//             case "I16":
//                 return LLVMInt16TypeInContext(llvm.context)
//             case "I32":
//                 return LLVMInt32TypeInContext(llvm.context)
//             case "I64":
//                 return LLVMInt64TypeInContext(llvm.context)
//                 
//             // Unsigned integers
//             case "U8":
//                 return LLVMInt8TypeInContext(llvm.context) // LLVM doesn't distinguish signed/unsigned at type level
//             case "U16":
//                 return LLVMInt16TypeInContext(llvm.context)
//             case "U32":
//                 return LLVMInt32TypeInContext(llvm.context)
//             case "U64":
//                 return LLVMInt64TypeInContext(llvm.context)
//                 
//             // Floating point
//             case "F32":
//                 return LLVMFloatTypeInContext(llvm.context)
//             case "F64":
//                 return LLVMDoubleTypeInContext(llvm.context)
//                 
//             // Other common types you might want
//             case "Bool":
//                 return LLVMInt1TypeInContext(llvm.context)
//             case "String":
//                 // Strings are pointers to i8 in LLVM
//                 return LLVMPointerType(LLVMInt8TypeInContext(llvm.context), 0)
//             
//             default:
//                 if let structType = LLVMGetTypeByName(llvm.module, typeName) {
//                     return structType
//                 }
//                 // If not found, create a placeholder struct
//                 let structType = LLVMStructCreateNamed(llvm.context, typeName)
//                 return structType! // WARN: don't know if I should force unwrap, or even create type here
//             }
//         default:
//             throw .notImplemented
//         }
//             
//         // case .lambda(let lambda):
//         //     // Function type
//         //     let inputTypes = lambda.input.map { $0.toLLVMType(llvm: &llvm) }
//         //     let outputTypes = lambda.output.map { $0.toLLVMType(llvm: &llvm) }
//         //     
//         //     // For multiple output values, create a struct
//         //     let returnType: LLVMTypeRef
//         //     if outputTypes.isEmpty {
//         //         returnType = LLVMVoidTypeInContext(llvm.context)
//         //     } else if outputTypes.count == 1 {
//         //         returnType = outputTypes[0]
//         //     } else {
//         //         returnType = LLVMStructTypeInContext(llvm.context, outputTypes, UInt32(outputTypes.count), 0)
//         //     }
//         //     
//         //     return LLVMPointerType(LLVMFunctionType(returnType, inputTypes, UInt32(inputTypes.count), 0), 0)
//         //     
//         // case .namedTuple(let namedTuple):
//         //     // Create a struct for named tuples
//         //     let fieldTypes = namedTuple.types.map { $0.type.toLLVMType(llvm: &llvm) }
//         //     return LLVMStructTypeInContext(llvm.context, fieldTypes, UInt32(fieldTypes.count), 0)
//         //     
//         // case .unnamedTuple(let unnamedTuple):
//         //     // Create a struct for unnamed tuples
//         //     let elementTypes = unnamedTuple.types.map { $0.toLLVMType(llvm: &llvm) }
//         //     return LLVMStructTypeInContext(llvm.context, elementTypes, UInt32(elementTypes.count), 0)
//         //     
//         // case .union(let unionType):
//         //     // For union types, find the largest type
//         //     let types = unionType.types.map { $0.toLLVMType(llvm: &llvm) }
//         //     var maxSize: UInt64 = 0
//         //     
//         //     for type in types {
//         //         let typeSize = LLVMABISizeOfType(LLVMModuleGetDataLayout(llvm.module), type)
//         //         maxSize = max(maxSize, typeSize)
//         //     }
//         //     
//         //     // Create a tagged union struct (tag + union data)
//         //     let tagType = LLVMInt32TypeInContext(llvm.context)
//         //     let dataType = LLVMArrayType(LLVMInt8TypeInContext(llvm.context), UInt32(maxSize))
//         //     
//         //     let unionElements = [tagType, dataType]
//         //     return LLVMStructTypeInContext(llvm.context, unionElements, 2, 0)
//         // }
//     }
// }
