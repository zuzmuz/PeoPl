extension Typed.Builtins {
    static let i8 = Typed.TypeSpecifier.nominal("I8")
    static let i16 = Typed.TypeSpecifier.nominal("I16")
    static let i32 = Typed.TypeSpecifier.nominal("I32")
    static let i64 = Typed.TypeSpecifier.nominal("I64")
    static let u8 = Typed.TypeSpecifier.nominal("U8")
    static let u16 = Typed.TypeSpecifier.nominal("U16")
    static let u32 = Typed.TypeSpecifier.nominal("U32")
    static let u64 = Typed.TypeSpecifier.nominal("U64")
    static let f16 = Typed.TypeSpecifier.nominal("F16")
    static let f32 = Typed.TypeSpecifier.nominal("F32")
    static let f64 = Typed.TypeSpecifier.nominal("F64")
    static let string = Typed.TypeSpecifier.nominal("String")
    static let bool = Typed.TypeSpecifier.nominal("Bool")

    static let builtinSource = """
        type I8
        type I16
        type I32
        type I64
        type U8
        type U16
        type U32
        type U64
        type F16
        type F32
        type F64
        type Bool
        type String

        func left: I8 + right: I8 => I8
        func left: I8 * right: I8 => I8
        func left: I8 - right: I8 => I8
        func left: I8 / right: I8 => I8
        func left: I8 % right: I8 => I8
        func left: I8 < right: I8 => Bool
        func left: I8 > right: I8 => Bool
        func left: I8 <= right: I8 => Bool
        func left: I8 >= right: I8 => Bool
        func left: I8 = right: I8 => Bool
        func left: I8 != right: I8 => Bool

        func left: I16 + right: I16 => I16
        func left: I16 * right: I16 => I16
        func left: I16 - right: I16 => I16
        func left: I16 / right: I16 => I16
        func left: I16 % right: I16 => I16
        func left: I16 < right: I16 => Bool
        func left: I16 > right: I16 => Bool
        func left: I16 <= right: I16 => Bool
        func left: I16 >= right: I16 => Bool
        func left: I16 = right: I16 => Bool
        func left: I16 != right: I16 => Bool

        func left: I32 + right: I32 => I32
        func left: I32 * right: I32 => I32
        func left: I32 - right: I32 => I32
        func left: I32 / right: I32 => I32
        func left: I32 % right: I32 => I32
        func left: I32 < right: I32 => Bool
        func left: I32 > right: I32 => Bool
        func left: I32 <= right: I32 => Bool
        func left: I32 >= right: I32 => Bool
        func left: I32 = right: I32 => Bool
        func left: I32 != right: I32 => Bool

        func left: I64 + right: I64 => I64
        func left: I64 * right: I64 => I64
        func left: I64 - right: I64 => I64
        func left: I64 / right: I64 => I64
        func left: I64 % right: I64 => I64
        func left: I64 < right: I64 => Bool
        func left: I64 > right: I64 => Bool
        func left: I64 <= right: I64 => Bool
        func left: I64 >= right: I64 => Bool
        func left: I64 = right: I64 => Bool
        func left: I64 != right: I64 => Bool


        func left: U8 + right: U8 => I8
        func left: U8 * right: U8 => I8
        func left: U8 - right: U8 => I8
        func left: U8 / right: U8 => I8
        func left: U8 % right: U8 => I8
        func left: U8 < right: U8 => Bool
        func left: U8 > right: U8 => Bool
        func left: U8 <= right: U8 => Bool
        func left: U8 >= right: U8 => Bool
        func left: U8 = right: U8 => Bool
        func left: U8 != right: U8 => Bool

        func left: U16 + right: U16 => I16
        func left: U16 * right: U16 => I16
        func left: U16 - right: U16 => I16
        func left: U16 / right: U16 => I16
        func left: U16 % right: U16 => I16
        func left: U16 < right: U16 => Bool
        func left: U16 > right: U16 => Bool
        func left: U16 <= right: U16 => Bool
        func left: U16 >= right: U16 => Bool
        func left: U16 = right: U16 => Bool
        func left: U16 != right: U16 => Bool

        func left: U32 + right: U32 => I32
        func left: U32 * right: U32 => I32
        func left: U32 - right: U32 => I32
        func left: U32 / right: U32 => I32
        func left: U32 % right: U32 => I32
        func left: U32 < right: U32 => Bool
        func left: U32 > right: U32 => Bool
        func left: U32 <= right: U32 => Bool
        func left: U32 >= right: U32 => Bool
        func left: U32 = right: U32 => Bool
        func left: U32 != right: U32 => Bool

        func left: U64 + right: U64 => I64
        func left: U64 * right: U64 => I64
        func left: U64 - right: U64 => I64
        func left: U64 / right: U64 => I64
        func left: U64 % right: U64 => I64
        func left: U64 < right: U64 => Bool
        func left: U64 > right: U64 => Bool
        func left: U64 <= right: U64 => Bool
        func left: U64 >= right: U64 => Bool
        func left: U64 = right: U64 => Bool
        func left: U64 != right: U64 => Bool

        func left: F16 + right: F16 => F16
        func left: F16 * right: F16 => F16
        func left: F16 - right: F16 => F16
        func left: F16 / right: F16 => F16
        func left: F16 < right: F16 => Bool
        func left: F16 > right: F16 => Bool
        func left: F16 <= right: F16 => Bool
        func left: F16 >= right: F16 => Bool
        func left: F16 = right: F16 => Bool
        func left: F16 != right: F16 => Bool

        func left: F32 + right: F32 => F32
        func left: F32 * right: F32 => F32
        func left: F32 - right: F32 => F32
        func left: F32 / right: F32 => F32
        func left: F32 < right: F32 => Bool
        func left: F32 > right: F32 => Bool
        func left: F32 <= right: F32 => Bool
        func left: F32 >= right: F32 => Bool
        func left: F32 = right: F32 => Bool
        func left: F32 != right: F32 => Bool

        func left: F64 + right: F64 => F64
        func left: F64 * right: F64 => F64
        func left: F64 - right: F64 => F64
        func left: F64 / right: F64 => F64
        func left: F64 < right: F64 => Bool
        func left: F64 > right: F64 => Bool
        func left: F64 <= right: F64 => Bool
        func left: F64 >= right: F64 => Bool
        func left: F64 = right: F64 => Bool
        func left: F64 != right: F64 => Bool

        func (I8) to_i16() => I16
        func (I8) to_i32() => I32
        func (I8) to_i64() => I64
        func (I8) to_u8() => U8
        func (I8) to_u16() => U16
        func (I8) to_u32() => U32
        func (I8) to_u64() => U64
        func (I8) to_f16() => F16
        func (I8) to_f32() => F32
        func (I8) to_f64() => F64
        func (I16) to_i8() => I8
        func (I16) to_i32() => I32
        func (I16) to_i64() => I64
        func (I16) to_u8() => U8
        func (I16) to_u16() => U16
        func (I16) to_u32() => U32
        func (I16) to_u64() => U64
        func (I16) to_f16() => F16
        func (I16) to_f32() => F32
        func (I16) to_f64() => F64
        func (I32) to_i8() => I8
        func (I32) to_i16() => I16
        func (I32) to_i64() => I64
        func (I32) to_u8() => U8
        func (I32) to_u16() => U16
        func (I32) to_u32() => U32
        func (I32) to_u64() => U64
        func (I32) to_f16() => F16
        func (I32) to_f32() => F32
        func (I32) to_f64() => F64
        func (I64) to_i8() => I8
        func (I64) to_i16() => I16
        func (I64) to_i32() => I32
        func (I64) to_u8() => U8
        func (I64) to_u16() => U16
        func (I64) to_u32() => U32
        func (I64) to_u64() => U64
        func (I64) to_f16() => F16
        func (I64) to_f32() => F32
        func (I64) to_f64() => F64
        func (U8) to_i8() => I8
        func (U8) to_i16() => I16
        func (U8) to_i32() => I32
        func (U8) to_i64() => I64
        func (U8) to_u16() => U16
        func (U8) to_u32() => U32
        func (U8) to_u64() => U64
        func (U8) to_f16() => F16
        func (U8) to_f32() => F32
        func (U8) to_f64() => F64
        func (U16) to_i8() => I8
        func (U16) to_i16() => I16
        func (U16) to_i32() => I32
        func (U16) to_i64() => I64
        func (U16) to_u8() => U8
        func (U16) to_u32() => U32
        func (U16) to_u64() => U64
        func (U16) to_f16() => F16
        func (U16) to_f32() => F32
        func (U16) to_f64() => F64
        func (U32) to_i8() => I8
        func (U32) to_i16() => I16
        func (U32) to_i32() => I32
        func (U32) to_i64() => I64
        func (U32) to_u8() => U8
        func (U32) to_u16() => U16
        func (U32) to_u64() => U64
        func (U32) to_f16() => F16
        func (U32) to_f32() => F32
        func (U32) to_f64() => F64
        func (U64) to_i8() => I8
        func (U64) to_i16() => I16
        func (U64) to_i32() => I32
        func (U64) to_i64() => I64
        func (U64) to_u8() => U8
        func (U64) to_u16() => U16
        func (U64) to_u32() => U32
        func (U64) to_f16() => F16
        func (U64) to_f32() => F32
        func (U64) to_f64() => F64
        """
    // static func getBuiltinContext() -> SemanticContext {
    //     let builtins = try! Module(source: builtinSource, path: "builtin")
    //     let emptyContext = SemanticContext.empty
    //
    //     let (typesDefinitions, _) = builtins.resolveTypeDefinitions(builtins: emptyContext)
    //     let functionsContext = builtins.resolveFunctionDefinitions(
    //         typesDefinitions: typesDefinitions,
    //         builtins: emptyContext)
    //
    //     return SemanticContext(
    //         types: typesDefinitions,
    //         functions: functionsContext.functions,
    //         functionsIdentifiers: functionsContext.functionsIdentifiers,
    //         functionsInputTypeIdentifiers: functionsContext.functionsInputTypeIdentifiers,
    //         operators: functionsContext.operators)
    // }
}
