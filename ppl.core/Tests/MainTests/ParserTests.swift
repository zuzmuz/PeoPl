import XCTest

@testable import Main

extension Syntax.Module: Testable {
    func assertEqual(
        with: Self
    ) {
        XCTAssertEqual(
            self.definitions.count,
            with.definitions.count,
            "Module \(self.sourceName) definition counts do not match")
        zip(self.definitions, with.definitions).forEach {
            $0.assertEqual(with: $1)
        }
    }
}

extension Syntax.Definition: Testable {
    func assertEqual(
        with: Self
    ) {
        XCTAssertEqual(
            self.identifier,
            with.identifier,
            "Type definition identifier \(self.identifier) does not match \(with.identifier)"
        )

        if let withTypeSpecifier = with.typeSpecifier {
            XCTAssertNotNil(self.typeSpecifier)
            if let typeSpecifier = self.typeSpecifier {
                typeSpecifier.assertEqual(with: withTypeSpecifier)
            }
        }

        XCTAssertEqual(
            self.typeArguments.count,
            with.typeArguments.count,
            "Type Arguments \(self.location) counts do not match")
        zip(self.typeArguments, with.typeArguments).forEach {
            $0.assertEqual(with: $1)
        }

        self.definition.assertEqual(with: with.definition)
    }
}

extension Syntax.TypeSpecifier: Testable {
    func assertEqual(
        with: Self
    ) {
        switch (self, with) {
        case (.nothing, .nothing), (.never, .never):
            // pass
            break
        case let (.recordType(lhs), .recordType(rhs)):
            lhs.assertEqual(with: rhs)
        case let (.choiceType(lhs), .choiceType(rhs)):
            lhs.assertEqual(with: rhs)
        case let (.nominal(lhs), .nominal(rhs)):
            lhs.assertEqual(with: rhs)
        case let (.function(lhs), .function(rhs)):
            lhs.assertEqual(with: rhs)
        default:
            XCTFail("Type specifiers do not match \(self) vs \(with)")
        }
    }
}

extension Syntax.RecordType: Testable {
    func assertEqual(with: Self) {
        XCTAssertEqual(
            self.typeFields.count,
            with.typeFields.count,
            "Product \(self.location) type field counts do not match")
        zip(self.typeFields, with.typeFields).forEach {
            $0.assertEqual(with: $1)
        }
    }
}

extension Syntax.ChoiceType: Testable {
    func assertEqual(with: Self) {
        XCTAssertEqual(
            self.typeFields.count,
            with.typeFields.count,
            "Sum \(self.location) type field counts do not match")
        zip(self.typeFields, with.typeFields).forEach {
            $0.assertEqual(with: $1)
        }
    }
}

extension Syntax.TypeField: Testable {
    func assertEqual(
        with: Self
    ) {
        switch (self, with) {
        case let (.typeSpecifier(lhs), .typeSpecifier(rhs)):
            lhs.assertEqual(with: rhs)
        case let (.taggedTypeSpecifier(lhs), .taggedTypeSpecifier(rhs)):
            lhs.assertEqual(with: rhs)
        case let (.homogeneousTypeProduct(lhs), .homogeneousTypeProduct(rhs)):
            lhs.assertEqual(with: rhs)
        default:
            XCTFail("Type fields do not match")
        }
    }
}

extension Syntax.TaggedTypeSpecifier: Testable {
    func assertEqual(
        with: Self
    ) {
        XCTAssertEqual(self.tag, with.tag)
        self.typeSpecifier.assertEqual(with: with.typeSpecifier)
    }
}

extension Syntax.HomogeneousTypeProduct: Testable {
    func assertEqual(
        with: Self
    ) {
        self.typeSpecifier.assertEqual(with: with.typeSpecifier)
        self.count.assertEqual(with: with.count)
    }
}

extension Syntax.HomogeneousTypeProduct.Exponent: Testable {
    func assertEqual(
        with: Self
    ) {
        switch (self, with) {
        case let (.literal(lhs), .literal(rhs)):
            XCTAssertEqual(lhs, rhs)
        case let (.identifier(lhs), .identifier(rhs)):
            XCTAssertEqual(lhs, rhs)
        default:
            XCTFail("Homogeneous type product exponents do not match")
        }
    }
}

extension Syntax.Nominal: Testable {
    func assertEqual(
        with: Self
    ) {
        XCTAssertEqual(self.identifier, with.identifier)
        zip(self.typeArguments, with.typeArguments).forEach {
            $0.assertEqual(with: $1)
        }
    }
}

extension Syntax.Expression: Testable {
    func assertEqual(
        with: Self
    ) {
        switch (self, with) {
        case (.literal(let lhs), .literal(let rhs)):
            lhs.assertEqual(with: rhs)
        case (.unary(let lhs), .unary(let rhs)):
            lhs.assertEqual(with: rhs)
        case (.binary(let lhs), .binary(let rhs)):
            lhs.assertEqual(with: rhs)
        case (.nominal(let lhs), .nominal(let rhs)):
            lhs.assertEqual(with: rhs)
        case (.recordType(let lhs), .recordType(let rhs)):
            lhs.assertEqual(with: rhs)
        case (.choiceType(let lhs), .choiceType(let rhs)):
            lhs.assertEqual(with: rhs)
        case (.function(let lhs), .function(let rhs)):
            lhs.assertEqual(with: rhs)
        case (.call(let lhs), .call(let rhs)):
            lhs.assertEqual(with: rhs)
        case (.access(let lhs), .access(let rhs)):
            lhs.assertEqual(with: rhs)
        case (.binding(let lhs), .binding(let rhs)):
            lhs.assertEqual(with: rhs)
        case (.taggedExpression(let lhs), .taggedExpression(let rhs)):
            lhs.assertEqual(with: rhs)
        case (.branched(let lhs), .branched(let rhs)):
            lhs.assertEqual(with: rhs)
        case (.piped(let lhs), .piped(let rhs)):
            lhs.assertEqual(with: rhs)
        default:
            XCTFail("Expressions do not match")
        }
    }
}

extension Syntax.Literal: Testable {
    func assertEqual(
        with: Self
    ) {
        XCTAssertEqual(self.value, with.value)
    }
}

extension Syntax.Unary: Testable {
    func assertEqual(
        with: Self
    ) {
        XCTAssertEqual(self.op, with.op)
        self.expression.assertEqual(with: with.expression)
    }
}

extension Syntax.Binary: Testable {
    func assertEqual(
        with: Self
    ) {
        XCTAssertEqual(self.op, with.op)
        self.left.assertEqual(with: with.left)
        self.right.assertEqual(with: with.right)
    }
}

extension Syntax.Function {
    func assertEqual(
        with: Self
    ) {
        if let withSignature = with.signature {
            XCTAssertNotNil(self.signature)
            if let signature = self.signature {
                signature.assertEqual(with: withSignature)
            }
        } else {
            XCTAssertNil(self.signature)
        }
        self.body.assertEqual(with: with.body)
    }
}

extension Syntax.FunctionType {
    func assertEqual(
        with: Self
    ) {
        if let withInputType = with.inputType {
            XCTAssertNotNil(self.inputType)
            if let inputType = self.inputType {
                inputType.assertEqual(with: withInputType)
            }
        } else {
            XCTAssertNil(self.inputType)
        }

        XCTAssertEqual(self.arguments.count, with.arguments.count)

        zip(self.arguments, with.arguments).forEach {
            $0.assertEqual(with: $1)
        }

        self.outputType.assertEqual(with: with.outputType)
    }
}

extension Syntax.Call: Testable {
    func assertEqual(
        with: Self
    ) {
        self.prefix.assertEqual(with: with.prefix)

        XCTAssertEqual(self.arguments.count, with.arguments.count)

        zip(self.arguments, with.arguments).forEach {
            $0.assertEqual(with: $1)
        }
    }
}

extension Syntax.Access: Testable {
    func assertEqual(
        with: Self
    ) {
        self.prefix.assertEqual(with: with.prefix)
        XCTAssertEqual(self.field, with.field)
    }
}

extension Syntax.Binding: Testable {
    func assertEqual(
        with: Self
    ) {
        XCTAssertEqual(self.identifier, with.identifier)
    }
}

extension Syntax.TaggedExpression: Testable {
    func assertEqual(
        with: Self
    ) {
        XCTAssertEqual(self.tag, with.tag)
        self.expression.assertEqual(with: with.expression)
    }
}

extension Syntax.Branched: Testable {
    func assertEqual(
        with: Self
    ) {
        XCTAssertEqual(self.branches.count, with.branches.count)
        zip(self.branches, with.branches).forEach {
            $0.assertEqual(with: $1)
        }
    }
}

extension Syntax.Branched.Branch: Testable {
    func assertEqual(
        with: Self
    ) {
        self.matchExpression.assertEqual(with: with.matchExpression)

        if let withGuardExpression = with.guardExpression {
            XCTAssertNotNil(self.guardExpression)
            if let guardExpression = self.guardExpression {
                guardExpression.assertEqual(with: withGuardExpression)
            }
        } else {
            XCTAssertNil(self.guardExpression)
        }

        self.body.assertEqual(with: with.body)
    }
}

extension Syntax.Pipe: Testable {
    func assertEqual(
        with: Self
    ) {
        self.left.assertEqual(with: with.left)
        self.right.assertEqual(with: with.right)
    }
}

extension Syntax.QualifiedIdentifier {
    static func chain(
        _ components: [String]
    ) -> Syntax.QualifiedIdentifier {
        return .init(chain: components)
    }
}

extension Syntax.TypeSpecifier {
    static func record(
        _ typeFields: [Syntax.TypeField]
    ) -> Syntax.TypeSpecifier {
        return .recordType(
            .init(typeFields: typeFields))
    }

    static func choice(
        _ typeFields: [Syntax.TypeField]
    ) -> Syntax.TypeSpecifier {
        return .choiceType(
            .init(typeFields: typeFields))
    }

    static func nominalType(
        _ identifier: Syntax.QualifiedIdentifier
    ) -> Syntax.TypeSpecifier {
        return .nominal(.init(identifier: identifier))
    }
}

extension Syntax.TypeField {
    static func tagged(
        tag: String,
        typeSpecifier: Syntax.TypeSpecifier
    ) -> Syntax.TypeField {
        return .taggedTypeSpecifier(
            .init(tag: tag, typeSpecifier: typeSpecifier))
    }

    static func untagged(
        typeSpecifier: Syntax.TypeSpecifier
    ) -> Syntax.TypeField {
        return .typeSpecifier(typeSpecifier)
    }
}

extension Syntax.Expression {
    static let nothing: Syntax.Expression = .literal(.init(value: .nothing))
    static func binary(
        _ lhs: Syntax.Expression,
        _ op: Operator,
        _ rhs: Syntax.Expression
    ) -> Syntax.Expression {
        return .binary(
            .init(op: op, left: lhs, right: rhs)
        )
    }
}

final class ParserTests: XCTestCase {
    let fileNames: [String: Syntax.Module] = [
        // "types": .init(
        //     sourceName: "types",
        //     definitions: [
        //         .type(
        //             identifier: .chain(["Basic"]),
        //             typeSpecifier: .productType(
        //                 typeFields: [
        //                     .tagged(
        //                         tag: "a",
        //                         typeSpecifier: .nominalType(
        //                             identifier: .chain(["Int"])
        //                         )
        //                     )
        //                 ]
        //             )
        //         ),
        //         .type(
        //             identifier: .chain(["Multiple"]),
        //             typeSpecifier: .productType(
        //                 typeFields: [
        //                     .tagged(
        //                         tag: "a",
        //                         typeSpecifier: .nominalType(
        //                             identifier: .chain(["Int"])
        //                         )
        //                     ),
        //                     .tagged(
        //                         tag: "b",
        //                         typeSpecifier: .nominalType(
        //                             identifier: .chain(["Float"])
        //                         )
        //                     ),
        //                     .tagged(
        //                         tag: "c",
        //                         typeSpecifier: .nominalType(
        //                             identifier: .chain(["String"])
        //                         )
        //                     ),
        //                 ]
        //             )
        //         ),
        //         .type(
        //             identifier: .chain(["Nested"]),
        //             typeSpecifier: .productType(
        //                 typeFields: [
        //                     .tagged(
        //                         tag: "a",
        //                         typeSpecifier: .nominalType(
        //                             identifier: .chain(["Int"])
        //                         )
        //                     ),
        //                     .tagged(
        //                         tag: "d",
        //                         typeSpecifier: .productType(
        //                             typeFields: [
        //                                 .tagged(
        //                                     tag: "b",
        //                                     typeSpecifier: .nominalType(
        //                                         identifier: .chain(["Float"])
        //                                     )
        //                                 ),
        //                                 .tagged(
        //                                     tag: "e",
        //                                     typeSpecifier: .productType(
        //                                         typeFields: [
        //                                             .tagged(
        //                                                 tag: "c",
        //                                                 typeSpecifier:
        //                                                     .nominalType(
        //                                                         identifier:
        //                                                             .chain([
        //                                                                 "String"
        //                                                             ]
        //                                                             )
        //                                                     )
        //                                             )
        //                                         ]
        //                                     )
        //                                 ),
        //                             ]
        //                         )
        //                     ),
        //                 ]
        //             )
        //         ),
        //         .type(
        //             identifier: .chain(["Scoped", "Basic"]),
        //             typeSpecifier: .productType(
        //                 typeFields: [
        //                     .tagged(
        //                         tag: "a",
        //                         typeSpecifier: .nominalType(
        //                             identifier: .chain(["Int"])
        //                         )
        //                     )
        //                 ]
        //             )
        //         ),
        //         .type(
        //             identifier: .chain(["Scoped", "Multiple", "Times"]),
        //             typeSpecifier: .productType(
        //                 typeFields: [
        //                     .tagged(
        //                         tag: "a",
        //                         typeSpecifier: .nominalType(
        //                             identifier: .chain(["Int"])
        //                         )
        //                     ),
        //                     .tagged(
        //                         tag: "e",
        //                         typeSpecifier: .nominalType(
        //                             identifier: .chain(["Bool"])
        //                         )
        //                     ),
        //                 ]
        //             )
        //         ),
        //         .type(
        //             identifier: .chain(["ScopedTypes"]),
        //             typeSpecifier: .productType(
        //                 typeFields: [
        //                     .tagged(
        //                         tag: "x",
        //                         typeSpecifier: .nominalType(
        //                             identifier: .chain(["CG", "Float"])
        //                         )
        //                     ),
        //                     .tagged(
        //                         tag: "y",
        //                         typeSpecifier: .nominalType(
        //                             identifier: .chain(["CG", "Vector"])
        //                         )
        //                     ),
        //                 ]
        //             )
        //         ),
        //         .type(
        //             identifier: .chain(["TypeWithNothing"]),
        //             typeSpecifier: .productType(
        //                 typeFields: [
        //                     .tagged(
        //                         tag: "m",
        //                         typeSpecifier: .nothing(location: .nowhere)
        //                     ),
        //                     .tagged(
        //                         tag: "n",
        //                         typeSpecifier: .nothing(location: .nowhere)
        //                     ),
        //                 ]
        //             )
        //         ),
        //         .type(
        //             identifier: .chain(["Numbered"]),
        //             typeSpecifier: .productType(
        //                 typeFields: [
        //                     .tagged(
        //                         tag: "_1",
        //                         typeSpecifier: .nominalType(
        //                             identifier: .chain(["One"])
        //                         )
        //                     ),
        //                     .tagged(
        //                         tag: "_2",
        //                         typeSpecifier: .nominalType(
        //                             identifier: .chain(["Two"])
        //                         )
        //                     ),
        //                     .tagged(
        //                         tag: "_3",
        //                         typeSpecifier: .nominalType(
        //                             identifier: .chain(["Three"])
        //                         )
        //                     ),
        //                 ]
        //             )
        //         ),
        //         .type(
        //             identifier: .chain(["Tuple"]),
        //             typeSpecifier: .productType(
        //                 typeFields: [
        //                     .untagged(
        //                         typeSpecifier: .nominalType(
        //                             identifier: .chain(["Int"])
        //                         )
        //                     ),
        //                     .untagged(
        //                         typeSpecifier: .nominalType(
        //                             identifier: .chain(["Float"])
        //                         )
        //                     ),
        //                     .untagged(
        //                         typeSpecifier: .nominalType(
        //                             identifier: .chain(["String"])
        //                         )
        //                     ),
        //                     .untagged(
        //                         typeSpecifier: .nominalType(
        //                             identifier: .chain(["Bool"])
        //                         )
        //                     ),
        //                     .untagged(
        //                         typeSpecifier: .nominalType(
        //                             identifier: .chain(["Nested", "Scope"])
        //                         )
        //                     ),
        //                     .untagged(
        //                         typeSpecifier: .nominalType(
        //                             identifier: .chain([
        //                                 "Multiple",
        //                                 "Nested",
        //                                 "Scope",
        //                             ])
        //                         )
        //                     ),
        //                 ]
        //             )
        //         ),
        //         .type(
        //             identifier: .chain(["Mix"]),
        //             typeSpecifier: .productType(typeFields: [
        //                 .untagged(
        //                     typeSpecifier: .nominalType(
        //                         identifier: .chain(["Int"])
        //                     )
        //                 ),
        //                 .tagged(
        //                     tag: "named",
        //                     typeSpecifier: .nominalType(
        //                         identifier: .chain(["Int"])
        //                     )
        //                 ),
        //                 .untagged(
        //                     typeSpecifier: .nominalType(
        //                         identifier: .chain(["Float"])
        //                     )
        //                 ),
        //                 .tagged(
        //                     tag: "other",
        //                     typeSpecifier: .nominalType(
        //                         identifier: .chain(["Float"])
        //                     )
        //                 ),
        //
        //             ])
        //         ),
        //         .type(
        //             identifier: .chain(["Choice"]),
        //             typeSpecifier: .sumType(typeFields: [
        //                 .tagged(
        //                     tag: "first",
        //                     typeSpecifier: .nothing(location: .nowhere)),
        //                 .tagged(
        //                     tag: "second",
        //                     typeSpecifier: .nothing(location: .nowhere)),
        //                 .tagged(
        //                     tag: "third",
        //                     typeSpecifier: .nothing(location: .nowhere)),
        //             ])
        //         ),
        //         .type(
        //             identifier: .chain(["Shape"]),
        //             typeSpecifier: .sumType(typeFields: [
        //                 .tagged(
        //                     tag: "circle",
        //                     typeSpecifier: .productType(typeFields: [
        //                         .tagged(
        //                             tag: "radius",
        //                             typeSpecifier: .nominalType(
        //                                 identifier: .chain(["Float"])))
        //                     ])),
        //                 .tagged(
        //                     tag: "rectangle",
        //                     typeSpecifier: .productType(typeFields: [
        //                         .tagged(
        //                             tag: "width",
        //                             typeSpecifier: .nominalType(
        //                                 identifier: .chain(["Float"]))),
        //                         .tagged(
        //                             tag: "height",
        //                             typeSpecifier: .nominalType(
        //                                 identifier: .chain(["Float"]))),
        //                     ])),
        //                 .tagged(
        //                     tag: "triangle",
        //                     typeSpecifier: .productType(typeFields: [
        //                         .tagged(
        //                             tag: "base",
        //                             typeSpecifier: .nominalType(
        //                                 identifier: .chain(["Float"]))),
        //                         .tagged(
        //                             tag: "height",
        //                             typeSpecifier: .nominalType(
        //                                 identifier: .chain(["Float"]))),
        //                     ])),
        //             ])
        //         ),
        //         .type(
        //             identifier: .chain(["Graphix", "Color"]),
        //             typeSpecifier: .sumType(typeFields: [
        //                 .tagged(
        //                     tag: "rgb",
        //                     typeSpecifier: .productType(typeFields: [
        //                         .tagged(
        //                             tag: "red",
        //                             typeSpecifier: .nominalType(
        //                                 identifier: .chain(["Float"]))),
        //                         .tagged(
        //                             tag: "green",
        //                             typeSpecifier: .nominalType(
        //                                 identifier: .chain(["Float"]))),
        //                         .tagged(
        //                             tag: "blue",
        //                             typeSpecifier: .nominalType(
        //                                 identifier: .chain(["Float"]))),
        //                     ])),
        //                 .tagged(
        //                     tag: "named",
        //                     typeSpecifier: .nominalType(
        //                         identifier: .chain(["Graphix", "ColorName"]))
        //                 ),
        //                 .tagged(
        //                     tag: "hsv",
        //                     typeSpecifier: .productType(typeFields: [
        //                         .tagged(
        //                             tag: "hue",
        //                             typeSpecifier: .nominalType(
        //                                 identifier: .chain(["Float"]))),
        //                         .tagged(
        //                             tag: "saturation",
        //                             typeSpecifier: .nominalType(
        //                                 identifier: .chain(["Float"]))),
        //                         .tagged(
        //                             tag: "value",
        //                             typeSpecifier: .nominalType(
        //                                 identifier: .chain(["Float"]))),
        //                     ])),
        //             ])
        //         ),
        //         .type(
        //             identifier: .chain(["Union"]),
        //             typeSpecifier: .sumType(typeFields: [
        //                 .untagged(
        //                     typeSpecifier: .nominalType(
        //                         identifier: .chain(["Int"])
        //                     )
        //                 ),
        //                 .untagged(
        //                     typeSpecifier: .nominalType(
        //                         identifier: .chain(["Float"])
        //                     )
        //                 ),
        //                 .untagged(
        //                     typeSpecifier: .nominalType(
        //                         identifier: .chain(["String"])
        //                     )
        //                 ),
        //             ])
        //         ),
        //         .type(
        //             identifier: .chain(["Nested", "Stuff"]),
        //             typeSpecifier: .productType(
        //                 typeFields: [
        //                     .tagged(
        //                         tag: "first",
        //                         typeSpecifier: .sumType(
        //                             typeFields: [
        //                                 .untagged(
        //                                     typeSpecifier: .nominalType(
        //                                         identifier: .chain(["A"]))),
        //                                 .untagged(
        //                                     typeSpecifier: .nominalType(
        //                                         identifier: .chain(["B"]))),
        //                                 .untagged(
        //                                     typeSpecifier: .nominalType(
        //                                         identifier: .chain(["C"]))),
        //                             ]
        //                         )
        //                     ),
        //                     .tagged(
        //                         tag: "second",
        //                         typeSpecifier: .sumType(
        //                             typeFields: [
        //                                 .tagged(
        //                                     tag: "a",
        //                                     typeSpecifier: .nothing(
        //                                         location: .nowhere)),
        //                                 .tagged(
        //                                     tag: "b",
        //                                     typeSpecifier: .nothing(
        //                                         location: .nowhere)),
        //                                 .tagged(
        //                                     tag: "c",
        //                                     typeSpecifier: .nothing(
        //                                         location: .nowhere)),
        //                             ]
        //                         )
        //                     ),
        //                     .tagged(
        //                         tag: "mix",
        //                         typeSpecifier: .sumType(
        //                             typeFields: [
        //                                 .untagged(
        //                                     typeSpecifier: .nominalType(
        //                                         identifier: .chain(["First"]))),
        //                                 .tagged(
        //                                     tag: "second",
        //                                     typeSpecifier: .nominalType(
        //                                         identifier: .chain(["Second"]))),
        //                                 .tagged(
        //                                     tag: "third",
        //                                     typeSpecifier: .sumType(
        //                                         typeFields: [
        //                                             .tagged(
        //                                                 tag: "_1",
        //                                                 typeSpecifier: .nothing(
        //                                                     location: .nowhere)),
        //                                             .tagged(
        //                                                 tag: "_2",
        //                                                 typeSpecifier: .nothing(
        //                                                     location: .nowhere)),
        //                                             .tagged(
        //                                                 tag: "_3",
        //                                                 typeSpecifier: .nothing(
        //                                                     location: .nowhere)),
        //
        //                                         ]
        //                                     )
        //                                 ),
        //                             ]
        //                         )
        //                     ),
        //                 ]
        //             )
        //         ),
        //     ]
        // ),
        // "simpleexpressions": .init(
        //     sourceName: "expressions",
        //     definitions: [
        //         .value(identifier: .chain(["well"]), expression: .nothing),
        //         .value(
        //             identifier: .chain(["arithmetics"]),
        //             expression: .binary(
        //                 .intLiteral(1),
        //                 .minus,
        //                 .intLiteral(10)
        //             )
        //         ),
        //     ]
        // ),
        "errors": .init(
            sourceName: "errors", definitions: [])
    ]

    func testFiles() throws {
        let bundle = Bundle.module

        for (name, reference) in fileNames {
            let sourceUrl = bundle.url(
                forResource: "parser_\(name)",
                withExtension: "ppl")!
            let source = try Syntax.Source(url: sourceUrl)
            let module = TreeSitterModulParser().parseModule(source: source)
            module.assertEqual(with: reference)
        }
    }
}
