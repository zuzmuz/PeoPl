// The Swift Programming Language
// https://docs.swift.org/swift-book

import LLVM

// AST Nodes matching your grammar
enum ASTNode {
    case literal(value: String)
    case identifier(name: String)
    case pipeExpression(left: ASTNode, right: CallNode)
    case call(CallNode)
}

struct CallNode {
    let functionName: String
    let parameters: [(name: String, value: ASTNode)]
}

// LLVM Code Generator
class CodeGenerator {
    private let module: Module
    private let builder: IRBuilder
    private let context: Context
    
    init(moduleName: String) {
        context = Context()
        module = Module(name: moduleName, context: context)
        builder = IRBuilder(context: context)
    }
    
    func compile(_ node: ASTNode) throws -> IRValue {
        switch node {
        case .literal(let value):
            if let intValue = Int32(value) {
                return context.int32(intValue)
            }
            // Add float/string handling as needed
            fatalError("Unsupported literal type")
            
        case .identifier(let name):
            guard let value = module.globalVariable(named: name) else {
                throw CompilerError.undefinedVariable(name)
            }
            return builder.buildLoad(value, type: value.type.pointee)
            
        case .pipeExpression(let left, let right):
            let leftValue = try compile(left)
            return try compileCall(right, withPipeInput: leftValue)
            
        case .call(let callNode):
            return try compileCall(callNode)
        }
    }
    
    private func compileCall(_ call: CallNode, withPipeInput: IRValue? = nil) throws -> IRValue {
        guard let function = module.function(named: call.functionName) else {
            throw CompilerError.undefinedFunction(call.functionName)
        }
        
        var args: [IRValue] = []
        if let pipeInput = withPipeInput {
            args.append(pipeInput)
        }
        
        for param in call.parameters {
            let paramValue = try compile(param.value)
            args.append(paramValue)
        }
        
        return builder.buildCall(function, args: args)
    }
    
    // Function to create a new function definition
    func createFunction(name: String, paramTypes: [IRType], returnType: IRType) -> Function {
        let functionType = FunctionType(argTypes: paramTypes, returnType: returnType)
        let function = builder.addFunction(name, type: functionType, to: module)
        let entry = function.appendBasicBlock(named: "entry")
        builder.positionAtEnd(of: entry)
        return function
    }
}

enum CompilerError: Error {
    case undefinedVariable(String)
    case undefinedFunction(String)
    case typeMismatch(String)
}

// Example usage:
let generator = CodeGenerator(moduleName: "example")

// Create a simple function that adds numbers
let addFunc = generator.createFunction(
    name: "add",
    paramTypes: [IntType.int32, IntType.int32],
    returnType: IntType.int32
)

// Example of compiling an expression: 5 |> add x: 3
let expr: ASTNode = .pipeExpression(
    left: .literal(value: "5"),
    right: CallNode(
        functionName: "add",
        parameters: [("x", .literal(value: "3"))]
    )
)

do {
    let result = try generator.compile(expr)
    // Add verification and optimization passes here
    print(module.description)
} catch {
    print("Compilation error: \(error)")
}
