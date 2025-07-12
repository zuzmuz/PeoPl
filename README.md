# Table Of Content :toc:
1. [The Specs](#The-Specs)


# The Specs

# Why
Just for fun.

But also a thought experiment.
An opinionated programming language that fits my programming style.

# What
## The basics
PeoPl is a statically typed compiled functional programming language.
An expression only language, which means no statements are allowed in blocks

Functions behave like pipelines, a pipeline of nodes,
nodes are expressions that can be evaluated to a value.
Expressions are:
- literals
  - integers, decimals, booleans, strings
- arithmetic expressions
- function calls
- branching expressions
- identifiers

Expressions behave like functions.
Functions take an input, with extra arguments, and return an output.

Expressions like literals behave like functions that evaluates to themselves,
they take nothing as input.

Expressions are chained using the pipe operator `|>`.

A function input behave like a regular function argument. But has a priviledged syntax.
It is analoguous to *this* or *self* in object methods.
This means OOP method style syntax is also supported.

It doesn't use curly braces to delimit scope.
It is not needed because there's no standalone statements like assignments and loops.

## The not so basics
Peopl is designed to have an expressive type system, using algebraic data types at its core.
The type system plays well with the expression based syntax for function blocks.

Peopl is also designed to have a powerful and expressive generics system.


# State
Ok nothing is ready, if you find this repo by mistake, just know that nothing is ready.

Todo list:
- [-] Treesitter grammar version 0.1.0.0
  - [X] Type system
    - [X] Tuples
    - [X] Choices
    - [X] Subsets
    - [X] Generics
    - [X] Functions
  - [X] Expressions
    - [X] Arithmetic expressions
    - [X] Function calls
    - [X] Initializers
    - [X] Branching
    - [X] Pattern Matching
  - [ ] Namespaces
    - [ ] Definining namespaces
    - [ ] Importing scopes
- [X] Parser based on Treesitter
- [-] Semantic Analyzer
  - [-] Type definitions check
    - [X] Checking invalid definitions
    - [X] Checking redefinitions
    - [ ] Checking shadowing
    - [X] Checking cyclical definitions
  - [-] Expressions type checking
    - [X] Basic piping type checking
    - [X] Function call type checking
    - [ ] Branching type checking
      - [ ] Exhaustive branching
    - [ ] Lambdas type checking
    - [ ] Type checking with generics
- [ ] Backend
  - [ ] LLVM
- [-] Lsp
  - [X] Sending syntax diagnostics
  - [ ] Sending semantics diagnostics
  - [ ] completion 
  - [ ] go to definition 
  - [ ] references 
  - [ ] hover
  - [ ] rename 
