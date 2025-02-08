import Foundation

do {
    let source = """
            func factorial(of: I32) => I32
                of |>
                |value <= 1| 1,
                |value| value*factorial(of: value-1)

            func (I32) main() => I32
                |i| factorial(of: i)
        """
    let module = try Module(source: source, path: "main")
    let project = Project(modules: ["main": module])
    let scope = EvaluationScope()
    project.evaluate(with: .int(5), and: scope)

} catch {
    print("we catching \(error.localizedDescription)")
}
