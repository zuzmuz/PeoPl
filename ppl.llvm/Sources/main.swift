import Foundation


let syntaxTree = try SyntaxTree(path: "../examples/capturing_branching_looping.ppl")
let jsonEncoder = JSONEncoder()
jsonEncoder.outputFormatting = .prettyPrinted
let encoded = try jsonEncoder.encode(syntaxTree.statements)
print(String(data: encoded, encoding: .utf8) ?? "")
