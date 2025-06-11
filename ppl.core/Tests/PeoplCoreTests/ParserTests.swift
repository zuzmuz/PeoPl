import XCTest

@testable import PeoplCore

protocol Testable {
    func assertEqual(
        with: Self,
    )
}

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
        switch (self, with) {
        case let (.typeDefinition(lhs), .typeDefinition(rhs)):
            lhs.assertEqual(with: rhs)
        case let (.valueDefinition(lhs), .valueDefinition(rhs)):
            // lhs.assertEqual(with: rhs)
            XCTFail("Value definitions are not comparable yet")
        default:
            XCTFail("Definitions do not match")
        }
    }
}

extension Syntax.TypeDefinition: Testable {
    func assertEqual(
        with: Self
    ) {
        XCTAssertEqual(
            self.identifier,
            with.identifier,
            "Type definition identifier \(self.identifier) does not match \(with.identifier)"
        )
        self.typeSpecifier.assertEqual(with: with.typeSpecifier)
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
        case let (.product(lhs), .product(rhs)):
            lhs.assertEqual(with: rhs)
        case let (.nominal(lhs), .nominal(rhs)):
            lhs.assertEqual(with: rhs)
        default:
            XCTFail("Type specifiers do not match \(self) vs \(with)")
        }
    }
}

extension Syntax.Product: Testable {
    func assertEqual(
        with: Self
    ) {
        XCTAssertEqual(
            self.typeFields.count,
            with.typeFields.count,
            "Product \(self.location) type field counts do not match")
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

extension Syntax.Definition {
    static func type(
        identifier: Syntax.ScopedIdentifier,
        typeSpecifier: Syntax.TypeSpecifier
    ) -> Syntax.Definition {
        return .typeDefinition(
            .init(identifier: identifier, typeSpecifier: typeSpecifier))
    }
}

extension Syntax.ScopedIdentifier {
    static func chain(
        _ components: [String]
    ) -> Syntax.ScopedIdentifier {
        return .init(chain: components)
    }
}

extension Syntax.TypeSpecifier {
    static func productType(
        typeFields: [Syntax.TypeField]
    ) -> Syntax.TypeSpecifier {
        return .product(
            .init(typeFields: typeFields))
    }

    static func nominalType(
        identifier: Syntax.ScopedIdentifier
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

final class ParserTests: XCTestCase {
    let fileNames: [String: Syntax.Module] = [
        "producttypes": .init(
            sourceName: "producttypes",
            definitions: [
                .type(
                    identifier: .chain(["Basic"]),
                    typeSpecifier: .productType(
                        typeFields: [
                            .tagged(
                                tag: "a",
                                typeSpecifier: .nominalType(
                                    identifier: .chain(["Int"])
                                )
                            )
                        ]
                    )
                ),
                .type(
                    identifier: .chain(["Multiple"]),
                    typeSpecifier: .productType(
                        typeFields: [
                            .tagged(
                                tag: "a",
                                typeSpecifier: .nominalType(
                                    identifier: .chain(["Int"])
                                )
                            ),
                            .tagged(
                                tag: "b",
                                typeSpecifier: .nominalType(
                                    identifier: .chain(["Float"])
                                )
                            ),
                            .tagged(
                                tag: "c",
                                typeSpecifier: .nominalType(
                                    identifier: .chain(["String"])
                                )
                            ),
                        ]
                    )
                ),
                .type(
                    identifier: .chain(["Nested"]),
                    typeSpecifier: .productType(
                        typeFields: [
                            .tagged(
                                tag: "a",
                                typeSpecifier: .nominalType(
                                    identifier: .chain(["Int"])
                                )
                            ),
                            .tagged(
                                tag: "d",
                                typeSpecifier: .productType(
                                    typeFields: [
                                        .tagged(
                                            tag: "b",
                                            typeSpecifier: .nominalType(
                                                identifier: .chain(["Float"])
                                            )
                                        ),
                                        .tagged(
                                            tag: "e",
                                            typeSpecifier: .productType(
                                                typeFields: [
                                                    .tagged(
                                                        tag: "c",
                                                        typeSpecifier:
                                                            .nominalType(
                                                                identifier:
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
                .type(
                    identifier: .chain(["Scoped", "Basic"]),
                    typeSpecifier: .productType(
                        typeFields: [
                            .tagged(
                                tag: "a",
                                typeSpecifier: .nominalType(
                                    identifier: .chain(["Int"])
                                )
                            )
                        ]
                    )
                ),
                .type(
                    identifier: .chain(["Scoped", "Multiple", "Times"]),
                    typeSpecifier: .productType(
                        typeFields: [
                            .tagged(
                                tag: "a",
                                typeSpecifier: .nominalType(
                                    identifier: .chain(["Int"])
                                )
                            ),
                            .tagged(
                                tag: "e",
                                typeSpecifier: .nominalType(
                                    identifier: .chain(["Bool"])
                                )
                            ),
                        ]
                    )
                ),
                .type(
                    identifier: .chain(["ScopedTypes"]),
                    typeSpecifier: .productType(
                        typeFields: [
                            .tagged(
                                tag: "x",
                                typeSpecifier: .nominalType(
                                    identifier: .chain(["CG", "Float"])
                                )
                            ),
                            .tagged(
                                tag: "y",
                                typeSpecifier: .nominalType(
                                    identifier: .chain(["CG", "Vector"])
                                )
                            ),
                        ]
                    )
                ),
                .type(
                    identifier: .chain(["TypeWithNothing"]),
                    typeSpecifier: .productType(
                        typeFields: [
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
                .type(
                    identifier: .chain(["Numbered"]),
                    typeSpecifier: .productType(
                        typeFields: [
                            .tagged(
                                tag: "_1",
                                typeSpecifier: .nominalType(
                                    identifier: .chain(["One"])
                                )
                            ),
                            .tagged(
                                tag: "_2",
                                typeSpecifier: .nominalType(
                                    identifier: .chain(["Two"])
                                )
                            ),
                            .tagged(
                                tag: "_3",
                                typeSpecifier: .nominalType(
                                    identifier: .chain(["Three"])
                                )
                            ),
                        ]
                    )
                ),
                .type(
                    identifier: .chain(["Tuple"]),
                    typeSpecifier: .productType(
                        typeFields: [
                            .untagged(
                                typeSpecifier: .nominalType(
                                    identifier: .chain(["Int"])
                                )
                            ),
                            .untagged(
                                typeSpecifier: .nominalType(
                                    identifier: .chain(["Float"])
                                )
                            ),
                            .untagged(
                                typeSpecifier: .nominalType(
                                    identifier: .chain(["String"])
                                )
                            ),
                            .untagged(
                                typeSpecifier: .nominalType(
                                    identifier: .chain(["Bool"])
                                )
                            ),
                            .untagged(
                                typeSpecifier: .nominalType(
                                    identifier: .chain(["Nested", "Scope"])
                                )
                            ),
                            .untagged(
                                typeSpecifier: .nominalType(
                                    identifier: .chain([
                                        "Multiple",
                                        "Nested",
                                        "Scope"]
                                    )
                                )
                            )
                        ]
                    )
                )
            ]
        )
    ]

    func testFiles() throws {
        let bundle = Bundle.module

        for (name, reference) in fileNames {
            let sourceUrl = bundle.url(forResource: name, withExtension: "ppl")!
            let source = try Syntax.Module(url: sourceUrl)
            source.assertEqual(with: reference)
        }
    }
}
