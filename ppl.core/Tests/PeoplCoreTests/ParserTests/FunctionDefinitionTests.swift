import XCTest

@testable import PeoplCore

final class SignatureTests: XCTestCase {
    var jsonEncoder: JSONEncoder!
    override func setUpWithError() throws {
        self.jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
    }


    func testSimple() throws {
        let source = """
            func main() => Nothing
                Nothing..
        """
        let parseTree = ""

        let project = try Project(source: source, path: "main")

        let encoded = try jsonEncoder.encode(project.statements)
        print(String(data: encoded, encoding: .utf8) ?? "")
    }
}
