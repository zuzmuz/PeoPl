
# Table of content
- [What is PeoPl](#what-is-peopl)
- [Expression Oriented](#expression-oriented)
  - [Pipeline Centric](#pipeline-centric)
  - [Input Capturing in Pipelines](#input-capturing-in-pipelines)
  - [Pattern Matching](#pattern-matching)
  - [Piping Complex Data Structures](#piping-complex-data-structures)
- [Functions](#functions)
  - [Functions with inputs](#functions-with-inputs)
  - [Function arguments](#function-arguments)
  - [Calling functions](#calling-functions)
- [Program structure](#program-structure)
  - [File structure](#file-structure)
- [Type System](#type-system)
  - [Tuples and Records](#tuples-and-records)
  - [Enums and Tagged Unions](#enums-and-tagged-unions)
  - [Nothing](#nothing)

# What is PeoPl

PeoPl is *Pipeline Expression Oriented Programming Language*.

Programs are constructed as pipelines of operations,
where each operation receives data, transforms it, and passes it forward.

# Expression Oriented

Everything is an expression that produces a value.

``` peopl
"hello"                    // A string literal expression returning "hello"
42                         // An integer literal expression returning 42
2 + 3                      // A binary operation expression returning 5
```

## Pipeline Centric

Data flows through transformation nodes,
similar to Unix pipes but with structured data, and strong types.

``` peopl
// Piping a string through functions
"hello world" |> reverse                // Returns "dlrow olleh"

// Method-like syntax is also supported
"hello world".reverse                   // Returns "dlrow olleh"

// Multi-step pipelines are natural
42 |> toString |> reverse             // Returns "24"
42.toString.reverse                   // Equivalent method syntax

// Complex transformations become readable pipelines
"1,2,3,4,5"
|> split(separator: ",")
|> map(transform: parseInt)
|> filter {|$x| x > 2}
|> sum                                // Returns 12
```

Drawing inspiration from Unix pipes, functional programming's composition operators, and object methods,
PeoPl makes data flow the central mechanism of the language.
Each function in a pipeline takes the output of the previous function as its primary input,
with additional arguments.

PeoPl's expression-only design eliminates the statement/expression dichotomy found in many languages.

We'll get into more details about [[#How Piping Works][piping]] later

## Input Capturing in Pipelines

Explicitly name and manipulate the pipeline input within transformation nodes.
This is done using the input capture syntax with the vertical bar notation `|$name|`.

``` peopl
// Input capturing using |$name| syntax
12321
|> toString
|> |$value| value = value.reverse // Returns true (palindrome check)
```

## Pattern Matching
Input capturing is pattern matchin.
In the previous example, the output of `toString()` is matched with the label value.
The `$` sign is used to bind inputs to labels. Think of it like assignment, but backwards.

### Branching

Pattern matching is not only for binding values.
It also allows for branching.
Input can be matched to exact values, or binded to labels but with guard expressions.

``` peopl
// Basic pattern matching on values
value
|>
    |0| "Zero",
    |1| "One",
    |$n if n < 0| "Negative",
    |$n if n % 2 = 0| "Even",
    |_| "Other"
```

### Destructuring

Pattern matching can be complex, it also can be performed on [[*Tuples][tuples]] and [[*Tagged unions][tagged unions]],
which will be covered later.

## Piping Complex Data Structures

PeoPl uses product types (tuples, records) to pass complex data structure

Records (objects with named fields) can be passed through pipelines and accessed directly within transformation nodes

### Tuples

Tuples (ordered collections of values) can be processed efficiently:

``` peopl
// Piping a tuple through a transformation
(10, 5)
|> |$dimensions| dimensions.0 * dimensions.1  // Returns 50
```

### Records

Records are named tuples

``` peopl
// Piping a record
(width: 10, height: 5)
|> |$in| in.width * in.height  // Returns 50


// Piping a record and anonymous capture
(width: 10, height: 5)
|> |$| width * height  // Returns 50
```

### Nested Structures

Pattern matching and bindings can be performed on nested structures, used for destructuring.

``` peopl
// Processing nested data
(
  user: (name: "Abdulla", birthyear: 1934),
  role: "admin"
)
|> |$data| (
  username: data.user.name,
  age: 2025 - data.user.birthyear,
  canEdit: data.role = "admin"
)

// Nested pattern matching
(
  user: (name: "Abdulla", birthyear: 1934),
  role: "admin"
)
|> |(user: (name: "Hanine", birthyear: $year, role: $role)| "Hanin is born in $birthyear"
```

# Functions

Functions are also expressions
``` peopl
thisReturns42: () -> Int {
  42
}
```

This syntax creates a function that takes nothing as input and returns 42.
Return statements do not exist because the are not necessary.

## Functions with inputs
Function inputs are different from regular function arguments.
Similar to how shell commands take their input from stdin.
They're analoguous to self or this in languages with object methods.
Inputs are anonymous, which means they can be pipelined directly into other functions.
However, if needed they can also be captured.

``` peopl
square: (Int) -> Int {
  |$in| in*in
}
```

## Function arguments
In addition to function input, functions also take extra arguments.
Extra arguments are always named.


``` peopl
add: [a: Int, b: Int] -> Int {
  a + b
}
```

if `()` are ommited, it means the functions takes nothing as input.
By nothing, I mean the type nothing, analoguous to null or None.

## Calling functions
Functions with inputs need to be called on an object

``` peopl
5.square // returns 25
// or
5 |> square
```

If a function does not define extra arguments with `[]` the function can be called without `()`

``` peopl
squareP: (Int)[] -> Int { // defined with empty `[]`
  |$in| in*in
}

5.square() // () are needed here
```

Functions with nothing as input can't receive a value as input

``` peopl
5 |>
add(a: 1, b: 2) // Error: add expects nothing as input
```

Function with nothing as input can be considered as static functions.

# Program structure

Expressions are not allowed at a file top level.
The need to be binded to a label.

``` peopl
a: 3 // creating the constant a with the value 3

main: () -> Nothing { // main function
  _
}
```

The main function is the entry point of the program.

## File structure
### Definitions
A file is a list of definitions, definitions are like expressions known at compile time.
There are currently 2 supported definions
- [Type Definitions](#Type-Definitions)
- [Value Definitions](#Value-Definitions)

#### Value Definitions
Value definitions defines compile time expressions. These are usually constants,
and function definitions.

Functions are values. Values have [types](#Types)

Value identifiers always start with a lower case.

#### Type Definitions
Type definitions create type aliases. All types in PeoPl are actually structural types.
Nominal types are just aliases to these structural types.

Type identifiers always start  with Upper case.

# Type System
PeoPl has first class support for algebraic types, mainly product types and sum types.

## Tuples and Records
The basic building blocks for types are the tuples (untagged product types)
and records (tagged product types), records are like structs in c.
Defining tuples or records uses the same syntax.
``` peopl
  MyType: [Int, Float, String] // tuple
  Person: [name: String, age: Int] // record
```

As stated [above](#Definitions), type identifiers are always capitilized,
while tags always start with a lower case.

To create an instance of types use the `()`.
`[]` to define the type, `()` to create the type
``` peopl
 (1, 3.14, "hi")
 Person(name: "peopl", age: 14)
```
Tagged fields and untagged fields can be mixed

``` peopl
  Legal: [Int, what: Int]
```

## Enums and Tagged Unions
Sum types are defined in the same way as tuples and records with an additional keyword.
``` peopl
  
  Shape: choice [
       rectangle: [width: Float, height: Float],
       circle: [radius: Float]
  ]
```

The `choice` keyword is an intersting keyword because it can define unions, tagged unions,
enums as being the same concept, a choice between items.

##* Untagged Unions
An untagged union is a union of types.
Untagged unions aren't really useful, so actually untagged choices are actually implicitely tagged.
However, it doesn't make sense to have a union of the same type, or overlapping types.
So these are not allowed.
``` peopl
Number: choice [Int, Float] // Int has implicit tag 0, and Float has 1

Redundant: choice [String, String] // not allowed, can't really assign tags
```

##* Tagged Unions
Tagged unions are a very powerful feature in a language.
This also covers traditional c enums, because enums are technically
a tagged union of the [[#Nothing][nothing]] type.

``` peopl

Color: choice [red, green, blue]
// equivalent to
Color: choice [red: Nothing, green: Nothing, blue: Nothing]
```

## Nothing
Oh I forgot about nothing. Nothing is basically the empty tuple,
the Unit type, void.
Actually it's not technically void.
If a function returns `nothing` it is equivalent to returning void in c.
Though it is equivalent to None in other languages.
Nothing, with capital N is the nothing type, while nothing with small n is the value.
However, because Nothing is too verbose, an alias would be `_`
``` peopl

Nothing: []
nothing: ()
_: Nothing

```

