import XCTest

@testable import Main

extension Semantic.Error: Testable {
    func assertEqual(
        with: Self
    ) {
        switch self {
        case .bindingMismatch(let expression):
            break
        case .bindingNotAllowed(let expression):
            break
        case .consecutiveUnary(let expression):
            break
        case .cyclicType(let type, let cyclicType):
            break
        case .duplicateFieldName(let field):
            break
        case .duplicatedExpressionFieldName(let expression):
            break
        case .guardShouldReturnBool(let expression):
            break
        case .homogeneousTypeProductInSum(let field):
            break
        case .inputMismatch(let expression, let expected, let received):
            break
        case .invalidOperation(let expression, let leftType, let rightType):
            break
        case .notImplemented(_, let location):
            break
        case .taggedTypeSpecifierRequired:
            break
        case .typeNotInScope(let type):
            break
        case .typeRedeclaration(let types):
            break
        case .undefinedCall(let expression):
            break
        case .undefinedField(let expression, let field):
            break
        case .undefinedType(let expression, let identifier):
            break
        case .valueRedeclaration(let values):
            break
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

final class TypeResoltionTests: XCTestCase {
    let fileNames:
        [String: (
            typeDeclarations: Semantic.TypeDeclarationsMap,
            typeErrors: [Semantic.Error]
        )] = [
            "goodtypes": (
                [
                    .chain(["simple"]): .raw(.record([
                        .named("a"): .nominal(.chain(["Int"])),
                        .named("b"): .nominal(.chain(["Float"])),
                    ])),
                    .chain(["enum"]): .raw(.choice([
                        .named("first"): .nothing,
                        .named("second"): .nothing,
                        .named("third"): .nothing
                    ])),
                    .chain(["Shape"]): .raw(.choice([
                        .named("circle"): .raw(.record([
                            .named("radius"): .nominal(.chain(["Float"]))
                        ])),
                        .named("rectangle"): .raw(.record([
                            .named("width"): .nominal(.chain(["Float"])),
                            .named("height"): .nominal(.chain(["Float"])),
                        ])),
                        .named("triangle"): .raw(.record([
                            .named("base"): .nominal(.chain(["Float"])),
                            .named("height"): .nominal(.chain(["Float"])),
                        ])),
                    ])),
                    .chain(["Point"]): .raw(.record([
                        .unnamed(0): .nominal(.chain(["Float"])),
                        .unnamed(1): .nominal(.chain(["Float"])),
                    ])),
                    .chain(["Circle"]): .raw(.record([
                        .named("center"): .nominal(.chain(["Point"])),
                        .named("radius"): .nominal(.chain(["Float"])),
                    ])),
                    .chain(["Rectangle"]): .raw(.record([
                        .named("topLeft"): .nominal(.chain(["Point"])),
                        .named("width"): .nominal(.chain(["Float"])),
                        .named("height"): .nominal(.chain(["Float"])),
                    ])),
                    .chain(["Triangle"]): .raw(.record([
                        .named("pointA"): .nominal(.chain(["Point"])),
                        .named("pointB"): .nominal(.chain(["Point"])),
                        .named("pointC"): .nominal(.chain(["Point"])),
                    ])),
                    .chain(["Geometry", "Shape"]): .raw(.choice([
                        .named("circle"): .nominal(.chain(["Circle"])),
                        .named("rectangle"): .nominal(.chain(["Rectangle"])),
                        .named("triangle"): .nominal(.chain(["Triangle"]))
                    ])),
                ],
                []
            )
        ]

    func testFiles() throws {

        let bundle = Bundle.module
        let intrinsicDeclarations = Semantic.getIntrinsicDeclarations()

        for (name, reference) in fileNames {
            let sourceUrl = bundle.url(
                forResource: "analyzer_\(name)",
                withExtension: "ppl")!
            let source = try Syntax.Source(url: sourceUrl)
            let module = TreeSitterModulParser.parseModule(source: source)
            let (typeDeclarations, _, typeErrors) =
                module.resolveTypeSymbols(
                    contextTypeDeclarations: intrinsicDeclarations
                        .typeDeclarations)
            XCTAssertEqual(typeErrors.count, reference.typeErrors.count)
            zip(typeErrors, reference.typeErrors).forEach {
                $0.assertEqual(with: $1)
            }
            XCTAssertEqual(
                typeDeclarations.count,
                reference.typeDeclarations.count)
            for (identifier, typeSpecifier) in typeDeclarations {
                XCTAssertNotNil(reference.typeDeclarations[identifier])
                if let referenceTypeSpecifier =
                    reference.typeDeclarations[identifier]
                {
                    XCTAssertEqual(typeSpecifier, referenceTypeSpecifier)
                }
            }
        }
    }
}
