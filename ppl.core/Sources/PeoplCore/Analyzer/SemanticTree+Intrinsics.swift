func getIntrinsicDeclarations() -> Semantic.DeclarationsContext {
    return .init(
        typeDeclarations: [
            .init(chain: ["U32"]): .uint,
            .init(chain: ["I32"]): .int,
            .init(chain: ["F64"]): .float,
            .init(chain: ["Bool"]): .bool,
        ],
        valueDeclarations: [:]) }

func getIntrinsicDefinitions() -> Semantic.DefinitionsContext {
    return .init(
        valueDefinitions: [:],
        operators: [
            .init(left: .uint, right: .uint, op: .plus): .init(
                expression: .intrinsic, type: .int),
            .init(left: .nothing, right: .uint, op: .plus): .init(
                expression: .intrinsic, type: .uint),
            .init(left: .uint, right: .uint, op: .minus): .init(
                expression: .intrinsic, type: .uint),
            .init(left: .nothing, right: .uint, op: .minus): .init(
                expression: .intrinsic, type: .uint),
            .init(left: .uint, right: .uint, op: .times): .init(
                expression: .intrinsic, type: .uint),
            .init(left: .uint, right: .uint, op: .by): .init(
                expression: .intrinsic, type: .uint),
            .init(left: .uint, right: .uint, op: .modulo): .init(
                expression: .intrinsic, type: .uint),

            .init(left: .int, right: .int, op: .plus): .init(
                expression: .intrinsic, type: .int),
            .init(left: .nothing, right: .int, op: .plus): .init(
                expression: .intrinsic, type: .int),
            .init(left: .int, right: .int, op: .minus): .init(
                expression: .intrinsic, type: .int),
            .init(left: .nothing, right: .int, op: .minus): .init(
                expression: .intrinsic, type: .int),
            .init(left: .int, right: .int, op: .times): .init(
                expression: .intrinsic, type: .int),
            .init(left: .int, right: .int, op: .by): .init(
                expression: .intrinsic, type: .int),
            .init(left: .int, right: .int, op: .modulo): .init(
                expression: .intrinsic, type: .int),

            .init(left: .float, right: .float, op: .plus): .init(
                expression: .intrinsic, type: .float),
            .init(left: .nothing, right: .float, op: .plus): .init(
                expression: .intrinsic, type: .float),
            .init(left: .float, right: .float, op: .minus): .init(
                expression: .intrinsic, type: .float),
            .init(left: .nothing, right: .float, op: .minus): .init(
                expression: .intrinsic, type: .int),
            .init(left: .float, right: .float, op: .times): .init(
                expression: .intrinsic, type: .float),
            .init(left: .float, right: .float, op: .by): .init(
                expression: .intrinsic, type: .float),

            .init(left: .uint, right: .uint, op: .equal): .init(
                expression: .intrinsic, type: .bool),
            .init(left: .uint, right: .uint, op: .different): .init(
                expression: .intrinsic, type: .bool),
            .init(left: .uint, right: .uint, op: .lessThan): .init(
                expression: .intrinsic, type: .bool),
            .init(left: .uint, right: .uint, op: .lessThanOrEqual): .init(
                expression: .intrinsic, type: .bool),
            .init(left: .uint, right: .uint, op: .greaterThan): .init(
                expression: .intrinsic, type: .bool),
            .init(left: .uint, right: .uint, op: .greaterThanOrEqual): .init(
                expression: .intrinsic, type: .bool),

            .init(left: .int, right: .int, op: .equal): .init(
                expression: .intrinsic, type: .bool),
            .init(left: .int, right: .int, op: .different): .init(
                expression: .intrinsic, type: .bool),
            .init(left: .int, right: .int, op: .lessThan): .init(
                expression: .intrinsic, type: .bool),
            .init(left: .int, right: .int, op: .lessThanOrEqual): .init(
                expression: .intrinsic, type: .bool),
            .init(left: .int, right: .int, op: .greaterThan): .init(
                expression: .intrinsic, type: .bool),
            .init(left: .int, right: .int, op: .greaterThanOrEqual): .init(
                expression: .intrinsic, type: .bool),

            .init(left: .float, right: .float, op: .equal): .init(
                expression: .intrinsic, type: .bool),
            .init(left: .float, right: .float, op: .different): .init(
                expression: .intrinsic, type: .bool),
            .init(left: .float, right: .float, op: .lessThan): .init(
                expression: .intrinsic, type: .bool),
            .init(left: .float, right: .float, op: .lessThanOrEqual): .init(
                expression: .intrinsic, type: .bool),
            .init(left: .float, right: .float, op: .greaterThan): .init(
                expression: .intrinsic, type: .bool),
            .init(left: .float, right: .float, op: .greaterThanOrEqual): .init(
                expression: .intrinsic, type: .bool),

            .init(left: .string, right: .string, op: .equal): .init(
                expression: .intrinsic, type: .bool),
            .init(left: .string, right: .string, op: .different): .init(
                expression: .intrinsic, type: .bool),

            .init(left: .bool, right: .bool, op: .equal): .init(
                expression: .intrinsic, type: .bool),
            .init(left: .bool, right: .bool, op: .different): .init(
                expression: .intrinsic, type: .bool),
            .init(left: .bool, right: .bool, op: .and): .init(
                expression: .intrinsic, type: .bool),
            .init(left: .bool, right: .bool, op: .or): .init(
                expression: .intrinsic, type: .bool),
            .init(left: .nothing, right: .bool, op: .not): .init(
                expression: .intrinsic, type: .bool),
        ]

    )
}
