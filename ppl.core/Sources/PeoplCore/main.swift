import Foundation

do {
    let project = try Project(path: "/Users/zuz/Desktop/Muz/coding/simpl/examples/main.ppl")
    let jsonEncoder = JSONEncoder()
    jsonEncoder.outputFormatting = .prettyPrinted
    // let evaluation = project.evaluate(with: .nothing, and: [:])
    // let encoded = switch evaluation {
    // case let .success(expression):
    //     try jsonEncoder.encode(expression)
    // case let .failure(error):
    //     try jsonEncoder.encode(error)
    // }
    // print(String(data: encoded, encoding: .utf8) ?? "")

} catch {
    print("we catching \(error.localizedDescription)")
}
