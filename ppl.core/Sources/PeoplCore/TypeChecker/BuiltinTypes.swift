enum Builtins {
    static let i32 = TypeIdentifier.nominal(
        NominalType(
            chain: [
                .init(typeName: "I32", typeArguments: [], location: .nowhere)
            ],
            location: .nowhere))
    static let f64 = TypeIdentifier.nominal(
        NominalType(
            chain: [
                .init(typeName: "F64", typeArguments: [], location: .nowhere)
            ],
            location: .nowhere))
    static let string = TypeIdentifier.nominal(
        NominalType(
            chain: [
                .init(typeName: "String", typeArguments: [], location: .nowhere)
            ], 
            location: .nowhere))
}
