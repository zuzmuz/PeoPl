import XCTest
@testable import PeoplCore

final class FunctionDefinitionTests: XCTestCase {

    func testSimple() throws {
        let source = """
            func main() => Nothing
                Nothing
        """
        let module = try Module(source: source, path: "main")
        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(functionDefinition.functionIdentifier.name, "main")
        XCTAssertEqual(functionDefinition.inputType, TypeIdentifier.nothing(location: .nowhere))
        XCTAssertEqual(functionDefinition.functionIdentifier.scope, nil)
        XCTAssertEqual(functionDefinition.params.count, 0)
        XCTAssertEqual(functionDefinition.outputType, TypeIdentifier.nothing(location: .nowhere))
    }

    func testScoped1() throws {
        let source = """
            func Scope.main() => Nothing
                Nothing
        """
        let module = try Module(source: source, path: "main")
        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(functionDefinition.functionIdentifier.name, "main")
        XCTAssertEqual(functionDefinition.inputType, TypeIdentifier.nothing(location: .nowhere))
        XCTAssertNotEqual(functionDefinition.functionIdentifier.scope, nil)
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain.count, 1)
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[0].typeName, "Scope")
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[0].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.params.count, 0)
        XCTAssertEqual(functionDefinition.outputType, TypeIdentifier.nothing(location: .nowhere))
    }

    func testScoped2() throws {
        let source = """
            func Scope1::Scope2.main() => Nothing
                Nothing
        """
        let module = try Module(source: source, path: "main")
        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(functionDefinition.functionIdentifier.name, "main")
        XCTAssertEqual(functionDefinition.inputType, TypeIdentifier.nothing(location: .nowhere))
        XCTAssertNotEqual(functionDefinition.functionIdentifier.scope, nil)
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain.count, 2)
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[0].typeName, "Scope1")
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[0].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[1].typeName, "Scope2")
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[1].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.params.count, 0)
        XCTAssertEqual(functionDefinition.outputType, TypeIdentifier.nothing(location: .nowhere))
    }

    func testScoped10() throws {
        let source = """
            func Scope1::Scope2::Scope3::Scope4::Scope5::Scope6::Scope7::Scope8::Scope9::Scope10.main() => Nothing
                Nothing
        """
        let module = try Module(source: source, path: "main")
        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(functionDefinition.functionIdentifier.name, "main")
        XCTAssertEqual(functionDefinition.inputType, TypeIdentifier.nothing(location: .nowhere))
        XCTAssertNotEqual(functionDefinition.functionIdentifier.scope, nil)
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain.count, 10)
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[0].typeName, "Scope1")
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[0].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[1].typeName, "Scope2")
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[1].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[2].typeName, "Scope3")
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[2].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[3].typeName, "Scope4")
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[3].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[4].typeName, "Scope5")
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[4].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[5].typeName, "Scope6")
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[5].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[6].typeName, "Scope7")
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[6].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[7].typeName, "Scope8")
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[7].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[8].typeName, "Scope9")
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[8].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[9].typeName, "Scope10")
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[9].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.params.count, 0)
        XCTAssertEqual(functionDefinition.outputType, TypeIdentifier.nothing(location: .nowhere))
    }

    func testInput() throws {
        let source = """
            func (Input) Scope.main() => Nothing
                Nothing
        """
        let module = try Module(source: source, path: "main")
        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(functionDefinition.functionIdentifier.name, "main")
        guard case let .nominal(inputType) = functionDefinition.inputType else {
            XCTAssertTrue(false)
            return
        }
        XCTAssertEqual(inputType.chain.count, 1)
        XCTAssertEqual(inputType.chain[0].typeName, "Input")
        XCTAssertEqual(inputType.chain[0].typeArguments.count, 0)
        XCTAssertNotEqual(functionDefinition.functionIdentifier.scope, nil)
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain.count, 1)
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[0].typeName, "Scope")
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[0].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.params.count, 0)
        XCTAssertEqual(functionDefinition.outputType, TypeIdentifier.nothing(location: .nowhere))
    }

    func testNestedInput() throws {
        let source = """
            func (Nested::Input) Scope.main() => Nothing
                Nothing
        """
        let module = try Module(source: source, path: "main")
        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(functionDefinition.functionIdentifier.name, "main")
        guard case let .nominal(inputType) = functionDefinition.inputType else {
            XCTAssertTrue(false)
            return
        }
        XCTAssertEqual(inputType.chain.count, 2)
        XCTAssertEqual(inputType.chain[0].typeName, "Nested")
        XCTAssertEqual(inputType.chain[0].typeArguments.count, 0)
        XCTAssertEqual(inputType.chain[1].typeName, "Input")
        XCTAssertEqual(inputType.chain[1].typeArguments.count, 0)
        XCTAssertNotEqual(functionDefinition.functionIdentifier.scope, nil)
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain.count, 1)
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[0].typeName, "Scope")
        XCTAssertEqual(functionDefinition.functionIdentifier.scope!.chain[0].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.params.count, 0)
        XCTAssertEqual(functionDefinition.outputType, TypeIdentifier.nothing(location: .nowhere))
    }

    func testTuplesAsInputAndOutput() throws {
        let source = """
            func ([A, B, C, D]) Scope.main() => [E, F]
                Nothing
        """
        let module = try Module(source: source, path: "main")
        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(functionDefinition.functionIdentifier.name, "main")
        guard case let .unnamedTuple(inputType) = functionDefinition.inputType else {
            XCTAssertTrue(false)
            return
        }
        XCTAssertEqual(inputType.types.count, 4)
        guard case let .nominal(type1) = inputType.types[0],
              case let .nominal(type2) = inputType.types[1],
              case let .nominal(type3) = inputType.types[2],
              case let .nominal(type4) = inputType.types[3] else {
            XCTAssertTrue(false)
            return
        }
        XCTAssertEqual(type1.chain[0].typeName, "A")
        XCTAssertEqual(type2.chain[0].typeName, "B")
        XCTAssertEqual(type3.chain[0].typeName, "C")
        XCTAssertEqual(type4.chain[0].typeName, "D")

        guard case let .unnamedTuple(outputType) = functionDefinition.outputType else {
            XCTAssertTrue(false)
            return
        }
        XCTAssertEqual(outputType.types.count, 2)
        guard case let .nominal(type1) = outputType.types[0],
              case let .nominal(type2) = outputType.types[1] else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(type1.chain[0].typeName, "E")
        XCTAssertEqual(type2.chain[0].typeName, "F")
    }

    func testTuplesAsInputAndOutputScoped() throws {
        let source = """
            func ([A::Z, B::Y::X]) Scope.main() => [E::W, F::V::U]
                Nothing
        """
        let module = try Module(source: source, path: "main")
        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(functionDefinition.functionIdentifier.name, "main")
        guard case let .unnamedTuple(inputType) = functionDefinition.inputType else {
            XCTAssertTrue(false)
            return
        }
        XCTAssertEqual(inputType.types.count, 2)
        guard case let .nominal(type1) = inputType.types[0],
              case let .nominal(type2) = inputType.types[1] else {
            XCTAssertTrue(false)
            return
        }
        XCTAssertEqual(type1.chain[0].typeName, "A")
        XCTAssertEqual(type1.chain[1].typeName, "Z")
        XCTAssertEqual(type2.chain[0].typeName, "B")
        XCTAssertEqual(type2.chain[1].typeName, "Y")
        XCTAssertEqual(type2.chain[2].typeName, "X")

        guard case let .unnamedTuple(outputType) = functionDefinition.outputType else {
            XCTAssertTrue(false)
            return
        }
        XCTAssertEqual(outputType.types.count, 2)
        guard case let .nominal(type1) = outputType.types[0],
              case let .nominal(type2) = outputType.types[1] else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(type1.chain[0].typeName, "E")
        XCTAssertEqual(type1.chain[1].typeName, "W")
        XCTAssertEqual(type2.chain[0].typeName, "F")
        XCTAssertEqual(type2.chain[1].typeName, "V")
        XCTAssertEqual(type2.chain[2].typeName, "U")
    }

    func testGenericsInput() throws {
        let source = """
            func (A::B<C>) Scope.main() => D<E, F, G>
                Nothing
        """
        let module = try Module(source: source, path: "main")
        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(functionDefinition.functionIdentifier.name, "main")
        guard case let .nominal(inputType) = functionDefinition.inputType else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(inputType.chain.count, 2)
        XCTAssertEqual(inputType.chain[0].typeName, "A")
        XCTAssertEqual(inputType.chain[0].typeArguments.count, 0)
        XCTAssertEqual(inputType.chain[1].typeName, "B")
        XCTAssertEqual(inputType.chain[1].typeArguments.count, 1)
        guard case let .nominal(genericType) = inputType.chain[1].typeArguments[0] else {
            XCTAssertTrue(false)
            return
        }
        XCTAssertEqual(genericType.chain[0].typeName, "C")

        guard case let .nominal(outputType) = functionDefinition.outputType else {
            XCTAssertTrue(false)
            return
        }
        XCTAssertEqual(outputType.chain.count, 1)
        XCTAssertEqual(outputType.chain[0].typeName, "D")
        XCTAssertEqual(outputType.chain[0].typeArguments.count, 3)
        guard case let .nominal(genericType1) = outputType.chain[0].typeArguments[0],
              case let .nominal(genericType2) = outputType.chain[0].typeArguments[1],
              case let .nominal(genericType3) = outputType.chain[0].typeArguments[2] else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(genericType1.chain[0].typeName, "E")
        XCTAssertEqual(genericType2.chain[0].typeName, "F")
        XCTAssertEqual(genericType3.chain[0].typeName, "G")
    }

    func testComplicatedGeneric() throws {
        let source = """
            func (A::B<[C::D<E>, F], G::H<I, [J, K]>>) Scope.main() => [L::M<N, O, [P, Q]>]
                Nothing
        """
        let module = try Module(source: source, path: "main")
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        guard case let .nominal(inputType) = functionDefinition.inputType else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(inputType.chain.count, 2)
        XCTAssertEqual(inputType.chain[0].typeName, "A")
        XCTAssertEqual(inputType.chain[0].typeArguments.count, 0)
        XCTAssertEqual(inputType.chain[1].typeName, "B")
        XCTAssertEqual(inputType.chain[1].typeArguments.count, 2)
        guard case let .unnamedTuple(genericType1) = inputType.chain[1].typeArguments[0],
              case let .nominal(genericType2) = inputType.chain[1].typeArguments[1] else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(genericType1.types.count, 2)
        guard case let .nominal(type1) = genericType1.types[0],
              case let .nominal(type2) = genericType1.types[1] else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(type1.chain.count, 2)
        XCTAssertEqual(type1.chain[0].typeName, "C")
        XCTAssertEqual(type1.chain[1].typeName, "D")
        XCTAssertEqual(type1.chain[1].typeArguments.count, 1)

        XCTAssertEqual(type2.chain.count, 1)
        XCTAssertEqual(type2.chain[0].typeName, "F")


        XCTAssertEqual(genericType2.chain[0].typeName, "G")
        XCTAssertEqual(genericType2.chain[1].typeName, "H")
        XCTAssertEqual(genericType2.chain[1].typeArguments.count, 2)

        guard case let .nominal(nestedGenericType1) = genericType2.chain[1].typeArguments[0],
              case let .unnamedTuple(nestedGenericType2) = genericType2.chain[1].typeArguments[1] else {
            XCTAssertTrue(false)
            return
        }


        XCTAssertEqual(nestedGenericType1.chain[0].typeName, "I")
        XCTAssertEqual(nestedGenericType2.types.count, 2)


        guard case let .unnamedTuple(outputType) = functionDefinition.outputType else {
            XCTAssertTrue(false)
            return
        }
        XCTAssertEqual(outputType.types.count, 1)
        guard case let .nominal(type1) = outputType.types[0] else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(type1.chain[0].typeName, "L")
        XCTAssertEqual(type1.chain[1].typeName, "M")
        XCTAssertEqual(type1.chain[1].typeArguments.count, 3)

        guard case let .nominal(genericType1) = type1.chain[1].typeArguments[0],
              case let .nominal(genericType2) = type1.chain[1].typeArguments[1],
              case let .unnamedTuple(genericType3) = type1.chain[1].typeArguments[2] else {
            XCTAssertTrue(false)
            return
        }
        XCTAssertEqual(genericType1.chain[0].typeName, "N")
        XCTAssertEqual(genericType2.chain[0].typeName, "O")
        XCTAssertEqual(genericType3.types.count, 2)

        guard case let .nominal(nestedGenericType1) = genericType3.types[0],
              case let .nominal(nestedGenericType2) = genericType3.types[1] else {
            XCTAssertTrue(false)
            return
        }
        XCTAssertEqual(nestedGenericType1.chain[0].typeName, "P")
        XCTAssertEqual(nestedGenericType2.chain[0].typeName, "Q")
    }

    func testFunctionParams() throws {
        let source = """
            func (Input) main(param1: A, param2: B) => Nothing
                Nothing
        """

        let module = try Module(source: source, path: "main")
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        guard case let .nominal(inputType) = functionDefinition.inputType else {
            XCTAssertTrue(false)
            return
        }
        XCTAssertEqual(inputType.chain.count, 1)
        XCTAssertEqual(inputType.chain[0].typeName, "Input")

        XCTAssertEqual(functionDefinition.params.count, 2)
        XCTAssertEqual(functionDefinition.params[0].name, "param1")
        XCTAssertEqual(functionDefinition.params[1].name, "param2")

        guard case let .nominal(type1) = functionDefinition.params[0].type,
              case let .nominal(type2) = functionDefinition.params[1].type else {
            XCTAssertTrue(false)
            return
        }
        XCTAssertTrue(type1.chain[0].typeName == "A")
        XCTAssertTrue(type2.chain[0].typeName == "B")
    }

    func testFunctionParamsComplicated() throws {
        let source = """
            func (Input) main(param1: A::B, param2: [C<D>, Q], param3: {E, F} -> G) => Nothing
                Nothing
        """

        let module = try Module(source: source, path: "main")
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        guard case let .nominal(inputType) = functionDefinition.inputType else {
            XCTAssertTrue(false)
            return
        }
        XCTAssertEqual(inputType.chain.count, 1)
        XCTAssertEqual(inputType.chain[0].typeName, "Input")

        XCTAssertEqual(functionDefinition.params.count, 3)
        XCTAssertEqual(functionDefinition.params[0].name, "param1")
        XCTAssertEqual(functionDefinition.params[1].name, "param2")
        XCTAssertEqual(functionDefinition.params[2].name, "param3")

        guard case let .nominal(type1) = functionDefinition.params[0].type,
              case let .unnamedTuple(type2) = functionDefinition.params[1].type,
              case let .lambda(type3) = functionDefinition.params[2].type else {
            XCTAssertTrue(false)
            return
        }
        XCTAssertTrue(type1.chain[0].typeName == "A")
        XCTAssertTrue(type1.chain[1].typeName == "B")

        XCTAssertEqual(type2.types.count, 2)
        guard case let .nominal(type21) = type2.types[0],
              case let .nominal(type22) = type2.types[1] else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(type21.chain[0].typeName, "C")
        XCTAssertEqual(type21.chain[0].typeArguments.count, 1)
        XCTAssertEqual(type22.chain[0].typeName, "Q")

        XCTAssertEqual(type3.input.count, 2)
        XCTAssertEqual(type3.output.count, 1)

        guard case let .nominal(type31) = type3.input[0],
              case let .nominal(type32) = type3.input[1],
              case let .nominal(type33) = type3.output[0] else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(type31.chain[0].typeName, "E")
        XCTAssertEqual(type32.chain[0].typeName, "F")
        XCTAssertEqual(type33.chain[0].typeName, "G")
    }

    func testReturnLambda() throws {
        let source = """
            func (Input) main(param1: {{} -> Nothing, {A, B, D} -> C} -> D) => {E} -> G
                Nothing
        """

        let module = try Module(source: source, path: "main")
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(functionDefinition.params.count, 1)
        XCTAssertEqual(functionDefinition.params[0].name, "param1")

        guard case let .lambda(paramType) = functionDefinition.params[0].type else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(paramType.input.count, 2)
        XCTAssertEqual(paramType.output.count, 1)

        guard case let .lambda(paramInput1) = paramType.input[0],
            case let .lambda(paramInput2) = paramType.input[1] else
        {
            XCTAssertTrue(false)
            return
        }
        
        XCTAssertEqual(paramInput1.input.count, 0)
        XCTAssertEqual(paramInput2.input.count, 3)

        guard case let .lambda(outputType) = functionDefinition.outputType else {
            XCTAssertTrue(false)
            return
        }
        XCTAssertEqual(outputType.input.count, 1)

        if case let .nominal(ouputInputType) = outputType.input[0] {
            XCTAssertEqual(ouputInputType.chain.count, 1)
            XCTAssertEqual(ouputInputType.chain[0].typeName, "E")
        }
    }
}
