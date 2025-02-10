# What's the idea

Piping Programming Language
PPL
pronounced people, or pee pee ell, whatever you like
stylized as PeoPl
is the people's language

# No really what is it about

My motivation was to boil down programming concepts to its essentials.
It is a very opinionated project on what (in my opinion)
are the most useful programming concepts.

1. [To read about the motivation and philosophy behind the project](docs/motivation.md)

The project is in early devolopment, there is a basic incomplete interpreter and an incomplete typechecker.

## The basics

PeoPl is a statically typed compiled functional programming language with a bash influence.
It is an expression only language, which means no statements are allowed in blocks, only top level statements like function and type deckarations are allowed.

It uses the pipe operator `|>` found in FP to perform functional chaining, however it uses object method syntax.

It is influence by shell scripting languages where a command takes an input (usually from stdin), with extra arguments,
and produces an output (usually to stdout).

The input of functions is treated differently from function arguments (unlike with regular FP languages), therefor, the syntax resembles Go like function declarations.
It takes concepts from swift, rust, go, elixir, kotlin, haskell.

# Why

Just for fun.

But also a thought experiment. Can I create a minimal programming language with just the most basic concepts but at the same time create something useful. 

# If you want to try it out

If you have swift installed on mac or linux just clone the project build it, check the tests as examples and try it out.

There's a basic interpreter.

If you use neovim you can build the tree sitter parser and install it manually to the list of neovim parsers,
also add the highlights.scm file to your treesitter queries folder to have syntax highlighting in neovim.

I'm planning on making a vscode extension once a basic version of an LSP is ready.

# The syntax

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

## What is an expression

An expression is a block of code that evaluates to a certain value.
Think of it as a processing unit, that takes in an input, with extra parameters,
and produces an output.
In Peopl, like in functional programming languages, expressions are pure, they do not produce side effects,
they do not manipulate any global state.

Int, float and string literals are expressions, as well as basic arithmetic expressions, function calls, branching with pattern matching etc...

## Are expressions enough

Yeah, the body of a function in Peopl is just a list of expressions, each expression's output is the next's expression's input.

Assignments are not necessary, our monkey brains need them to create temporary intermediate values so that the code is simpler to read.
But, with a different nicer syntax, they can be omitted. Assignments are basically like labeling, slapping a label on a value.
Assignments where modifying an object are different though, they're basically mutations. Mutations can be avoided, at least explicitly.
The compiler can perform inplace mutation if certain criteria are met, but like in FP languages, mutation is basically creating a new object,
with some modifications.

'If statements' can be branching expressions.

Functional programming already doesn't have loops and use recursion instead.

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

## Capturing

Because Peopl doesn't support assignments, it gives you a consistent syntax to represent value capturing and pattern matching.

Use the `|var_name|` after the pipe operator (by the way this is the pipe operator `|>`).

This syntax will capture the output of the past expression and slap a name to it.

If the past expression produces multiple results (as a tuple, we'll see this later) each value of the tuple can be caught separately.

Like this `|first_value, second_value|`.

## Branching

While capturing the input, you can also do some pattern matching on it like this.

```ppl
func (I32) is_even() => Bool
    |value: value % 2 = 0| "is even",
    |_| "is odd"
```
    
Here the is even function takes an integer as input. It passes the input to the branching expression.
The branching expression has two branches, separated by the comma `,` .

The first branch captures the input with the label value, and then performs the capture block expression
to check if the value is even. If the capture block expression passes, the expression after the corresponding capture block is executed.
The execution chooses the first capture block that passes. 

An important thing to notice is that the branches should be exhaustive, which means they should cover all possible branches that evaluates to a value.

# Wanna know more

That's all I got currently, the project is in early development.
