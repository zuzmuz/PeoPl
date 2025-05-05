import Foundation

do {
    let module = try Syntax.Module(
        path: "/Users/zuz/Desktop/Muz/coding/peopl/examples/main.ppl")
    // var llvm = LLVM.Builder(name: "main")
    //
    // let semanticContext = try module.semanticCheck().get()
    // try semanticContext.llvmBuildStatement(llvm: &llvm)
    // // FIX: should parse all functions declarations before generating body IR
    // print("verifying \(llvm.verify())")
    // print(llvm.generate())
    // print(llvm.save(to: "/Users/zuz/Desktop/Muz/coding/peopl/examples/main.ll"))
    // // let jsonEncoder = JSONEncoder()
    // jsonEncoder.outputFormatting = .prettyPrinted
    // let project = Project(modules: ["main": module])
    // let evaluation = project.evaluate(with: .nothing, and: EvaluationScope(locals: [:]))
    //
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
