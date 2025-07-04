// extension Syntax.Module: Hashable {
//     func hash(into hasher: inout Hasher) {
//         hasher.combine(definitions)
//     }
//     static func == (
//         lhs: Self,
//         rhs: Self
//     ) -> Bool {
//         lhs.definitions == rhs.definitions
//     }
// }
//
// extension Syntax.Definition: Hashable {
//     func hash(into hasher: inout Hasher) {
//         switch self {
//         case let .typeDefinition(typeDefinition):
//             hasher.combine(typeDefinition)
//         case let .valueDefinition(valueDefinition):
//             fatalError("not comparing value definitions")
//         }
//     }
//     static func == (
//         lhs: Self,
//         rhs: Self
//     ) -> Bool {
//         switch (lhs, rhs) {
//         case let (.typeDefinition(lhs), .typeDefinition(rhs)):
//             return lhs == rhs
//         case let (.valueDefinition(lhs), .valueDefinition(rhs)):
//             return false
//         default:
//             return false
//         }
//     }
// }
//
// extension Syntax.TypeDefinition: Hashable {
//     func hash(into hasher: inout Hasher) {
//         hasher.combine(self.identifier)
//         hasher.combine(self.arguments)
//         hasher.combine(self.definition)
//     }
//
//     static func == (
//         lhs: Self,
//         rhs: Self
//     ) -> Bool {
//         lhs.identifier == rhs.identifier
//             && lhs.arguments == rhs.arguments
//             && lhs.definition == rhs.definition
//     }
// }
//
extension Syntax.ScopedIdentifier: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.chain)
    }

    public static func == (
        lhs: Self,
        rhs: Self
    ) -> Bool {
        lhs.chain == rhs.chain
    }
}
//
// extension Syntax.ValueDefinition: Hashable {
//     func hash(into hasher: inout Hasher) {
//         hasher.combine(self.identifier)
//         // NOTE: not allowing for function overloading
//     }
//
//     static func == (
//         lhs: Self,
//         rhs: Self
//     ) -> Bool {
//         lhs.identifier == rhs.identifier
//     }
// }
//
// extension Syntax.TypeSpecifier: Hashable {
//     func hash(into hasher: inout Hasher) {
//         switch self {
//         case .nothing:
//             hasher.combine("nothing")
//         case .never:
//             hasher.combine("never")
//         case let .product(product):
//             hasher.combine(product)
//         case let .sum(sum):
//             hasher.combine(sum)
//         default:
//             fatalError("hashing not implemented for \(self)")
//         }
//     }
//
//     static func == (
//         lhs: Self,
//         rhs: Self
//     ) -> Bool {
//         switch (lhs, rhs) {
//         case (.nothing, .nothing):
//             return true
//         case (.never, .never):
//             return true
//         case let (.product(lhsProduct), .product(rhsProduct)):
//             return lhsProduct == rhsProduct
//         case let (.sum(lhsSum), .sum(rhsSum)):
//             return lhsSum == rhsSum
//         default:
//             return false
//         }
//     }
// }
//
// extension Syntax.Product: Hashable {
//     func hash(into hasher: inout Hasher) {
//         hasher.combine(self.typeFields)
//     }
//
//     static func == (
//         lhs: Self,
//         rhs: Self
//     ) -> Bool {
//         lhs.typeFields == rhs.typeFields
//     }
// }
//
// extension Syntax.Sum: Hashable {
//     func hash(into hasher: inout Hasher) {
//         for field in self.typeFields {
//             hasher.combine(field)
//         }
//     }
//
//     static func == (
//         lhs: Self,
//         rhs: Self
//     ) -> Bool {
//         lhs.typeFields == rhs.typeFields
//     }
// }
//
// extension Syntax.TypeField: Hashable {
//     func hash(into hasher: inout Hasher) {
//         switch self {
//         case let .typeSpecifier(typeSpecifier):
//             hasher.combine(typeSpecifier)
//         case let .taggedTypeSpecifier(taggedTypeSpecifier):
//             hasher.combine(taggedTypeSpecifier)
//         case let .homogeneousTypeProduct(homogeneousTypeProduct):
//             hasher.combine(homogeneousTypeProduct)
//         }
//     }
//
//     static func == (
//         lhs: Self,
//         rhs: Self
//     ) -> Bool {
//         switch (lhs, rhs) {
//         case let (.typeSpecifier(lhsType), .typeSpecifier(rhsType)):
//             return lhsType == rhsType
//         case let (
//             .taggedTypeSpecifier(lhsTagged), .taggedTypeSpecifier(rhsTagged)
//         ):
//             return lhsTagged == rhsTagged
//         case let (
//             .homogeneousTypeProduct(lhsHomogeneous),
//             .homogeneousTypeProduct(rhsHomogeneous)
//         ):
//             return lhsHomogeneous == rhsHomogeneous
//         default:
//             return false
//         }
//     }
// }
//
// extension Syntax.TaggedTypeSpecifier: Hashable {
//     func hash(into hasher: inout Hasher) {
//         hasher.combine(self.identifier)
//         hasher.combine(self.type)
//     }
//
//     static func == (
//         lhs: Self,
//         rhs: Self
//     ) -> Bool {
//         lhs.identifier == rhs.identifier && lhs.type == rhs.type
//     }
// }
//
// extension Syntax.HomogeneousTypeProduct: Hashable {
//     func hash(into hasher: inout Hasher) {
//         hasher.combine(self.typeSpecifier)
//         hasher.combine(self.count)
//     }
//
//     static func == (
//         lhs: Self,
//         rhs: Self
//     ) -> Bool {
//         lhs.typeSpecifier == rhs.typeSpecifier && lhs.count == rhs.count
//     }
// }
//
// extension Syntax.HomogeneousTypeProduct.Exponent: Hashable {
//     func hash(into hasher: inout Hasher) {
//         switch self {
//         case let .literal(value):
//             hasher.combine(value)
//         case let .identifier(identifier):
//             hasher.combine(identifier)
//         }
//     }
//
//     static func == (
//         lhs: Self,
//         rhs: Self
//     ) -> Bool {
//         switch (lhs, rhs) {
//         case let (.literal(lhsValue), .literal(rhsValue)):
//             return lhsValue == rhsValue
//         case let (.identifier(lhsIdentifier), .identifier(rhsIdentifier)):
//             return lhsIdentifier == rhsIdentifier
//         default:
//             return false
//         }
//     }
// }
