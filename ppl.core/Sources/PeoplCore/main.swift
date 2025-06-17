import Foundation

do {
    let module = try Syntax.Module(
        source: """
            other: (Int) -> Bool {
                > 1
            }

            main: (Int) -> Bool {
                + 4
                |> - 2
                |> other()
                |> and true
            }
            """,
        path: "main")

    let result = module.semanticCheck()

    switch result {
    case let .success(context):
        print(context.display())
    case let .failure(error):
        print("Semantic check failed with errors: \(error.errors)")
    }

} catch {
    print("we catching \(error)")
}
