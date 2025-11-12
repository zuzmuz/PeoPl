// extension Semantic.TypeSpecifier {
// 	static let uint = Semantic.TypeSpecifier.nominal(.init(chain: ["UInt"]))
// 	static let int = Semantic.TypeSpecifier.nominal(.init(chain: ["Int"]))
// 	static let float = Semantic.TypeSpecifier.nominal(.init(chain: ["Float"]))
// 	// static let string =
// 	// Semantic.TypeSpecifier.(.intrinsic(Semantic.IntrinsicType))
// 	static let bool = Semantic.TypeSpecifier.nominal(.init(chain: ["Bool"]))
//
// 	static let nothing = Semantic.TypeSpecifier.raw(.record([:]))
// 	static let never = Semantic.TypeSpecifier.nominal(.init(chain: ["Never"]))
// }
//
// extension Semantic {
// 	public static func getIntrinsicDeclarations() -> Semantic.DeclarationsContext
// 	{
// 		return .init(
// 			typeDeclarations: [
// 				.init(chain: ["UInt"]): .uint,
// 				.init(chain: ["Int"]): .int,
// 				.init(chain: ["Float"]): .float,
// 				.init(chain: ["Bool"]): .bool,
// 			],
// 			functionDeclarations: [:],
// 			operatorDeclarations: [
// 				.init(left: .uint, right: .uint, op: .plus): .uint,
// 				.init(left: .nothing, right: .uint, op: .plus): .uint,
// 				.init(left: .uint, right: .uint, op: .minus): .uint,
// 				.init(left: .nothing, right: .uint, op: .minus): .uint,
// 				.init(left: .uint, right: .uint, op: .times): .uint,
// 				.init(left: .uint, right: .uint, op: .by): .uint,
// 				.init(left: .uint, right: .uint, op: .modulo): .uint,
//
// 				.init(left: .int, right: .int, op: .plus): .int,
// 				.init(left: .nothing, right: .int, op: .plus): .int,
// 				.init(left: .int, right: .int, op: .minus): .int,
// 				.init(left: .nothing, right: .int, op: .minus): .int,
// 				.init(left: .int, right: .int, op: .times): .int,
// 				.init(left: .int, right: .int, op: .by): .int,
// 				.init(left: .int, right: .int, op: .modulo): .int,
//
// 				.init(left: .float, right: .float, op: .plus): .float,
// 				.init(left: .nothing, right: .float, op: .plus): .float,
// 				.init(left: .float, right: .float, op: .minus): .float,
// 				.init(left: .nothing, right: .float, op: .minus): .int,
// 				.init(left: .float, right: .float, op: .times): .float,
// 				.init(left: .float, right: .float, op: .by): .float,
//
// 				.init(left: .uint, right: .uint, op: .equal): .bool,
// 				.init(left: .uint, right: .uint, op: .different): .bool,
// 				.init(left: .uint, right: .uint, op: .lessThan): .bool,
// 				.init(left: .uint, right: .uint, op: .lessThanOrEqual): .bool,
// 				.init(left: .uint, right: .uint, op: .greaterThan): .bool,
// 				.init(left: .uint, right: .uint, op: .greaterThanOrEqual):
// 					.bool,
//
// 				.init(left: .int, right: .int, op: .equal): .bool,
// 				.init(left: .int, right: .int, op: .different): .bool,
// 				.init(left: .int, right: .int, op: .lessThan): .bool,
// 				.init(left: .int, right: .int, op: .lessThanOrEqual): .bool,
// 				.init(left: .int, right: .int, op: .greaterThan): .bool,
// 				.init(left: .int, right: .int, op: .greaterThanOrEqual): .bool,
//
// 				.init(left: .float, right: .float, op: .equal): .bool,
// 				.init(left: .float, right: .float, op: .different): .bool,
// 				.init(left: .float, right: .float, op: .lessThan): .bool,
// 				.init(left: .float, right: .float, op: .lessThanOrEqual): .bool,
// 				.init(left: .float, right: .float, op: .greaterThan): .bool,
// 				.init(left: .float, right: .float, op: .greaterThanOrEqual):
// 					.bool,
//
// 				// .init(left: .string, right: .string, op: .equal): .bool,
// 				// .init(left: .string, right: .string, op: .different): .bool,
//
// 				.init(left: .bool, right: .bool, op: .equal): .bool,
// 				.init(left: .bool, right: .bool, op: .different): .bool,
// 				.init(left: .bool, right: .bool, op: .and): .bool,
// 				.init(left: .bool, right: .bool, op: .or): .bool,
// 				.init(left: .nothing, right: .bool, op: .not): .bool,
// 			]
// 		)
// 	}
//
// 	func getIntrinsicDefinitions() -> Semantic.DefinitionsContext {
// 		return .init(
// 			functionDefinitions: [:],
// 			typeDefinitions: [:]
// 			// operators: [
// 			//     .init(left: .uint, right: .uint, op: .plus): .init(
// 			//         expression: .intrinsic, type: .int),
// 			//     .init(left: .nothing, right: .uint, op: .plus): .init(
// 			//         expression: .intrinsic, type: .uint),
// 			//     .init(left: .uint, right: .uint, op: .minus): .init(
// 			//         expression: .intrinsic, type: .uint),
// 			//     .init(left: .nothing, right: .uint, op: .minus): .init(
// 			//         expression: .intrinsic, type: .uint),
// 			//     .init(left: .uint, right: .uint, op: .times): .init(
// 			//         expression: .intrinsic, type: .uint),
// 			//     .init(left: .uint, right: .uint, op: .by): .init(
// 			//         expression: .intrinsic, type: .uint),
// 			//     .init(left: .uint, right: .uint, op: .modulo): .init(
// 			//         expression: .intrinsic, type: .uint),
// 			//
// 			//     .init(left: .int, right: .int, op: .plus): .init(
// 			//         expression: .intrinsic, type: .int),
// 			//     .init(left: .nothing, right: .int, op: .plus): .init(
// 			//         expression: .intrinsic, type: .int),
// 			//     .init(left: .int, right: .int, op: .minus): .init(
// 			//         expression: .intrinsic, type: .int),
// 			//     .init(left: .nothing, right: .int, op: .minus): .init(
// 			//         expression: .intrinsic, type: .int),
// 			//     .init(left: .int, right: .int, op: .times): .init(
// 			//         expression: .intrinsic, type: .int),
// 			//     .init(left: .int, right: .int, op: .by): .init(
// 			//         expression: .intrinsic, type: .int),
// 			//     .init(left: .int, right: .int, op: .modulo): .init(
// 			//         expression: .intrinsic, type: .int),
// 			//
// 			//     .init(left: .float, right: .float, op: .plus): .init(
// 			//         expression: .intrinsic, type: .float),
// 			//     .init(left: .nothing, right: .float, op: .plus): .init(
// 			//         expression: .intrinsic, type: .float),
// 			//     .init(left: .float, right: .float, op: .minus): .init(
// 			//         expression: .intrinsic, type: .float),
// 			//     .init(left: .nothing, right: .float, op: .minus): .init(
// 			//         expression: .intrinsic, type: .int),
// 			//     .init(left: .float, right: .float, op: .times): .init(
// 			//         expression: .intrinsic, type: .float),
// 			//     .init(left: .float, right: .float, op: .by): .init(
// 			//         expression: .intrinsic, type: .float),
// 			//
// 			//     .init(left: .uint, right: .uint, op: .equal): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//     .init(left: .uint, right: .uint, op: .different): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//     .init(left: .uint, right: .uint, op: .lessThan): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//     .init(left: .uint, right: .uint, op: .lessThanOrEqual): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//     .init(left: .uint, right: .uint, op: .greaterThan): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//     .init(left: .uint, right: .uint, op: .greaterThanOrEqual): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//
// 			//     .init(left: .int, right: .int, op: .equal): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//     .init(left: .int, right: .int, op: .different): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//     .init(left: .int, right: .int, op: .lessThan): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//     .init(left: .int, right: .int, op: .lessThanOrEqual): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//     .init(left: .int, right: .int, op: .greaterThan): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//     .init(left: .int, right: .int, op: .greaterThanOrEqual): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//
// 			//     .init(left: .float, right: .float, op: .equal): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//     .init(left: .float, right: .float, op: .different): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//     .init(left: .float, right: .float, op: .lessThan): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//     .init(left: .float, right: .float, op: .lessThanOrEqual): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//     .init(left: .float, right: .float, op: .greaterThan): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//     .init(left: .float, right: .float, op: .greaterThanOrEqual): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//
// 			//     .init(left: .string, right: .string, op: .equal): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//     .init(left: .string, right: .string, op: .different): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//
// 			//     .init(left: .bool, right: .bool, op: .equal): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//     .init(left: .bool, right: .bool, op: .different): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//     .init(left: .bool, right: .bool, op: .and): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//     .init(left: .bool, right: .bool, op: .or): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			//     .init(left: .nothing, right: .bool, op: .not): .init(
// 			//         expression: .intrinsic, type: .bool),
// 			// ]
// 		)
// 	}
// }
