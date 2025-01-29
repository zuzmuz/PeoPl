import Foundation


let syntaxTree = try SyntaxTree(path: "../examples/compound_expressions.ppl")
let jsonEncoder = JSONEncoder()
jsonEncoder.outputFormatting = .prettyPrinted
let encoded = try jsonEncoder.encode(syntaxTree.statements)
print(String(data: encoded, encoding: .utf8) ?? "")
