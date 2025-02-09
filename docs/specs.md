# Specs

# The source

# Comments

```ppl
** this is a comment
```

# Statements

one file execution with list of statements.

types of acceptable statements
> 0.0.0
- definitions
    - function definitions
> 0.1.0
- definitions
    - type definitions
> 0.2.0
- constant declarations
> 0.30.0
- implementation declarations

# Statements

A statement can either be a type definition or a function definition
followed by a "..".
The ".." signifies the end of a statement.

# Function definitions

> 0.0.0

Functions are blocks of processing.
They take an input, extra arguments, and return an output.

```ppl

func (InputType) function_name(arg1: Arg, arg2: Arg3) => ReturnType
    // function body
    ..
```

The input type can be ommitted if the input type is Nothing.

# Type definitions

## Simple Types

Simple types are nominal types that act as defined structures.
They are equivalent to records (data classes), or tuples with named arguments.

> 0.1.0
```ppl
type MyType
    arg1: Arg1
    arg2: Arg2
    arg3: Arg3
    ..
```

Type names should start with a Capital letter,
or with 1+ number of _ followed directly by a capital letter,
and contain only alpha numerical characters or _.

Argument names should start with a small letter,
or with 1+ number of _ followed directly by a small letter,
and contain only alpha numerical characters or _.
Arguments can also just be a single _ (unnamed argument).

A type definition can be written on 1 line

```ppl
type MyType arg1: Arg1 arg2: Arg2 arg3: Arg3..
```

Commas and parenthesis are optional to separate type members

```ppl
type MyType(arg1: Arg1, arg2: Arg2, arg3: Arg3)..
```


Types are values. This means they cannot contain themselves or have cyclical containment.
A type cannot have a member which type is itself (or contain itself at some point in the composition chain).
Types as values mean that their size is known, containing themselves means they're incomplete.
In order for a type to have a member that point to the same type (like linked list nodes for example),
their should be indirect types, or references. The member would be living outside of the structure itself,
and only a reference to that member would be inside the type.
References, (or boxes), are not yet supported.


---

> 0.1.1
Types can be nested

```ppl
type MyType::MyNestedType
    arg1: Arg1
    ..
```

Nested types treat their containers as namespaces.
The container type name need not to be defined,
if not defined it acts only as a namespace.
Nesting is useful for name collisions and scoping of type names.

---

> 0.10.0

Types can be parametrizable with generic argument types.

```ppl
type Generic<T>
    generic: T
    ..

```

The can have multiple generic argument types

```ppl
type Generic<T, U, V>
    arg1: T
    arg2: U
    arg3: V
    ..
```


Scoping and nesting can combine with generics to create super complicated structures

```ppl
type A::B<C::D, E::F>::G<H>
    arg: H
    ..
```

Eventhough the above is valid grammar, namespace type names should not contain type arguemnts.
Because, unike with [function definitions](#function_definitions), 
namespace type's type arguments do not provide any useful info to the nested type as it is not accessible.

```ppl
type TopGeneric<T>
    arg: T
    ..

type TopGeneric::Bottom<T>
    arg: T

** this is valid syntax
```

## Enum Types

> 0.4.0

Enum types, or sum types are like simple types but can be any one of listed types in Enum

```ppl

type MyEnum
    Case1
    Case2
    ..
```


The enum cases are also considered types and can therefore contain members


```ppl
type MyEnum
    Case1 arg: Arg
    Case2 arg1: Arg1 arg2: Arg2
    ..
```


Enum types follow the same naming convention as regular types,
the useful distinction is that a enum type act as a meta type,
its members are types of their own. The enum cases follow the exact same
syntax as regular type definitions, (parenthesis and commas are optional).

The way the parser distincs between regular types and enum types is due to the strong
naming conventions. A regular type name is immidiately followed by a member definition,
which start with a small letter. If the word after the enum type name is capitilized,
it is considered an enum type case.

Enum types can be nested, and regular types can also be nested inside it.

```ppl
type Regular
    ..

type Regular::Enum
    Case
    ..

type Regular::Enum::OtherRegular
    ..
```


Same with regular types, enums cannot be indirect, or contain themselves, or contain something that contains them.
> 0.2.0

Enum types can also be generic

```ppl

type Optional<T>
    Value _: T
    Nothing
    ..

type Result<T, E>
    Success _: T
    Error: _: E
    ..
```

## Types

There's two types of types, nominal and structural.
Nominal types are user defined (or builtin) types that have a name.
Their structure and layout are defined.

The other type is structural types, and they are


### Tuples

> 0.0.0

Tuples are structures with unnamed members and are therefore non nominal.

```ppl

type TupleContainer
    tuple: [T, U, V]
```


tuple is an member of TupleContainer which type is a product of the three types T, U, V.

Tuples can contain any type inside of them (generic, enum ...) and any number of items.


### Lambdas

> 0.20.0

Lambdas are anonymous functions, that behave like regular functions but do not have extra arguments,
just input and output.

```ppl
type LambdaContainer
    lambda: {I, J} -> O
```

I and J are the types that constitues the tuple that forms the input of the lambda,
(the sqare brackets [] are not necessary in this case because the types are already surrounded by curly brackets).
O is the output

Just like tuples, the inputs and outputs can be any type.

