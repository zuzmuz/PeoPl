import cllvm

extension Semantic.Expression: LLVM.ValueBuilder {
    func llvmBuildValue(
        llvm: inout LLVM.Builder,
        scope: borrowing [LLVM.ParamTag: LLVMValueRef?]
    ) throws(LLVM.Error) -> LLVMValueRef {
        // TODO: generate typeref for builtins to use in literals,
        // also consider using the generic undefined literals (getting type from expression rather assuming the literal)
        switch self.expressionType {
        case .input:
            // TODO: build value based on input type and get it from scope
            return LLVMConstNull(LLVMVoidTypeInContext(llvm.context))
        case .nothing:
            return LLVMConstNull(LLVMVoidTypeInContext(llvm.context))
        case .never:
            return LLVMBuildUnreachable(llvm.builder)
        case let .intLiteral(value):
            return LLVMConstInt(
                try self.type.llvmGetType(llvm: &llvm), value, 0)
        case let .floatLiteral(value):
            return LLVMConstReal(
                try self.type.llvmGetType(llvm: &llvm),
                Double(value))
        case let .stringLiteral(value):
            // WARN: not sure about this one
            return LLVMBuildGlobalStringPtr(llvm.builder, value, "str")
        case let .boolLiteral(value):
            return LLVMConstInt(
                LLVMInt1TypeInContext(llvm.context),
                value ? 1 : 0,
                0)
        case let .binary(op, left, right):
            let lhs = try left.llvmBuildValue(llvm: &llvm, scope: scope)
            let rhs = try right.llvmBuildValue(llvm: &llvm, scope: scope)

            switch op {
            case .plus:
                // Check if we're dealing with integers or floating point
                let llvmType = try left.type.llvmGetType(llvm: &llvm)
                if LLVMGetTypeKind(llvmType) == LLVMFloatTypeKind
                    || LLVMGetTypeKind(llvmType) == LLVMDoubleTypeKind
                {
                    return LLVMBuildFAdd(llvm.builder, lhs, rhs, "fadd")
                } else {
                    return LLVMBuildAdd(llvm.builder, lhs, rhs, "add")
                }

            case .minus:
                let llvmType = try left.type.llvmGetType(llvm: &llvm)
                if LLVMGetTypeKind(llvmType) == LLVMFloatTypeKind
                    || LLVMGetTypeKind(llvmType) == LLVMDoubleTypeKind
                {
                    return LLVMBuildFSub(llvm.builder, lhs, rhs, "fsub")
                } else {
                    return LLVMBuildSub(llvm.builder, lhs, rhs, "sub")
                }

            case .times:
                let leftType = try left.type.llvmGetType(llvm: &llvm)
                if LLVMGetTypeKind(leftType) == LLVMFloatTypeKind
                    || LLVMGetTypeKind(leftType) == LLVMDoubleTypeKind
                {
                    return LLVMBuildFMul(llvm.builder, lhs, rhs, "fmul")
                } else {
                    return LLVMBuildMul(llvm.builder, lhs, rhs, "mul")
                }

            case .by:
                let leftType = try left.type.llvmGetType(llvm: &llvm)
                if LLVMGetTypeKind(leftType) == LLVMFloatTypeKind
                    || LLVMGetTypeKind(leftType) == LLVMDoubleTypeKind
                {
                    return LLVMBuildFDiv(llvm.builder, lhs, rhs, "fdiv")
                } else {
                    // Signed division
                    return LLVMBuildSDiv(llvm.builder, lhs, rhs, "sdiv")
                }

            case .modulo:
                let leftType = try left.type.llvmGetType(llvm: &llvm)
                if LLVMGetTypeKind(leftType) == LLVMFloatTypeKind
                    || LLVMGetTypeKind(leftType) == LLVMDoubleTypeKind
                {
                    return LLVMBuildFRem(llvm.builder, lhs, rhs, "frem")
                } else {
                    // Signed remainder
                    return LLVMBuildSRem(llvm.builder, lhs, rhs, "srem")
                }

            case .and:
                return LLVMBuildAnd(llvm.builder, lhs, rhs, "and")

            case .or:
                return LLVMBuildOr(llvm.builder, lhs, rhs, "or")

            case .equal:
                let leftType = try left.type.llvmGetType(llvm: &llvm)
                if LLVMGetTypeKind(leftType) == LLVMFloatTypeKind
                    || LLVMGetTypeKind(leftType) == LLVMDoubleTypeKind
                {
                    return LLVMBuildFCmp(
                        llvm.builder, LLVMRealOEQ, lhs, rhs, "fcmp_eq")
                } else {
                    return LLVMBuildICmp(
                        llvm.builder, LLVMIntEQ, lhs, rhs, "icmp_eq")
                }

            case .different:
                let leftType = try left.type.llvmGetType(llvm: &llvm)
                if LLVMGetTypeKind(leftType) == LLVMFloatTypeKind
                    || LLVMGetTypeKind(leftType) == LLVMDoubleTypeKind
                {
                    return LLVMBuildFCmp(
                        llvm.builder, LLVMRealONE, lhs, rhs, "fcmp_ne")
                } else {
                    return LLVMBuildICmp(
                        llvm.builder, LLVMIntNE, lhs, rhs, "icmp_ne")
                }

            case .lessThan:
                let leftType = try left.type.llvmGetType(llvm: &llvm)
                if LLVMGetTypeKind(leftType) == LLVMFloatTypeKind
                    || LLVMGetTypeKind(leftType) == LLVMDoubleTypeKind
                {
                    return LLVMBuildFCmp(
                        llvm.builder, LLVMRealOLT, lhs, rhs, "fcmp_lt")
                } else {
                    // Signed comparison
                    return LLVMBuildICmp(
                        llvm.builder, LLVMIntSLT, lhs, rhs, "icmp_slt")
                }

            case .lessThanOrEqual:
                let leftType = try left.type.llvmGetType(llvm: &llvm)
                if LLVMGetTypeKind(leftType) == LLVMFloatTypeKind
                    || LLVMGetTypeKind(leftType) == LLVMDoubleTypeKind
                {
                    return LLVMBuildFCmp(
                        llvm.builder, LLVMRealOLE, lhs, rhs, "fcmp_le")
                } else {
                    // Signed comparison
                    return LLVMBuildICmp(
                        llvm.builder, LLVMIntSLE, lhs, rhs, "icmp_sle")
                }

            case .greaterThan:
                let leftType = try left.type.llvmGetType(llvm: &llvm)
                if LLVMGetTypeKind(leftType) == LLVMFloatTypeKind
                    || LLVMGetTypeKind(leftType) == LLVMDoubleTypeKind
                {
                    return LLVMBuildFCmp(
                        llvm.builder, LLVMRealOGT, lhs, rhs, "fcmp_gt")
                } else {
                    // Signed comparison
                    return LLVMBuildICmp(
                        llvm.builder, LLVMIntSGT, lhs, rhs, "icmp_sgt")
                }

            case .greaterThanOrEqual:
                let leftType = try left.type.llvmGetType(llvm: &llvm)
                if LLVMGetTypeKind(leftType) == LLVMFloatTypeKind
                    || LLVMGetTypeKind(leftType) == LLVMDoubleTypeKind
                {
                    return LLVMBuildFCmp(
                        llvm.builder, LLVMRealOGE, lhs, rhs, "fcmp_ge")
                } else {
                    // Signed comparison
                    return LLVMBuildICmp(
                        llvm.builder, LLVMIntSGE, lhs, rhs, "icmp_sge")
                }
            case .not:
                fatalError("Not supported in binary expressions")
            }
        // case let .field(field):
        //     if let fieldValue = scope[field] {
        //         return fieldValue
        //     } else {
        //         throw .unsupportedExpression(self)
        //     }
        case let .call(signature, input, arguments):
            let llvmFunction = LLVMGetNamedFunction(
                llvm.module,
                signature.llvmName)

            let function = llvm.functions[signature.llvmName]!

            var params: [LLVMValueRef?] = .init(
                repeating: nil,
                count: function.paramTypes.count)

            let inputCount = input.type != .nothing ? 1 : 0

            if inputCount == 1 {
                params[0] = try input.llvmBuildValue(llvm: &llvm, scope: scope)
            }
            for (tag, argument) in arguments {
                let value = try argument.llvmBuildValue(
                    llvm: &llvm, scope: scope)
                let index = function.paramNames[tag.llvmTag()]!
                params[index + inputCount] = value
            }

            return params.withUnsafeMutableBufferPointer { buffer in
                return LLVMBuildCall2(
                    llvm.builder,
                    function.functionType,
                    llvmFunction,
                    buffer.baseAddress,
                    UInt32(buffer.count),
                    "")
            }
        default:
            fatalError("not implemented: \(self.expressionType)")
        }
    }
}
