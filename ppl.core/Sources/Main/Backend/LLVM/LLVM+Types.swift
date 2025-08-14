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
        case let .nominal(identifier):
            // force unwrapping here, because we should have
            return llvm.types[identifier.llvmName]!.structType

        default:
            // if let structType = LLVMGetTypeByName(llvm.module, typeName) {
            //     return structType
            throw .notImplemented("other types are not implemented yet")
        }
    }

    func llvmGetTypeDefinition(
        llvm: inout LLVM.Builder
    ) throws(LLVM.Error) -> LLVM.TypeDefinition {
        switch self {
        case let .nominal(identifier):
            return llvm.types[identifier.llvmName]!
        default:
            throw LLVM.Error.notImplemented("Only nominal types can be converted to struct types")
        }
    }
}

extension [Semantic.Tag: Semantic.TypeSpecifier] {
    func llvmBuildParams(
        llvm: inout LLVM.Builder
    ) throws(LLVM.Error) -> (
        [LLVMTypeRef?],
        [LLVM.ParamTag: Int]
    ) {
        var paramTypes: [LLVMTypeRef?] = []
        var paramNames: [LLVM.ParamTag: Int] = [:]

        for (index, argument) in self.enumerated() {
            paramNames[argument.key.llvmTag()] = index
            paramTypes.append(try argument.value.llvmGetType(llvm: &llvm))
        }

        return (paramTypes, paramNames)
    }
}

extension Semantic.QualifiedIdentifier {
    var llvmName: String {
        chain.joined(separator: "\\")
    }
}

extension Semantic.DefinitionsContext {

    static func llvmBuildType(
        identifier: Semantic.QualifiedIdentifier,
        typeSpecifier: Semantic.RawTypeSpecifier,
        llvm: inout LLVM.Builder
    ) throws(LLVM.Error) -> LLVM.TypeDefinition {
        let typeName = identifier.llvmName
        switch typeSpecifier {
        case let .record(fields):
            let structType = LLVMStructCreateNamed(llvm.context, typeName)
            var (paramTypes, paramNames) =
                try fields.llvmBuildParams(llvm: &llvm)
            // LLVMStructType(UnsafeMutablePointer<LLVMTypeRef?>!, UInt32, LLVMBool)
            paramTypes.withUnsafeMutableBufferPointer { buffer in
                LLVMStructSetBody(
                    structType, buffer.baseAddress, UInt32(buffer.count), 0)
            }

            return .init(
                name: typeName,
                paramTypes: paramTypes,
                paramNames: paramNames,
                structType: structType!)
        default:
            fatalError("not implemented yet")
        }
    }

    func llvmBuildTypes(
        llvm: inout LLVM.Builder
    ) throws(LLVM.Error) {
        for (identifier, typeSpecifier) in self.typeDefinitions {
            if case let .raw(rawType) = typeSpecifier {
                llvm.types[identifier.llvmName] =
                    try Self.llvmBuildType(
                        identifier: identifier,
                        typeSpecifier: rawType,
                        llvm: &llvm)
            }
        }
    }
}
