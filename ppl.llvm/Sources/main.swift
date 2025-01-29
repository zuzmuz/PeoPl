import Foundation

do {
    let project = try Project(path: "../examples/main.ppl")
    let jsonEncoder = JSONEncoder()
    jsonEncoder.outputFormatting = .prettyPrinted
    let encoded = try jsonEncoder.encode(project.statements)
    print("project \(project.main)")
    // print(String(data: encoded, encoding: .utf8) ?? "")
} catch {
    print("we catching \(error.localizedDescription)")
}
