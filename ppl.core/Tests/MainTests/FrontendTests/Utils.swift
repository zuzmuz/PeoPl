import XCTest

@testable import Main

protocol Testable {
	func assertEqual(
		with: Self
	)
}

#if ANALYZER
extension Semantic.Error: Testable {
	func assertEqual(
		with: Self
	) {
		switch (errorChoice, with.errorChoice) {
		case (
			.typeRedeclaration(let selfIdentifier, let selfTypes),
			.typeRedeclaration(let withIdentifier, let withTypes)
		):
			XCTAssertEqual(selfIdentifier, withIdentifier)
			XCTAssertEqual(selfTypes.count, withTypes.count)
		case (
			.cyclicType(let selfStack),
			.cyclicType(let withStack)
		):
			XCTAssertEqual(selfStack.count, withStack.count)
		case (
			.functionRedeclaration(let selfSignature, let selfLocations),
			.functionRedeclaration(let withSignature, let withLocations)
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


#endif
