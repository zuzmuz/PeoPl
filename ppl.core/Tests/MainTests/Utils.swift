import XCTest

@testable import Main

protocol Testable {
    func assertEqual(
        with: Self
    )
}

extension Semantic.Error: Testable {
    func assertEqual(
        with: Self
    ) {
        switch (self.errorChoice, with.errorChoice) {
        case let (
            .typeRedeclaration(selfIdentifier, selfTypes),
            .typeRedeclaration(withIdentifier, withTypes)
        ):
            XCTAssertEqual(selfIdentifier, withIdentifier)
            XCTAssertEqual(selfTypes.count, withTypes.count)
        case let (
            .cyclicType(selfStack),
            .cyclicType(withStack)
        ):
            XCTAssertEqual(selfStack.count, withStack.count)
        case let (
            .functionRedeclaration(selfSignature, selfLocations),
            .functionRedeclaration(withSignature, withLocations)
        ):
            XCTAssertEqual(selfSignature, withSignature)
            XCTAssertEqual(selfLocations.count, withLocations.count)
        default:
            XCTFail("Not Implemented for \(self) vs \(with)")
        }
    }
}

extension Semantic.QualifiedIdentifier {
    static func chain(
        _ components: [String]
    ) -> Semantic.QualifiedIdentifier {
        return .init(chain: components)
    }
}
