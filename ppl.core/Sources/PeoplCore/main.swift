import Foundation

do {
    let module = try Syntax.Module(
        source: """
            main: () -> Int {
                42
            }
            """,
        path: "main")

    let result = module.semanticCheck()

    switch result {
    case let .success(context):
        print(context)
    case let .failure(error):
        print("Semantic check failed with errors: \(error.errors)")
    }

} catch {
    print("we catching \(error)")
}
