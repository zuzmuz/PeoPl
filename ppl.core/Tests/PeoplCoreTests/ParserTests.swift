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
        XCTAssertEqual(self.identifier, with.identifier)
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

final class ParserTests: XCTestCase {
    let fileNames = [
        "producttypes"
        // "error",
    ]

    func testFiles() throws {
        let bundle = Bundle.module

        for name in fileNames {
            let sourceUrl = bundle.url(forResource: name, withExtension: "ppl")!
            let jsonUrl = bundle.url(forResource: name, withExtension: "json")!
            let jsonData = try Data(contentsOf: jsonUrl)

            let reference = try JSONDecoder().decode(
                Syntax.Module.self, from: jsonData)

            let source = try Syntax.Module(url: sourceUrl)

            source.assertEqual(with: reference)
        }
    }
}
