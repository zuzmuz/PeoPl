import SwiftTreeSitter

enum Expression {
    case simpleExpression(Simple)
    case callExpression(Call)
    case branchedExpression(Branched)
    // case pipedExpression

    indirect enum Simple {
        case intLiteral(Int)
        case floatLiteral(Float)
        case stringLiteral(String)
        case boolLiteral(Bool)

        case positive(Simple)
        case negative(Simple)
        case not(Simple)

        case add(left: Simple, right: Simple)
        case minus(left: Simple, right: Simple)
        case times(left: Simple, right: Simple)
        case by(left: Simple, right: Simple)

        case tuple([Expression])
        case parenthised(Expression)
        case lambda(Expression)
        case field(String)
        case access(Simple, field: String)
    }

    struct Call {
        enum Command {
            case field(String)
            case type(TypeIdentifier)
        }

        let command: Command
        let arguments: [Argument]

    }

    struct Argument {
        let name: String
        let value: Simple
    }

    struct Branched {
        let branches: [Branch]
        let lastBranch: Branch?

        struct Branch {
            let captureGroup: [Expression]
            let body: BranchBody

            enum BranchBody {
                case simple(Simple)
                case call(Call)
                indirect case looped(Expression)
            }
        }
    }
}
