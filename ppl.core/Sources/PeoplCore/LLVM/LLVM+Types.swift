import cllvm

extension Semantic.TypeSpecifier: LLVM.TypeBuilder {
    func llvmGetType(
        llvm: inout LLVM.Builder
    ) throws(LLVM.Error) -> LLVMTypeRef {
        switch self {
        case .nothing:
            return LLVMVoidTypeInContext(llvm.context)
        case .never:
            // Never is typically represented as void or a special token type
            // WARN: not really sure about this
            return LLVMVoidTypeInContext(llvm.context)
        case .uint:
            return LLVMInt32TypeInContext(llvm.context)
        case .int:
            return LLVMInt32TypeInContext(llvm.context)
        case .float:
            return LLVMDoubleTypeInContext(llvm.context)
        case .bool:
            return LLVMInt1TypeInContext(llvm.context)

        default:
            // if let structType = LLVMGetTypeByName(llvm.module, typeName) {
            //     return structType
            fatalError("Not implemented for type: \(self)")
        }
    }
}
