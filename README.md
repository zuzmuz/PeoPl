# What's the idea

Piping Programming Language
PPL
pronounced people, or pee pee ell, whatever you like
stylized as PeoPl
is the people's language


The project is in early development, there is a basic incomplete interpreter and an incomplete type checker.

# Why

Just for fun.

But also a thought experiment.
Can I create a minimal programming language with just the most basic concepts but at the same time create something useful.

# The syntax

## The basics

PeoPl is a statically typed compiled functional programming language.
It is an expression only language, which means no statements are allowed in blocks,
only top level statements like function and type declarations are allowed, and function blocks only contain expressions.

Expressions are chained using the pipe operator `|>`. 

Functions take an input, extra arguments and return an output.
PeoPl treats the main input of the function differently from other arguments,
which gives the possibility of OOP style object methods.

It doesn't use curly braces to delimit scope.
It is not needed because there's no standalone statements like assignments and loops.

## Hello World

Here's the obligatory Hello World

```ppl
func main() => I32
    "Hello World" |> print()
```

Ok, this is not very helpful so let's give a little bit of background.

## Expression based

Peopl has only top level statements, which means scopes and nested scopes can't have statements, only expressions.

Statements usually are:
- return statements
- assignments
- loops
- branching
- declarations

These don't exist in Peopl in the traditional sense. Let's see how they're replaced.

## Example

```ppl
func main(integer: I32) => I32
    integer |>
    to_string() |>
    |value| value = value.reverse()
```

This function checks if an integer is a palindrome.
The integer is piped to the function to_string() which transform the integer into a string.
Then the output of to_string is captured and given the label `value`, then the string is compared to its reverse.

Notice that I'm using just one = instead of ==. I might get heat over this decision, but because there is no assignments in Peopl,
the equality operator is used for what it actually means.

```ppl
func gcd(a: I32, b: I32) => I32
    |a = b| a,
    |a < b| gcd(a: a, b: b-a),
    |_| gcd(a: a-b, b: b)
```

This is an implementation of greatest common divisor.

## Function declarations/definitions

A function signature looks like the following

```ppl
func (InputType) function_name(argument_name: ArgumentType) => OutputType
    expression
```
This is a top level function declaration, which is one of the supported top level statements.

### InputType

It is the type this function runs on, the syntax resembles Go's function declaration.
Think of the input as this or self from OOP, or as the first function argument in functional programming.

### Arguments

These are the extra arguments needed for the function

### Output type

Well it is obviously the output type.

## Piping

In functional programming languages, there's no object methods, rather, a function takes all its input as function arguments.
To avoid ugly nesting of function calls, FP languages uses the pipe operator, to pass the value of the expression as first argument to the next function call.

PeoPl takes this concept further. Taking influence from shell scripting and OOP, every function in PeoPl has a main input,
which is syntactically treated differently from other function arguments.

The function main input is anonymous and implicit. It behaves similarly to `this` or `self` in OOP languages.

This distinction is useful because it allows both syntax, object methods and piping, simultaneously.

`input.method` is equivalent to `input |> method`.

The difference then is in operator precedence
- the "`.`" has high precedence, the highest of any operator. In `a + b.c()` the addition is applied after the function call on a.
- the "`|>`" has low precedence, the lowest of any operator. In `a + b |> c()` the addition is applied first, then the result of a + b is piped into function c.

The use of both syntax allows to more expressiveness. Giving the same semantics to object method chaining and also piping.


## Capturing

However, piping is much more flexible then basic method chaining. Because of its low precedence, `|>` allows to separate expressions more clearly.

This allows the language to apply pattern matching on inputs.

Peopl uses the same syntax flavor to perform assignments and branching, without the need for special keywords.

Assignments, which is storing temporary variables while labeling them, and branching, which is executing an expression if a condition is met,

```ppl
expression |> |var_name| /*expression using var_name*/
```

Because Peopl doesn't support assignments, it gives you a consistent syntax to represent value capturing and pattern matching.

Use the `|var_name|` after the pipe operator, to label the input of the current expression. Capturing the input by giving it a name, will consume the implicit input.
By consuming the input, an expression which takes no input can then follow the capture group.

If the past expression produces multiple results (as a tuple, we'll see this later) each value of the tuple can be caught separately.

Like this `|first_value, second_value|`.

## Branching

While capturing the input, you can also do some pattern matching on it like this.

```ppl
func (I32) is_even() => String
    |value: value % 2 = 0| "is even",
    |_| "is odd"
```
    
Here the is even function takes an integer as input. It passes the input to the branching expression.
The branching expression has two branches, separated by the comma `,` .

The first branch captures the input with the label value, and then performs the capture block expression
to check if the value is even. If the capture block expression passes, the expression after the corresponding capture block is executed.
The execution chooses the first capture block that passes. 

An important thing to notice is that the branches should be exhaustive, which means they should cover all possible branches that evaluates to a value.

## Algebraic types

Because PeoPl doesn't support assignments, it uses structural data types to model multiple variable assignments.
Create tuples to handle multiple variable.

```ppl
// unnamed tuples can be destructured by capturing its content
func () => Nothing
    [ expression1(), expression2() ] |>
    |a, b| /* expression using a and b as labels for the past expression*/ a + b
```

