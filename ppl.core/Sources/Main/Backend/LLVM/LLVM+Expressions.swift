// import cllvm
//
// extension Semantic.Expression: LLVM.ValueBuilder {
// 	func llvmBuildUnary(
// 		op: Operator,
// 		expression: Semantic.Expression,
// 		llvm: inout LLVM.Builder,
// 		scope: borrowing [LLVM.ParamTag: LLVMValueRef?]
// 	) throws(LLVM.Error) -> LLVMValueRef? {
// 		let value = try expression.llvmBuildValue(llvm: &llvm, scope: scope)
//
// 		switch op {
// 		case .plus:
// 			return value
// 		case .minus:
// 			let llvmType = try expression.type.llvmGetType(llvm: &llvm)
// 			if LLVMGetTypeKind(llvmType) == LLVMFloatTypeKind
// 				|| LLVMGetTypeKind(llvmType) == LLVMDoubleTypeKind
// 			{
// 				return LLVMBuildFNeg(llvm.builder, value, "neg")
// 			} else {
// 				return LLVMBuildNeg(llvm.builder, value, "neg")
// 			}
// 		case .not:
// 			return LLVMBuildNot(llvm.builder, value, "not")
// 		default:
// 			throw .unreachable
// 		}
// 	}
//
// 	// swiftlint:disable:next cyclomatic_complexity
// 	func llvmBuildBinary(
// 		op: Operator,
// 		left: Semantic.Expression,
// 		right: Semantic.Expression,
// 		llvm: inout LLVM.Builder,
// 		scope: borrowing [LLVM.ParamTag: LLVMValueRef?]
// 	) throws(LLVM.Error) -> LLVMValueRef? {
// 		let lhs = try left.llvmBuildValue(llvm: &llvm, scope: scope)
// 		let rhs = try right.llvmBuildValue(llvm: &llvm, scope: scope)
//
// 		switch op {
// 		case .plus:
// 			// Check if we're dealing with integers or floating point
// 			let llvmType = try left.type.llvmGetType(llvm: &llvm)
// 			if LLVMGetTypeKind(llvmType) == LLVMFloatTypeKind
// 				|| LLVMGetTypeKind(llvmType) == LLVMDoubleTypeKind
// 			{
// 				return LLVMBuildFAdd(llvm.builder, lhs, rhs, "fadd")
// 			} else {
// 				return LLVMBuildAdd(llvm.builder, lhs, rhs, "add")
// 			}
//
// 		case .minus:
// 			let llvmType = try left.type.llvmGetType(llvm: &llvm)
// 			if LLVMGetTypeKind(llvmType) == LLVMFloatTypeKind
// 				|| LLVMGetTypeKind(llvmType) == LLVMDoubleTypeKind
// 			{
// 				return LLVMBuildFSub(llvm.builder, lhs, rhs, "fsub")
// 			} else {
// 				return LLVMBuildSub(llvm.builder, lhs, rhs, "sub")
// 			}
//
// 		case .times:
// 			let leftType = try left.type.llvmGetType(llvm: &llvm)
// 			if LLVMGetTypeKind(leftType) == LLVMFloatTypeKind
// 				|| LLVMGetTypeKind(leftType) == LLVMDoubleTypeKind
// 			{
// 				return LLVMBuildFMul(llvm.builder, lhs, rhs, "fmul")
// 			} else {
// 				return LLVMBuildMul(llvm.builder, lhs, rhs, "mul")
// 			}
//
// 		case .by:
// 			let leftType = try left.type.llvmGetType(llvm: &llvm)
// 			if LLVMGetTypeKind(leftType) == LLVMFloatTypeKind
// 				|| LLVMGetTypeKind(leftType) == LLVMDoubleTypeKind
// 			{
// 				return LLVMBuildFDiv(llvm.builder, lhs, rhs, "fdiv")
// 			} else {
// 				// Signed division
// 				return LLVMBuildSDiv(llvm.builder, lhs, rhs, "sdiv")
// 			}
//
// 		case .modulo:
// 			let leftType = try left.type.llvmGetType(llvm: &llvm)
// 			if LLVMGetTypeKind(leftType) == LLVMFloatTypeKind
// 				|| LLVMGetTypeKind(leftType) == LLVMDoubleTypeKind
// 			{
// 				return LLVMBuildFRem(llvm.builder, lhs, rhs, "frem")
// 			} else {
// 				// Signed remainder
// 				return LLVMBuildSRem(llvm.builder, lhs, rhs, "srem")
// 			}
//
// 		case .and:
// 			return LLVMBuildAnd(llvm.builder, lhs, rhs, "and")
//
// 		case .or:
// 			return LLVMBuildOr(llvm.builder, lhs, rhs, "or")
//
// 		case .equal:
// 			let leftType = try left.type.llvmGetType(llvm: &llvm)
// 			if LLVMGetTypeKind(leftType) == LLVMFloatTypeKind
// 				|| LLVMGetTypeKind(leftType) == LLVMDoubleTypeKind
// 			{
// 				return LLVMBuildFCmp(
// 					llvm.builder, LLVMRealOEQ, lhs, rhs, "fcmp_eq"
// 				)
// 			} else {
// 				return LLVMBuildICmp(
// 					llvm.builder, LLVMIntEQ, lhs, rhs, "icmp_eq"
// 				)
// 				// return LLVMBuildIntCast2(
// 				//     llvm.builder, cmp,
// 				//     LLVMInt32TypeInContext(llvm.context),
// 				//     0, "cast")
// 			}
//
// 		case .different:
// 			let leftType = try left.type.llvmGetType(llvm: &llvm)
// 			if LLVMGetTypeKind(leftType) == LLVMFloatTypeKind
// 				|| LLVMGetTypeKind(leftType) == LLVMDoubleTypeKind
// 			{
// 				return LLVMBuildFCmp(
// 					llvm.builder, LLVMRealONE, lhs, rhs, "fcmp_ne"
// 				)
// 			} else {
// 				return LLVMBuildICmp(
// 					llvm.builder, LLVMIntNE, lhs, rhs, "icmp_ne"
// 				)
// 			}
//
// 		case .lessThan:
// 			let leftType = try left.type.llvmGetType(llvm: &llvm)
// 			if LLVMGetTypeKind(leftType) == LLVMFloatTypeKind
// 				|| LLVMGetTypeKind(leftType) == LLVMDoubleTypeKind
// 			{
// 				return LLVMBuildFCmp(
// 					llvm.builder, LLVMRealOLT, lhs, rhs, "fcmp_lt"
// 				)
// 			} else {
// 				// Signed comparison
// 				return LLVMBuildICmp(
// 					llvm.builder, LLVMIntSLT, lhs, rhs, "icmp_slt"
// 				)
// 			}
//
// 		case .lessThanOrEqual:
// 			let leftType = try left.type.llvmGetType(llvm: &llvm)
// 			if LLVMGetTypeKind(leftType) == LLVMFloatTypeKind
// 				|| LLVMGetTypeKind(leftType) == LLVMDoubleTypeKind
// 			{
// 				return LLVMBuildFCmp(
// 					llvm.builder, LLVMRealOLE, lhs, rhs, "fcmp_le"
// 				)
// 			} else {
// 				// Signed comparison
// 				return LLVMBuildICmp(
// 					llvm.builder, LLVMIntSLE, lhs, rhs, "icmp_sle"
// 				)
// 			}
//
// 		case .greaterThan:
// 			let leftType = try left.type.llvmGetType(llvm: &llvm)
// 			if LLVMGetTypeKind(leftType) == LLVMFloatTypeKind
// 				|| LLVMGetTypeKind(leftType) == LLVMDoubleTypeKind
// 			{
// 				return LLVMBuildFCmp(
// 					llvm.builder, LLVMRealOGT, lhs, rhs, "fcmp_gt"
// 				)
// 			} else {
// 				// Signed comparison
// 				return LLVMBuildICmp(
// 					llvm.builder, LLVMIntSGT, lhs, rhs, "icmp_sgt"
// 				)
// 			}
//
// 		case .greaterThanOrEqual:
// 			let leftType = try left.type.llvmGetType(llvm: &llvm)
// 			if LLVMGetTypeKind(leftType) == LLVMFloatTypeKind
// 				|| LLVMGetTypeKind(leftType) == LLVMDoubleTypeKind
// 			{
// 				return LLVMBuildFCmp(
// 					llvm.builder, LLVMRealOGE, lhs, rhs, "fcmp_ge"
// 				)
// 			} else {
// 				// Signed comparison
// 				return LLVMBuildICmp(
// 					llvm.builder, LLVMIntSGE, lhs, rhs, "icmp_sge"
// 				)
// 			}
//
// 		case .not:
// 			throw .unreachable
// 		}
// 	}
//
// 	func llvmBuildCall(
// 		signature: Semantic.FunctionSignature,
// 		input: Semantic.Expression,
// 		arguments: [Semantic.Tag: Semantic.Expression],
// 		llvm: inout LLVM.Builder,
// 		scope: borrowing [LLVM.ParamTag: LLVMValueRef?]
// 	) throws(LLVM.Error) -> LLVMValueRef? {
// 		let llvmFunction = LLVMGetNamedFunction(
// 			llvm.module,
// 			signature.llvmName
// 		)
//
// 		let function = llvm.functions[signature.llvmName]!
//
// 		var params: [LLVMValueRef?] = .init(
// 			repeating: nil,
// 			count: function.paramTypes.count
// 		)
//
// 		let inputCount = input.type != .nothing ? 1 : 0
//
// 		if inputCount == 1 {
// 			params[0] = try input.llvmBuildValue(llvm: &llvm, scope: scope)
// 		}
// 		for (tag, argument) in arguments {
// 			let value = try argument.llvmBuildValue(
// 				llvm: &llvm, scope: scope
// 			)
// 			let index = function.paramNames[tag.llvmTag()]!
// 			params[Int(index)] = value
// 		}
//
// 		return params.withUnsafeMutableBufferPointer { buffer in
// 			LLVMBuildCall2(
// 				llvm.builder,
// 				function.functionType,
// 				llvmFunction,
// 				buffer.baseAddress,
// 				UInt32(buffer.count),
// 				""
// 			)
// 		}
// 	}
//
// 	func llvmBuildInitializer(
// 		type: Semantic.TypeSpecifier,
// 		arguments: [Semantic.Tag: Semantic.Expression],
// 		llvm: inout LLVM.Builder,
// 		scope: borrowing [LLVM.ParamTag: LLVMValueRef?]
// 	) throws(LLVM.Error) -> LLVMValueRef? {
// 		let typeDefinition = try type.llvmGetTypeDefinition(llvm: &llvm)
// 		let structType = typeDefinition.structType
//
// 		let value = LLVMBuildAlloca(
// 			llvm.builder, typeDefinition.structType, "struct"
// 		)
//
// 		for (tag, argument) in arguments {
// 			let fieldIndex =
// 				typeDefinition.paramNames[tag.llvmTag()]!
// 			let fieldPointer = LLVMBuildStructGEP2(
// 				llvm.builder,
// 				structType,
// 				value,
// 				fieldIndex,
// 				"field_ptr"
// 			)
// 			let argumentValue = try argument.llvmBuildValue(
// 				llvm: &llvm, scope: scope
// 			)
// 			LLVMBuildStore(llvm.builder, argumentValue, fieldPointer)
// 		}
//
// 		return value
// 	}
//
// 	func llvmBuildAccess(
// 		expression: Semantic.Expression,
// 		field: Semantic.Tag,
// 		llvm: inout LLVM.Builder,
// 		scope: borrowing [LLVM.ParamTag: LLVMValueRef?]
// 	) throws(LLVM.Error) -> LLVMValueRef? {
// 		let expressionType = try expression.type.llvmGetTypeDefinition(
// 			llvm: &llvm
// 		)
// 		let expressionValue = try expression.llvmBuildValue(
// 			llvm: &llvm, scope: scope
// 		)
// 		let fieldIndex =
// 			expressionType.paramNames[field.llvmTag()]!
// 		let fieldType = expressionType.paramTypes[Int(fieldIndex)]
//
// 		let fieldPointer = LLVMBuildStructGEP2(
// 			llvm.builder,
// 			expressionType.structType,
// 			expressionValue,
// 			fieldIndex,
// 			"field_ptr"
// 		)
//
// 		return LLVMBuildLoad2(
// 			llvm.builder,
// 			fieldType,
// 			fieldPointer,
// 			"field_value"
// 		)
// 	}
//
// 	func llvmBuildBranches(
// 		matrix _: Semantic.DecompositionMatrix,
// 		llvm _: inout LLVM.Builder,
// 		scope _: borrowing [LLVM.ParamTag: LLVMValueRef?]
// 	) throws(LLVM.Error) -> LLVMValueRef? {
// 		throw .notImplemented(
// 			"branching expressions are not implemented yet"
// 		)
// 	}
//
// 	func llvmBuildValue(
// 		llvm: inout LLVM.Builder,
// 		scope: borrowing [LLVM.ParamTag: LLVMValueRef?]
// 	) throws(LLVM.Error) -> LLVMValueRef? {
// 		// TODO: generate typeref for builtins to use in literals,
// 		// also consider using the generic undefined literals (getting type from
// 		// expression rather assuming the literal)
// 		switch self {
// 		case .input:
// 			if let inputValue = scope[.input] {
// 				return inputValue
// 			} else {
// 				return LLVMConstNull(LLVMVoidTypeInContext(llvm.context))
// 			}
// 		case .nothing:
// 			return LLVMConstNull(LLVMVoidTypeInContext(llvm.context))
// 		case .never:
// 			return LLVMBuildUnreachable(llvm.builder)
// 		case let .intLiteral(value):
// 			return try LLVMConstInt(
// 				type.llvmGetType(llvm: &llvm), value, 0
// 			)
// 		case let .floatLiteral(value):
// 			return try LLVMConstReal(
// 				type.llvmGetType(llvm: &llvm),
// 				Double(value)
// 			)
// 		case let .stringLiteral(value):
// 			// WARN: not sure about this one
// 			return LLVMBuildGlobalStringPtr(llvm.builder, value, "str")
// 		case let .boolLiteral(value):
// 			return LLVMConstInt(
// 				LLVMInt1TypeInContext(llvm.context),
// 				value ? 1 : 0,
// 				0
// 			)
// 		case let .unary(op, expression, _):
// 			return try llvmBuildUnary(
// 				op: op,
// 				expression: expression,
// 				llvm: &llvm,
// 				scope: scope
// 			)
// 		case let .binary(op, left, right, _):
// 			return try llvmBuildBinary(
// 				op: op,
// 				left: left,
// 				right: right,
// 				llvm: &llvm,
// 				scope: scope
// 			)
// 		case let .fieldInScope(tag, _):
// 			return scope[tag.llvmTag()]!
// 		case let .call(signature, input, arguments, _):
// 			return try llvmBuildCall(
// 				signature: signature,
// 				input: input,
// 				arguments: arguments,
// 				llvm: &llvm,
// 				scope: scope
// 			)
// 		case let .access(expression, field, _):
// 			return try llvmBuildAccess(
// 				expression: expression,
// 				field: field,
// 				llvm: &llvm,
// 				scope: scope
// 			)
// 		case let .initializer(type, arguments):
// 			return try llvmBuildInitializer(
// 				type: type,
// 				arguments: arguments,
// 				llvm: &llvm,
// 				scope: scope
// 			)
// 		case let .branched(matrix, _):
// 			return try llvmBuildBranches(
// 				matrix: matrix,
// 				llvm: &llvm,
// 				scope: scope
// 			)
// 		default:
// 			throw .notImplemented(
// 				"other expressions \(self) are not implemented yet"
// 			)
// 		}
// 	}
// }
