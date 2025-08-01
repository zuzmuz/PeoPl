import XCTest

@testable import Main

// MARK: - Testable Protocol

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
        if let withTypeSpecifier = with.typeSpecifier {
            XCTAssertNotNil(self.typeSpecifier)
            if let selfTypeSpecifier = self.typeSpecifier {
                selfTypeSpecifier.assertEqual(with: withTypeSpecifier)
            }
        } else {
            XCTAssertNil(self.typeSpecifier)
        }
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

extension Syntax.Function: Testable {
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

extension Syntax.FunctionType: Testable {
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

// MARK: - Syntax Util Extensions

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
        typeSpecifier: Syntax.TypeSpecifier?
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
    static func intLiteral(_ value: UInt64) -> Syntax.Expression {
        return .literal(.init(value: .intLiteral(value)))
    }
    static func floatLiteral(_ value: Double) -> Syntax.Expression {
        return .literal(.init(value: .floatLiteral(value)))
    }
    static func stringLiteral(_ value: String) -> Syntax.Expression {
        return .literal(.init(value: .stringLiteral(value)))
    }

    static func unary(
        _ op: Operator,
        _ expression: Syntax.Expression
    ) -> Syntax.Expression {
        return .unary(.init(op: op, expression: expression))
    }

    static func binary(
        _ lhs: Syntax.Expression,
        _ op: Operator,
        _ rhs: Syntax.Expression
    ) -> Syntax.Expression {
        return .binary(
            .init(op: op, left: lhs, right: rhs)
        )
    }

    static func record(
        _ typeFields: [Syntax.TypeField]
    ) -> Syntax.Expression {
        return .recordType(
            .init(typeFields: typeFields))
    }

    static func choice(
        _ typeFields: [Syntax.TypeField]
    ) -> Syntax.Expression {
        return .choiceType(
            .init(typeFields: typeFields))
    }

    static func nominal(
        _ identifier: Syntax.QualifiedIdentifier
    ) -> Syntax.Expression {
        return .nominal(.init(identifier: identifier))
    }

    static func call(
        _ identifier: Syntax.QualifiedIdentifier,
        _ arguments: [Syntax.Expression] = []
    ) -> Syntax.Expression {
        return .call(
            .init(
                prefix: .nominal(identifier),
                arguments: arguments))
    }
}

// swiftlint:disable:next type_body_length
final class ParserTests: XCTestCase {
    let fileNames: [String: Syntax.Module] = [
        "types": .init(
            sourceName: "types",
            definitions: [
                .init(
                    identifier: .chain(["Basic"]),
                    definition: .record(
                        [
                            .tagged(
                                tag: "a",
                                typeSpecifier: .nominalType(
                                    .chain(["Int"])
                                )
                            )
                        ]
                    )
                ),
                .init(
                    identifier: .chain(["Multiple"]),
                    definition: .record(
                        [
                            .tagged(
                                tag: "a",
                                typeSpecifier: .nominalType(
                                    .chain(["Int"])
                                )
                            ),
                            .tagged(
                                tag: "b",
                                typeSpecifier: .nominalType(
                                    .chain(["Float"])
                                )
                            ),
                            .tagged(
                                tag: "c",
                                typeSpecifier: .nominalType(
                                    .chain(["String"])
                                )
                            ),
                        ]
                    )
                ),
                .init(
                    identifier: .chain(["Nested"]),
                    definition: .record(
                        [
                            .tagged(
                                tag: "a",
                                typeSpecifier: .nominalType(
                                    .chain(["Int"])
                                )
                            ),
                            .tagged(
                                tag: "d",
                                typeSpecifier: .record(
                                    [
                                        .tagged(
                                            tag: "b",
                                            typeSpecifier: .nominalType(
                                                .chain(["Float"])
                                            )
                                        ),
                                        .tagged(
                                            tag: "e",
                                            typeSpecifier: .record(
                                                [
                                                    .tagged(
                                                        tag: "c",
                                                        typeSpecifier:
                                                            .nominalType(
                                                                .chain([
                                                                    "String"
                                                                ]
                                                                )
                                                            )
                                                    )
                                                ]
                                            )
                                        ),
                                    ]
                                )
                            ),
                        ]
                    )
                ),
                .init(
                    identifier: .chain(["Scoped", "Basic"]),
                    definition: .record(
                        [
                            .tagged(
                                tag: "a",
                                typeSpecifier: .nominalType(
                                    .chain(["Int"])
                                )
                            )
                        ]
                    )
                ),
                .init(
                    identifier: .chain(["Scoped", "Multiple", "Times"]),
                    definition: .record(
                        [
                            .tagged(
                                tag: "a",
                                typeSpecifier: .nominalType(
                                    .chain(["Int"])
                                )
                            ),
                            .tagged(
                                tag: "e",
                                typeSpecifier: .nominalType(
                                    .chain(["Bool"])
                                )
                            ),
                        ]
                    )
                ),
                .init(
                    identifier: .chain(["ScopedTypes"]),
                    definition: .record(
                        [
                            .tagged(
                                tag: "x",
                                typeSpecifier: .nominalType(
                                    .chain(["CG", "Float"])
                                )
                            ),
                            .tagged(
                                tag: "y",
                                typeSpecifier: .nominalType(
                                    .chain(["CG", "Vector"])
                                )
                            ),
                        ]
                    )
                ),
                .init(
                    identifier: .chain(["TypeWithNothing"]),
                    definition: .record(
                        [
                            .tagged(
                                tag: "m",
                                typeSpecifier: .nothing(location: .nowhere)
                            ),
                            .tagged(
                                tag: "n",
                                typeSpecifier: .nothing(location: .nowhere)
                            ),
                        ]
                    )
                ),
                .init(
                    identifier: .chain(["Numbered"]),
                    definition: .record(
                        [
                            .tagged(
                                tag: "_1",
                                typeSpecifier: .nominalType(
                                    .chain(["One"])
                                )
                            ),
                            .tagged(
                                tag: "_2",
                                typeSpecifier: .nominalType(
                                    .chain(["Two"])
                                )
                            ),
                            .tagged(
                                tag: "_3",
                                typeSpecifier: .nominalType(
                                    .chain(["Three"])
                                )
                            ),
                        ]
                    )
                ),
                .init(
                    identifier: .chain(["Tuple"]),
                    definition: .record(
                        [
                            .untagged(
                                typeSpecifier: .nominalType(
                                    .chain(["Int"])
                                )
                            ),
                            .untagged(
                                typeSpecifier: .nominalType(
                                    .chain(["Float"])
                                )
                            ),
                            .untagged(
                                typeSpecifier: .nominalType(
                                    .chain(["String"])
                                )
                            ),
                            .untagged(
                                typeSpecifier: .nominalType(
                                    .chain(["Bool"])
                                )
                            ),
                            .untagged(
                                typeSpecifier: .nominalType(
                                    .chain(["Nested", "Scope"])
                                )
                            ),
                            .untagged(
                                typeSpecifier: .nominalType(
                                    .chain([
                                        "Multiple",
                                        "Nested",
                                        "Scope",
                                    ])
                                )
                            ),
                        ]
                    )
                ),
                .init(
                    identifier: .chain(["Mix"]),
                    definition: .record([
                        .untagged(
                            typeSpecifier: .nominalType(
                                .chain(["Int"])
                            )
                        ),
                        .tagged(
                            tag: "named",
                            typeSpecifier: .nominalType(
                                .chain(["Int"])
                            )
                        ),
                        .untagged(
                            typeSpecifier: .nominalType(
                                .chain(["Float"])
                            )
                        ),
                        .tagged(
                            tag: "other",
                            typeSpecifier: .nominalType(
                                .chain(["Float"])
                            )
                        ),
                    ])
                ),
                .init(
                    identifier: .chain(["Choice"]),
                    definition: .choice([
                        .tagged(
                            tag: "first",
                            typeSpecifier: nil),
                        .tagged(
                            tag: "second",
                            typeSpecifier: nil),
                        .tagged(
                            tag: "third",
                            typeSpecifier: nil),
                    ])
                ),
                .init(
                    identifier: .chain(["Shape"]),
                    definition: .choice([
                        .tagged(
                            tag: "circle",
                            typeSpecifier: .record([
                                .tagged(
                                    tag: "radius",
                                    typeSpecifier: .nominalType(
                                        .chain(["Float"])))
                            ])),
                        .tagged(
                            tag: "rectangle",
                            typeSpecifier: .record([
                                .tagged(
                                    tag: "width",
                                    typeSpecifier: .nominalType(
                                        .chain(["Float"]))),
                                .tagged(
                                    tag: "height",
                                    typeSpecifier: .nominalType(
                                        .chain(["Float"]))),
                            ])),
                        .tagged(
                            tag: "triangle",
                            typeSpecifier: .record([
                                .tagged(
                                    tag: "base",
                                    typeSpecifier: .nominalType(
                                        .chain(["Float"]))),
                                .tagged(
                                    tag: "height",
                                    typeSpecifier: .nominalType(
                                        .chain(["Float"]))),
                            ])),
                    ])
                ),
                .init(
                    identifier: .chain(["Graphix", "Color"]),
                    definition: .choice([
                        .tagged(
                            tag: "rgb",
                            typeSpecifier: .record([
                                .tagged(
                                    tag: "red",
                                    typeSpecifier: .nominalType(
                                        .chain(["Float"]))),
                                .tagged(
                                    tag: "green",
                                    typeSpecifier: .nominalType(
                                        .chain(["Float"]))),
                                .tagged(
                                    tag: "blue",
                                    typeSpecifier: .nominalType(
                                        .chain(["Float"]))),
                            ])),
                        .tagged(
                            tag: "named",
                            typeSpecifier: .nominalType(
                                .chain(["Graphix", "ColorName"]))
                        ),
                        .tagged(
                            tag: "hsv",
                            typeSpecifier: .record([
                                .tagged(
                                    tag: "hue",
                                    typeSpecifier: .nominalType(
                                        .chain(["Float"]))),
                                .tagged(
                                    tag: "saturation",
                                    typeSpecifier: .nominalType(
                                        .chain(["Float"]))),
                                .tagged(
                                    tag: "value",
                                    typeSpecifier: .nominalType(
                                        .chain(["Float"]))),
                            ])),
                    ])
                ),
                .init(
                    identifier: .chain(["Union"]),
                    definition: .choice([
                        .untagged(
                            typeSpecifier: .nominalType(
                                .chain(["Int"])
                            )
                        ),
                        .untagged(
                            typeSpecifier: .nominalType(
                                .chain(["Float"])
                            )
                        ),
                        .untagged(
                            typeSpecifier: .nominalType(
                                .chain(["String"])
                            )
                        ),
                    ])
                ),
                .init(
                    identifier: .chain(["Nested", "Stuff"]),
                    definition: .record([
                        .tagged(
                            tag: "first",
                            typeSpecifier: .choice([
                                .untagged(
                                    typeSpecifier: .nominalType(
                                        .chain(["A"]))),
                                .untagged(
                                    typeSpecifier: .nominalType(
                                        .chain(["B"]))),
                                .untagged(
                                    typeSpecifier: .nominalType(
                                        .chain(["C"]))),
                            ])
                        ),
                        .tagged(
                            tag: "second",
                            typeSpecifier: .choice([
                                .tagged(
                                    tag: "a",
                                    typeSpecifier: nil,
                                ),
                                .tagged(
                                    tag: "b",
                                    typeSpecifier: nil,
                                ),
                                .tagged(
                                    tag: "c",
                                    typeSpecifier: nil,
                                )
                            ])
                        ),
                        .tagged(
                            tag: "mix",
                            typeSpecifier: .choice([
                                .untagged(
                                    typeSpecifier: .nominalType(
                                        .chain(["First"]))),
                                .tagged(
                                    tag: "second",
                                    typeSpecifier: .nominalType(
                                        .chain(["Second"]))),
                                .tagged(
                                    tag: "third",
                                    typeSpecifier: .choice([
                                        .tagged(
                                            tag: "_1",
                                            typeSpecifier: nil),
                                        .tagged(
                                            tag: "_2",
                                            typeSpecifier: nil),
                                        .tagged(
                                            tag: "_3",
                                            typeSpecifier: nil),

                                    ])
                                ),
                            ])
                        ),
                    ])
                ),
            ]
        ),
        "expressions": .init(
            sourceName: "expressions",
            definitions: [
                .init(identifier: .chain(["well"]), definition: .nothing),
                .init(
                    identifier: .chain(["hello"]),
                    definition: .stringLiteral("Hello, World!"),
                ),
                .init(
                    identifier: .chain(["arithmetics"]),
                    definition: .binary(
                        .binary(
                            .binary(
                                .binary(
                                    .intLiteral(1),
                                    .plus,
                                    .binary(
                                        .intLiteral(20),
                                        .times,
                                        .binary(
                                            .intLiteral(5),
                                            .minus,
                                            .intLiteral(2),
                                        )
                                    )
                                ),
                                .minus,
                                .binary(
                                    .binary(
                                        .intLiteral(3),
                                        .by,
                                        .intLiteral(1)
                                    ),
                                    .times,
                                    .intLiteral(3)
                                )
                            ),
                            .plus,
                            .binary(
                                .intLiteral(10),
                                .modulo,
                                .intLiteral(3)
                            )
                        ),
                        .minus,
                        .intLiteral(10)
                    )
                ),
                .init(
                    identifier: .chain(["hexOctBin"]),
                    definition: .binary(
                        .binary(
                            .intLiteral(255),
                            .plus,
                            .binary(
                                .intLiteral(240),
                                .times,
                                .intLiteral(7)
                            )
                        ),
                        .minus,
                        .intLiteral(56400)
                    )
                ),
                .init(
                    identifier: .chain(["big_numbers"]),
                    definition: .intLiteral(1000000000),
                ),
                .init(
                    identifier: .chain(["floating"]),
                    definition: .binary(
                        .floatLiteral(1.0),
                        .plus,
                        .binary(
                            .binary(
                                .floatLiteral(2.5),
                                .times,
                                .binary(
                                    .floatLiteral(3.14),
                                    .minus,
                                    .floatLiteral(1.0)
                                )
                            ),
                            .by,
                            .floatLiteral(2.0)
                        )
                    )
                ),
                .init(
                    identifier: .chain(["prefix"]),
                    definition: .binary(
                        .intLiteral(1),
                        .minus,
                        .unary(
                            .plus,
                            .unary(
                                .minus,
                                .intLiteral(5)
                            )
                        )
                    )
                ),
                .init(
                    identifier: .chain(["conditions"]),
                    definition: .binary(
                        .binary(
                            .nominal(.chain(["you"])),
                            .and,
                            .nominal(.chain(["me"])),
                        ),
                        .or,
                        .nothing
                    )
                ),
                .init(
                    identifier: .chain(["complex", "Conditions"]),
                    definition: .binary(
                        .binary(
                            .binary(
                                .binary(
                                    .intLiteral(1),
                                    .plus,
                                    .intLiteral(3),
                                ),
                                .times,
                                .intLiteral(3),
                            ),
                            .greaterThan,
                            .intLiteral(42),
                        ),
                        .or,
                        .binary(
                            .nominal(.chain(["something"])),
                            .and,
                            .binary(
                                .binary(
                                    .stringLiteral("this"),
                                    .equal,
                                    .stringLiteral("that"),
                                ),
                                .or,
                                .unary(
                                    .not,
                                    .call(.chain(["theSame"]))
                                )
                            )
                        ),
                    )
                )
            ]
        ),
        // "errors": .init(
        //     sourceName: "errors", definitions: [])
    ]

    func testFiles() throws {
        let bundle = Bundle.module

        for (name, reference) in fileNames {
            let sourceUrl = bundle.url(
                forResource: "parser_\(name)",
                withExtension: "ppl")!
            let source = try Syntax.Source(url: sourceUrl)
            let module = TreeSitterModulParser.parseModule(source: source)
            module.assertEqual(with: reference)
        }
    }
}
