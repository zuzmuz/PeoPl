import cllvm

extension Semantic.Expression: LLVM.ValueBuilder {

    func llvmBuildUnary(
        op: Operator,
        expression: Semantic.Expression,
        llvm: inout LLVM.Builder,
        scope: borrowing [LLVM.ParamTag: LLVMValueRef?]
    ) throws(LLVM.Error) -> LLVMValueRef? {
        let value = try expression.llvmBuildValue(llvm: &llvm, scope: scope)

        switch op {
        case .plus:
            return value
        case .minus:
            let llvmType = try expression.type.llvmGetType(llvm: &llvm)
            if LLVMGetTypeKind(llvmType) == LLVMFloatTypeKind
                || LLVMGetTypeKind(llvmType) == LLVMDoubleTypeKind
            {
                return LLVMBuildFNeg(llvm.builder, value, "neg")
            } else {
                return LLVMBuildNeg(llvm.builder, value, "neg")
            }
        case .not:
            return LLVMBuildNot(llvm.builder, value, "not")
        default:
            throw .unreachable
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    func llvmBuildBinary(
        op: Operator,
        left: Semantic.Expression,
        right: Semantic.Expression,
        llvm: inout LLVM.Builder,
        scope: borrowing [LLVM.ParamTag: LLVMValueRef?]
    ) throws(LLVM.Error) -> LLVMValueRef? {
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
                // return LLVMBuildIntCast2(
                //     llvm.builder, cmp,
                //     LLVMInt32TypeInContext(llvm.context),
                //     0, "cast")
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
            throw .unreachable
        }
    }

    func llvmBuildCall(
        signature: Semantic.FunctionSignature,
        input: Semantic.Expression,
        arguments: [Semantic.Tag: Semantic.Expression],
        llvm: inout LLVM.Builder,
        scope: borrowing [LLVM.ParamTag: LLVMValueRef?]
    ) throws(LLVM.Error) -> LLVMValueRef? {
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
            params[Int(index)] = value
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
    }

    func llvmBuildInitializer(
        type: Semantic.TypeSpecifier,
        arguments: [Semantic.Tag: Semantic.Expression],
        llvm: inout LLVM.Builder,
        scope: borrowing [LLVM.ParamTag: LLVMValueRef?]
    ) throws(LLVM.Error) -> LLVMValueRef? {
        let typeDefinition = try type.llvmGetTypeDefinition(llvm: &llvm)
        let structType = typeDefinition.structType

        let value = LLVMBuildAlloca(
            llvm.builder, typeDefinition.structType, "struct")

        for (tag, argument) in arguments {
            let fieldIndex =
                typeDefinition.paramNames[tag.llvmTag()]!
            let fieldPointer = LLVMBuildStructGEP2(
                llvm.builder,
                structType,
                value,
                fieldIndex,
                "field_ptr")
            let argumentValue = try argument.llvmBuildValue(
                llvm: &llvm, scope: scope)
            LLVMBuildStore(llvm.builder, argumentValue, fieldPointer)
        }

        return value
    }

    func llvmBuildAccess(
        expression: Semantic.Expression,
        field: Semantic.Tag,
        llvm: inout LLVM.Builder,
        scope: borrowing [LLVM.ParamTag: LLVMValueRef?]
    ) throws(LLVM.Error) -> LLVMValueRef? {
        let expressionType = try expression.type.llvmGetTypeDefinition(
            llvm: &llvm)
        let expressionValue = try expression.llvmBuildValue(
            llvm: &llvm, scope: scope)
        let fieldIndex =
            expressionType.paramNames[field.llvmTag()]!
        let fieldType = expressionType.paramTypes[Int(fieldIndex)]

        let fieldPointer = LLVMBuildStructGEP2(
            llvm.builder,
            expressionType.structType,
            expressionValue,
            fieldIndex,
            "field_ptr")

        return LLVMBuildLoad2(
            llvm.builder,
            fieldType,
            fieldPointer,
            "field_value"
        )
    }

    func llvmBuildBranches(
        branches: [(
            match: Semantic.BindingExpression,
            guard: Semantic.Expression,
            body: Semantic.Expression
        )],
        llvm: inout LLVM.Builder,
        scope: borrowing [LLVM.ParamTag: LLVMValueRef?]
    ) throws(LLVM.Error) -> LLVMValueRef? {
        // TODO: each branch should be tagged (0 ..< n)
        // the switch expression input should evaluate the tag based on the the branches conditions and the input

        let branchingType = try self.type.llvmGetType(llvm: &llvm)
        let function = LLVMGetBasicBlockParent(
            LLVMGetInsertBlock(llvm.builder))

        let defaultBlock = LLVMAppendBasicBlockInContext(
            llvm.context, function, "default")
        // TODO: add unique identifiers to branches

        let resultValue = LLVMBuildAlloca(
            llvm.builder,
            branchingType,
            "branch_result")

        // this is convoluted and I think can be improved but is a general solution
        let switchCondition: LLVMValueRef =
            try branches.map { branch throws(LLVM.Error) in
                let matchCondition = try branch.match.condition.llvmBuildValue(
                    llvm: &llvm, scope: scope)
                let guardCondition = try branch.guard.llvmBuildValue(
                    llvm: &llvm, scope: scope)
                let combinedCondition = LLVMBuildAnd(
                    llvm.builder, matchCondition, guardCondition, "combined")

                return LLVMBuildIntCast2(
                    llvm.builder,
                    combinedCondition,
                    LLVMInt32TypeInContext(llvm.context),
                    0,
                    "cast")
            }.enumerated().reduce(
                LLVMConstInt(
                    LLVMInt32TypeInContext(llvm.context),
                    0,
                    0)
            ) { llvmValue, enumeratedValue in
                LLVMBuildAdd(
                    llvm.builder,
                    llvmValue,
                    LLVMBuildMul(
                        llvm.builder,
                        enumeratedValue.element,
                        LLVMConstInt(
                            LLVMInt32TypeInContext(llvm.context),
                            UInt64(enumeratedValue.offset),
                            0),
                        "mul"),
                    "added")
            }

        let switchExpression = LLVMBuildSwitch(
            llvm.builder,
            switchCondition,
            defaultBlock,
            UInt32(branches.count) - 1)

        let continueBlock = LLVMAppendBasicBlockInContext(
            llvm.context,
            function,
            "continue")

        for (index, branch) in branches.dropLast().enumerated() {
            let block = LLVMAppendBasicBlockInContext(
                llvm.context, function, "b_\(index)")
            // let matchValue = try branch.match.condition.llvmBuildValue(
            //     llvm: &llvm, scope: scope)
            let matchValue = LLVMConstInt(
                LLVMInt32TypeInContext(llvm.context), UInt64(index), 0)
            LLVMAddCase(switchExpression, matchValue, block)
            LLVMPositionBuilderAtEnd(llvm.builder, block)

            // TODO: add values to the scope based on bindings
            // bindings can be
            // - simple pure binding (capturing the whole input)
            // - complex pattern matching (capturing inner members of structures)
            // - tagged expressions (for sum types)

            LLVMBuildStore(
                llvm.builder,
                try branch.body.llvmBuildValue(llvm: &llvm, scope: scope),
                resultValue)

            LLVMBuildBr(llvm.builder, continueBlock)
        }

        LLVMPositionBuilderAtEnd(llvm.builder, defaultBlock)
        LLVMBuildStore(
            llvm.builder,
            try branches.last?.body.llvmBuildValue(
                llvm: &llvm, scope: scope),
            resultValue)
        LLVMBuildBr(llvm.builder, continueBlock)

        LLVMPositionBuilderAtEnd(llvm.builder, continueBlock)

        return LLVMBuildLoad2(
            llvm.builder, branchingType, resultValue, "result")
    }

    func llvmBuildValue(
        llvm: inout LLVM.Builder,
        scope: borrowing [LLVM.ParamTag: LLVMValueRef?]
    ) throws(LLVM.Error) -> LLVMValueRef? {
        // TODO: generate typeref for builtins to use in literals,
        // also consider using the generic undefined literals (getting type from expression rather assuming the literal)
        switch self {
        case .input:
            if let inputValue = scope[.input] {
                return inputValue
            } else {
                return LLVMConstNull(LLVMVoidTypeInContext(llvm.context))
            }
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
        case let .unary(op, expression, _):
            return try self.llvmBuildUnary(
                op: op,
                expression: expression,
                llvm: &llvm,
                scope: scope)
        case let .binary(op, left, right, _):
            return try self.llvmBuildBinary(
                op: op,
                left: left,
                right: right,
                llvm: &llvm,
                scope: scope)
        case let .fieldInScope(tag, _):
            return scope[tag.llvmTag()]!
        case let .call(signature, input, arguments, _):
            return try self.llvmBuildCall(
                signature: signature,
                input: input,
                arguments: arguments,
                llvm: &llvm,
                scope: scope)
        case let .access(expression, field, _):
            return try self.llvmBuildAccess(
                expression: expression,
                field: field,
                llvm: &llvm,
                scope: scope)
        case let .initializer(type, arguments):
            return try self.llvmBuildInitializer(
                type: type,
                arguments: arguments,
                llvm: &llvm,
                scope: scope)
        // case let .branching(branches):
        //     return try self.llvmBuildBranches(
        //         branches: branches,
        //         llvm: &llvm,
        //         scope: scope)
        default:
            throw .notImplemented(
                "other expressions \(self) are not implemented yet")
        }
    }
}
