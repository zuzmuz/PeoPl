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
        indentifier: Syntax.ScopedIdentifier
    ) -> Syntax.TypeSpecifier {
        return .nominal(.init(identifier: indentifier))
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
                                    indentifier: .chain(["Int"])
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
