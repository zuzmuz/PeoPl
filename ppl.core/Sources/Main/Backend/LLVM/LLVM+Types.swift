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
            throw .notImplemented("other types are not implemented yet")
        }
    }
}

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
