# Cartesianism

In his Discourse on the Method, French philosopher Rene Descartes
attempts to arrive to a set of principles that one can know as true without any doubt.

In his Meditations on First Philosophy, he establishes the thought experiment;
Imagine you have a basket of apples where you suspect some of them are rotten.
To prevent the rot from spreading, you remove all apples from the basket.
You then examine all apples, one by one, and only put back the ones that are good.

In the same way, I tried to reevaluate every programming concept, syntax and idioms.
Only keeping the ones I personally deem most useful, removing everything else.

## No keywords

Keywords are an easy way out for a language. They are needed in some cases,
but their problem is that whenever a new keyword is added, a new special syntax is needed.
This is more work on the language parser, more things for it to verify, 
the semantics of the code might change. It's also more things to learn as a programmer.

## The Bad and the Ugly

There's also some concepts that I consider either bad, or useless.
I can go into more details about this later, but here is a list of examples.

1. inheritance:
    it's bad. Or at least, not as useful as you might initially expect.
    Inheritance is just anonymous composition. Not even. It's implicit composition.
    I don't like implicitness when it can lead to ambiguity.
    When a class inherit from another, it is basically the same as just adding a member
    field to the class, which doesn't have a name (however it can sometime have the implicit 
    "super" name).
    Anonymous composition might be useful sometimes, but a lot of problems arise.
    For instance
    - multiple inheritance creates a lot of semantics issues
      and that's why it is not allowed in languages like Java and Objective C.
    - it allows function overriding, which means every object needs to have
      a virtual functions table, so that objects know which methods to call on runtime.
    - inheritance chains makes code harder to read. Some members can be part of a super class.
      Therefor, you'll have to hunt down method or member definitions,
      and it invites you to write fragmented code.
    - the `protected` keyword is basically a useless concept.
2. mutable variables:
    mutable variables might be necessary at a low level.
    Maybe it's because this is how computers work. You have registers with values,
    and you keep modifying these values.
    However, I believe that it is not a good way to model our algorithms.
    Variable assignment is not a good idea.
    Today we take it for granted, var a = expression, but it doesn't make mathematical sense.
    "=" is not an assignment operator. It is the mathematical equality operator.
    A C developer might write i = i + 1, and think this is a completely valid statement.
    But show this to someone who never learned programming and he will be confused.
3. side effect:
    I really hate methods or functions that have this kind of signature
    ```c
    void doesSomethingMysterious() { 
     // ...
    }
    ```
    What does it do? Why does it return void? Why does it take no arguments?
    I always viewed these kinds of functions like ghosts in the code, and I like to call
    them ghost functions.
    Do I really need to dig into the function implementation to guess what it's doing.
    There's only thing this function can be doing that is meaningful, actually 2:
    - Printing useless stuff to console
    - Modifying global state
    I genuinely believe that this type of signature should not be allowed in new high level
    programming languages (we give C a pass). 
    Luckily nobody does this anymore, right? Cause we unanimously decided that global variables
    are bad. But, why do I still see these kind of functions as class methods.
    Is it because it's scoped to an object that it becomes magically safer.
    Truth is, code that produce invisible side effects was, is and will always be a bad idea.
    Plus, a function that takes named arguments, and return a type is always way more expressive
    than a ghost function.
4. using objects to model behavior:
    OOP is great. I don't find anything wrong with it theoretically.
    It is much more intuitive to think about your code in terms of objects.
    This is why I think functional programming will still be niche.
    However, there's a big problem in programming languages that forces you,
    to model everything in terms of objects (looking at you Java).
    This lead to the unproductive habit of creating Services, Handlers, Managers, Observers
    Factories, and worrying about naming conventions, where all you needed was just a function.
    

There's many more that I will fill here whenever I remember them.

## The Good

I mentioned that inheritance is [bad](#the-bad-and-the-ugly).
Not all OOP concepts are bad though

1. OOP syntax
    having function on objects is a good idea.
    One thing I miss in functional programming languages is being able to press '.',
    and have all my method listed.
    Some functional programming languages uses the pipe operator for that,
    but it doesn't scratch the same itch.
    Plus, subject.verb(object) is such an intuitive concept that it will stay useful.
2. Polymorphism
    If we ditch inheritance and function overriding, we can still have polymorphism.
    Polymorphism is basically a fancy way of doing function overloading.
    Yes, ad hoc polymorphism is just function overloading with dynamic dispatch.
    You don't need v-tables, virtual functions and all of that.
    If you don't know which function to call at compile time, the compiler can do basic pattern matching
    on the type and run the corresponding function.
    Speaking of..
2. Pattern matching
    When I used to write c or c++ back in the days, I never used switch statements.
    They were basically a weird syntax to just do if elses.
    There might have been a small performance benefit. But I think compilers could achieve
    the same thing eventually. I might be wrong but a compiler can optimize successive
    if/elses as a switch block.
    However, once I started using modern programming languages like swift, rust or kotlin,
    I started to abuse pattern matching. They're such a useful concept.

There's many more that I will fill here whenever I remember them.

# My Philosophy

Okay let's start from scratch.
Let's go an acid trip, forgetting all programming syntax, remembering all programming concepts.
How would we model our programs.

## Data and Behavior

Basically programming boils down to defining two things
- the shape and layout of your data
- the processes and transformations that this data goes through

A good programming language is a language that gives you the necessary tools
to express these two things concisely and meaningfully. Without being too verbose, nor cryptic.

Having too many words to express basic concepts will fill your code with syntactic noise
(looking at you public static void main(String args))
Having too few will make things cryptic and terse (APL, Perl as examples)

There's an elegant balance to find somewhere in between the two extremes.

## What about the Data

Data is the easy part. C got it right from the start,
and we kept trying to reinvent the wheel.
Just have a named structure and define its content with named members.

All useful data types (in my opinion) are:
- Builtin types
    1. primitive scalar types (obviously)
    2. collection types, (dynamic string, lists, dictionaries)
- Custom types
    1. structured types, basically structs (like in C, go, rust, swift ...)
    2. tuples, also called product types, a compound of types paired together.
       They are called product types cause it's basically TypeA "and" TypeB "and" etc...
       (NB: structs are basically named product types, the struct members
       (each one having its name and type) constitute the element of the tuple
    3. enums, also called sum types, variant, choice types.
       They are called sum types cause it's basically TypeA "or" TypeB "or" etc...
    4. generic types, they are types with associated types.
       They are types that takes types as parameters.

These are in my opinion the most useful types in programming.
A programming language that provide a clean and meaningful syntax to define custom types.
Is a good programming language.

> I intentionally glossed over references and shared pointers
> In my opinion, these don't need to be represented in the type system
> They can be handled by a different mechanism, related to data ownership
> and the borrowing, moving, and copying mechanism.
> Furthermore, shared mutable types are generally not desirable
> and should be avoided if possible.
> In my opinion, shared mutable state when needed should exclusively be handled
> in a thread safe manner. Using an actor model of some sort.
> In all other applications, references might not be needed, the language, if designed
> correctly, should theoretically help the compiler know when to move, borrow or copy data.
> Memory ownership is generally an advanced topic that I'll delve into in more depth later

### Tangent about object methods

Ah and by the way, a type does not need to handle methods, they don't need to live inside the type
(because they technically don't) so why are we writing them inside the type.

This is misleading, and can mislead beginners.

Go and Rust provide an interesting approach.
Struct methods are defined outside the type, they are implementation on the type, not part of the type.

This makes sense logically, and leads to better code in my opinion. Instead of treating data and process
as the same thing (like in c++ and java). We treat them differently, (because they are different).

```rust

struct MyStruct {
    member1: i32,
    member2: i32
}

impl MyStruct {
    fn method1(self, argument: i32) -> String {
        "returned string"
    }
}

```

```go

struct MyStruct {
    member1 int
    member2 int
}

func (myStruct MyStruct) method1(argument int) String {
    return "returned string"
}
```


I love both of these syntaxes. Cause they model things like how they're really are.
Object methods are just regular functions, that take the object as first argument
(see the explicit self in rust), and they are scoped to the object. Which means that
they are automatically namespaced to that object and can't be accessed from anywhere.
That's it.
When I first learned c++, I was always confused about `this`, where did it come from,
what does it represent. What happens when we nest classes, what is `this`??
It was worse in Java, cause we had anonymous classes, and I always felt accessing the
exterior class from the nested class to be clunky and weird.

Kotlin has a nice feature which is extension functions, it is a similar syntax to go's functions

```kotlin
class MyClass (val member1: Int, val member2: Int){}

fun MyClass.method1(argument: Int) {
    // this is implicit here
}
```

An interesting example from python and lua to prove the point.

```python
class MyClass:
    def method(self, arg):
        pass

my_class = MyClass()

my_class.method("the argument")
# is equivalent to
MyClass.method(my_class, "the argument"

```

The above code just shows how the accessed method is basically syntax sugar
In lua are even more explicit about it

```lua

local MyObject = {}

function MyObject.method(self, arg1)
   -- you can use self here 
end

-- is equivalent to
function MyObject:method(arg1)
    -- the : instead of . implicitly adds self to the argument list
end


-- both methods are exactly equivalent

local my_object = setmetatable({}, { __index = MyObject })

MyObject.method(my_object, "the argument")
-- is equivalent to
my_object:method("the argument")
-- like in the method declaration, the : here passes my_object as first argument (self)
```

Now that we've established that methods are basically scoped functions that takes the object
as first argument.
Then nesting them inside the type doesn't really makes sense.

One last example from functional programming languages

```elixir

defmodule MyModule do
    def my_method(my_object, my_argument) do
    end
end
my_method(my_object, my_argument)
# is equivalent to
my_object |> my_method(my_argument)

```

Because functional programming languages don't have the idea of object methods,
they resorted to a differently named but basically same concept of piping.

The "|>" is just the pipe operator, it throws whatever is on the left as first argument
to the method on the right.

Let's take a break from this programming language features tour, and jump back to my philosophy.

## What about the process

Alright, now we delve into the advanced concepts.
As I said, defining your types is easy. We can just use a declarative syntax,
that will define the structure and layout of our data.

However defining our processes is much more nuanced, and is gonna be the gist of PeoPl.

### Let's take a deep breath, and talk about expressions

When I started working on PeoPl, I was asking myself, what is the most basic processing unit.

We can give it a name 
*The Expression*


An expression is basically something that evaluates to something else.

For example:

5*5

This is an expression that evaluates to 25.

An expression is self contained, does not have side effects, and produce a value.

So I started thinking, is that all we need?

### A tangent about shell scripting

I don't really like BASH, but I do believe that POSIX and the unix philosophy
have a lot of merit.

What is it you may ask?

Every command in the shell:
- takes in data (from stdin) usually text.
- might take extra arguments
- outputs data (to stdout (or stderr)) also usually as text.

Every command in the shell:
- is a self contained processing unit that does one thing (supposedly)
- can be part of a chain of commands, each command's output is the next command's input.

This is a very powerful concept, 
each command can either be a shell script, a compiled executable, a function etc,
and they all behave the same:
> take input +args return output

Some of the issues bash has:
- input and output are text, raw unstructured data. This is pretty annoying,
  because commands should worry about data content and representation.
  Commands should know how to parse the input, and if the input format change,
  the input parsing should also change to accommodate.
- archaic syntax, whenever I write BASH I just wonder who thought it was good idea
  to have `fi` terminate `if` blocks, and `esac` terminate `case` block.
  Oh and option arguments parsing is a mess.
- general inconsistencies, it's clear that you're not supposed to write big applications
  in BASH. But just like javascript and PHP, people kept adding stuff to it, so that it can do more.
  Eventually, we get some inconsistent syntax.


I'd like to mention nushell, which is a new type of shell.

I was really influenced by it, and I do believe that the nushell team got a lot of things right.

Some of the things nushell got right:
- data is now structured. Everything is a record. A record is basically a hashmap.
- new modern functional syntax.

The reason I mentioned shell scripting at all was that I was really influenced by it.
Specially nushell

### Back to expressions

We talked about (5*5) which is a very basic expression. Let's zoom out a bit.

Let's consider a block
```
 ╭───────╮
─┤a block├─
 ╰───────╯
```

 This block is an atomic processing unit that evaluates to a value.
 It takes an input, maybe some extra arguments, and produces an output.

```
       extra arguments
       ╭┴──────╮
input ─┤a block├─ output
       ╰───────╯
```

Let's chain a bunch of these

```

       extra arguments    extra arguments 
       ╭┴──────╮          ╭┴──────╮
input ─┤block 1├─ output ─┤block 2├─ output
       ╰───────╯          ╰───────╯

```
The output of block 1 becomes the input of block 2.
Each block evaluates to an output. Each block is an expression.

If we're clever about with it, I can argue that a chain of blocks is everything we need to
express our logic.

We don't need statements, we don't need assignments, we don't need keywords.

But, there's still a lot of things we need

### Branching

Branching might be the most important concept in programming.
It is what makes programming possible and gives us the possibility
of creating interesting software.

Furthermore, branching might be the first thing we learn in programming
(after the hello world, basic primitives and variable declaration)

How do we model branching with blocks?
```
                            extra arguments
                            ╭┴────────╮
       extra arguments    ╭─┤block 2.1├───────╮          extra arguments 
       ╭┴──────╮          │ ╰─────────╯       │          ╭┴──────╮
input ─┤block 1├─ output ─┤ extra arguments   ├─ output ─┤block 3├─ output
       ╰───────╯          │ ╭┴────────╮       │          ╰───────╯
                          ╰─┤block 2.2├───────╯
                            ╰─────────╯
```
Like this.


In most known programming language branching is performed by using the `if` statement.

If "STATEMENT".

A statement is not expression. It is special syntax that tells the program where to go.
It is not an expression that evaluates to something.

Modern programming languages now considers an if/else block as an expression.
Makes sense, an if statement alone can not be a valid expression,
because it will only evaluates if the if condition passes.
To have a valid expression we need all branches to evaluate to something.

### Capturing

Before continuing, let's ponder a bit on the last diagram.

In order for this diagram to be a valid one, the output of block 1 should match the input
of both block 2.1 and block 2.2. And the [sum](#what-about-the-data) of the outputs
of block 2.1 and block 2.2 should match the input of block 3.

Let's reconsider the expression ( 5*5 ).
This does not take any input. We can phrase this differently by saying that,
it takes `Nothing` as input. If we consider `Nothing` to be the empty [tuple](#what-about-the-data),
then `Nothing` is a valid type.

In programming languages like C, C++ and Java, it is called void.

> (void in c has a different semantics to it when it comes to pointers,
> it also represents the erasure of
> type information, a void * for example is not a pointer to nothing,
> rather it is a pointer to "I don't care")

Object literals are expressions that take `Nothing` as input.
Integer literals (0, -100, 69, 420)
Float literals (1.4142, 3.14159, 2.7182)
Bool literals (true, false)
String literals ("Hello World")

are all expression that have outputs, but don't take inputs. Hold this thought.

If we want to imagine the blocks above as passing through a stream of data,
an unstoppable flow of objects. Then if we need to stop it, we need to capture the input.

Capturing the input means we're giving it a name. When input is captured,
the actual input becomes `Nothing`, and input now has a name, to get input 
you need to call it by its new name

```
       extra arguments             extra arguments 
       ╭┴──────╮          ╭───────╮╭┴──────╮
input ─┤block 1├─ output ─┤capture├┤block 2├─ output
       ╰───────╯          ╰───────╯╰───────╯
```

Capturing the input is useful. It is so useful that we don't actually need assignments
Assignments are used to store temporary variables that will be needed at some point
in the process. In other programming languages, assignments are unstructured.
They can be scoped, which is a good thing (I will never understand why javascript thought
hoisting variables was an accepted idea), but they can be placed anywhere in the code.
Some times we don't need to give names to these temporary variables, cause they're temporary.
In this case they can just trickle through implicitly, if they are relevant, they're captured.

```swift
// TODO: give example of guard let and if let and corresponding c example
```


### Capturing with Branching

Where the concept of capturing really blossoms is when paired with pattern matching.

When learning elixir I came across this feature that I never saw before
```elixir
defmodule MyModule do
    def factorial(1), do: 1
    def factorial(n) when n > 1, do: n * factorial(n - 1)
end
```

Elixir supports function overloading on values.
I was mind blown. I suspect this behaves like pattern matching. 
Technically, factorial is just one function, when it's called, pattern matching is performed
at runtime on the argument, and then the corresponding branch is executed.
It was the first time that I understood the value of pattern matching in branching.
You don't really need an explicit if statement.
You just need to define a block of code that runs based on a condition, and another block that runs
based on another condition. With some clever syntax (which is still very intuitive) you can get rid
of the if statements.

Let's see how this applies to our blocks.

```
                                                extra arguments
                           ╭───────────────────╮╭┴────────╮
       extra arguments    ╭┤capture condition 1├┤block 2.1├───────╮          extra arguments 
       ╭┴──────╮          │╰───────────────────╯╰─────────╯       │          ╭┴──────╮
input ─┤block 1├─ output ─┤                     extra arguments   ├─ output ─┤block 3├─ output
       ╰───────╯          │╭───────────────────╮╭┴────────╮       │          ╰───────╯
                          ╰┤capture condition 2├┤block 2.2├───────╯
                           ╰───────────────────╯╰─────────╯
```



Capture blocks are also expressions. In the initial example where we only had one branch,
the capture block was just a name, a field identifier, which technically is an expression.
Capture groups should:
- be expressions that takes `Nothing`
- contain a field identifier that is new, input will then be assigned to it
- evaluate to something. A field identifier is an expression that evaluate to itself

Remember when I asked to hold the thought?
No?
[Here](#capturing)

Back then I claimed that literals are expressions that take `Nothing` as input.
They also output themselves. Just like field identifiers.

### Do we need looping

Alright, so we established a system where assignments and if statements are not needed.
What about looping.

Looping is nice, functional programming languages ditched it completely so I know that
it is doable with recursion and tail call optimizations.

But, I don't mind looping, I believe that it's a neat concept, plus, if we want to go all
the way to perform a basic operation like looping with recursion than there's something wrong.

It's important to note that looping is overrated. You rarely need to do C style raw looping.
Everything you want to achieve with looping can be achieved with iterators, mapping and
folding algorithms. And it's usually more desirable to write your code in this declarative
functional style rather than raw dogging imperative for/while loops.

Plus, C style loops don't work if we don't have assignments, because we need to keep track of
a index variables, and keep incrementing it.

We can have basic looping without the need of side effects and mutable variables.
For loops are basically if statements with a goto at the end of it.
Ah, remember gotos? I don't. Never used them. They're a myth of past programming practices.
I thought about reinventing gotos, make them cool again, make them viable again,
give them a new purpose.

The problem with gotos is that were not scoped, they were chaotic.
If we constrain them to only their scope they can be very intuitive, safe and useful.

Let's see how we can do it with our blocks


```
       ╭──────────╮
       │╭───────╮ │
input ─┴┤block  ├─╯
        ╰───────╯  
```

Hey, look, I just created an infinite loop.

Let's pause and ponder on what this diagram means.
First, it is an expression, and like all expressions, should take an input, 
optional extra arguments and should output something.

But what does this block output? You might say it outputs nothing.
Well, this is wrong, it can not output `Norhing`, because `Nothing` can be
consumed by the next block, if the next block accepts `Nothing`.
In this case it's more semantically correct to state that this block returns `Never`.

`Nothing` is the empty tuple, it can be represented by () in python or swift.
It represents the absence of content. It is analogous to the empty set in mathematics.
`Never` is different, it represents an interruption in the chain of pipes.
It is not a valid value. An interruption in the flow of data means two things:
- there is an infinite loop
- there's a fatal error (and the program exited unexpectedly)

Some programming languages have the concept of Never.

One example is swift. The `Never` type is a type that should never occur, either because it means
the termination of the program, or because if an expression returns `Never` 
it should never be called.

### For Ever and Never

I want to expand a little bit on `Never` and how it is implemented in swift,
because it's where I'm most familiar with.

A cool attribute of `Never` is that it implements everything, and can replace any type.
If a function returns Int, you can return `Never` inside it, and the compiler will be okay with it.
This is usually done by calling ```fatalError()``` for example.

Another place where `Never` occurs in swift is in defining associated types for generic protocols.

You might live your life never worrying about `Never`, but for compilers,
it is a useful tool for logical reasoning. A function that never returns, should never be called.
If it's called then something is wrong, and the compiler can identify this at compile time.
For example, a type which is a sum of a String and `Never` can be considered a just a string,
because the never variant can never exist.
A pure virtual function on an abstract type can be thought of as returning `Never`,
because `Never` can be coerced into anything, it is a valid thing to consider,
this concept will come handy later.

### Back to looping

Because the block in the last diagram returns `Never`, the compiler can warn us about it.
If we supposedly run it in strict mode, we can even throw a compiler error.
PeoPl detects infinite loops at compile time (PeoPl 1 c++ 0).

However, `Never` can exist in the code and  not cause problem, you just need to convince
the compiler that there's a way out. The is a path that leads to a valid output.

Combining capturing, with branching and looping we can have a nice elegant way to model looping.

```

                          ╭────────────────────────────────────────╮
                          │                      extra arguments   │
                          │ ╭───────────────────╮╭┴────────╮       │
       extra arguments    │╭┤capture condition 1├┤block 2.1├───────╯          extra arguments 
       ╭┴──────╮          ││╰───────────────────╯╰─────────╯                  ╭┴──────╮
input ─┤block 1├─ output ─┴┤                     extra arguments   ╭─ output ─┤block 3├─ output
       ╰───────╯           │╭───────────────────╮╭┴────────╮       │          ╰───────╯
                           ╰┤capture condition 2├┤block 2.2├───────╯
                            ╰───────────────────╯╰─────────╯
```

That a nice diagram isn't it?

Let's break it down.
- Block 1 produces an output that should match the block 2's input.
- Block 2's input is captured, either in the capture condition 1 or in capture condition 2.
- if follow the capture condition 1, we execute block 2.1 
  and the output of block 2.1 is looped back into block 2.
- Block 2.1's output should match block 2's input, which means it should match block 1's output.
- the output of block 2 is basically the output of block 2.2. Technically, it should be the
  sum of block 2.1's and block 2.2's outputs, but we've established that
  a sum of whatever and `Never` is the whatever.


### Functions

We covered expressions, blocks, inputs, arguments, and outputs.
We also covered capturing, branching and looping.

In my opinion this covers the essentials of programming.
These concepts, alongside an expressive declarative type system,
are enough to create a very useful and totally functional programming language.

Now let's talk about modularization.

It would be very useful if we can group these blocks together, slap a name onto them
and call it a function.
It would look something like that


```
       ╭────────────────────────────────────────────────────────────────────────────────────────╮      
       │                    ╭────────────────────────────────────────╮                          │  
       │                    │                      extra arguments   │                          │
       │                    │ ╭───────────────────╮╭┴────────╮       │                          │
       │ extra arguments    │╭┤capture condition 1├┤block 2.1├───────╯          extra arguments │  
       │ ╭┴──────╮          ││╰───────────────────╯╰─────────╯                  ╭┴──────╮       │
input ─┼─┤block 1├─ output ─┴┤                     extra arguments   ╭─ output ─┤block 3├───────┼─ output
       │ ╰───────╯           │╭───────────────────╮╭┴────────╮       │          ╰───────╯       │ 
       │                     ╰┤capture condition 2├┤block 2.2├───────╯                          │ 
       │                      ╰───────────────────╯╰─────────╯                                  │ 
       ╰────────────────────────────────────────────────────────────────────────────────────────╯       
                                              MY FUNCTION
```

Like a block, a function takes an input, optional extra arguments, and produces an output.

Functions that take in `Nothing` can be considered global functions, or top level functions,
or even static methods.
Functions that take in something can be considered object methods.


### Some extra sugar

One final feature we can think of is not technically necessary per say,
but it is a huge quality of life improvement. I know I wanted to be minimal,
but this feature gives us so much gain for no pain at all.

**Early returns.**

Let's consider long chain of blocks, that finally returns a sum type, of a specific result,
or a specific error.

Our chain of blocks can fail at each step, but only produce a result if it reaches the final step.

This is a very common type of application, for example: handling http request
- I need to handle authentication, if it fails I need to return NotAuthenticatedError
  if it succeeds,
- I need to handle authorization, if it fails I need to return NotAuthorizedError
  if it succeeds,
  I need to parse the request body, if it's invalid I need to return InvalidBodyError
  if it succeeds,
- I need to perform the corresponding query, if the logic of my application fails
  I need to return a OperationNotAllowedError, if it succeeds,
- I need to return the result with the corresponding return body.

We can model this chain with our blocks, but it will become cumbersome really quickly,
I'll either need to trickle down the error at each step so that it reaches the end then return it.
Or create nested capture groups at each step to handle the errors.

Both solutions seems unintuitive and ugly.

Usually, in programming languages you can have early returns on specific conditions.
Swift has guard clauses with the ```guard let``` keywords.
Rust has by far one of the most interesting approaches called error propagation.

How does it work.

Usually functions that return `Result` types in rust will behave in the way I explained above.

In rust, `Result` is a sum type with `Ok` being the result and `Err` being the error.
Error are handled in a special way, if a function returns an error
it can be propagated with the `?` operator.

This is a basic example:

```rust

fn handle(req: Request) -> Result<Response, Error> {
    let user = authenticate(req.token)?;
    authorize(user)?;
    let body = parse(req.body)?;
    let result = do_the_stuff(user, body)?;
    Ok(result)
}

```

See how potentially elegant this syntax can be.
Each step can return an error, if the step succeeds, you go to the next,
if it fails you stop execution and return the error.

Rust opted for this type of syntax because they chose not to implement a throw keyword.
The throw does a similar thing in theory, and in practice can lead to similar code.
`throws` have a bad rep because of c++ and javascript. However, in modern programming languages
like swift, they behave just like errors as values, even newer versions of swift have
typed throws.

```swift
func handle(req: Request) throws -> Response {
    let user = try authenticate(req.token)
    try authorize(user)
    let body = try parse(req.body)
    return try doTheStuff(user, body)
}
```


One could argue that the ? operator behaves like the try keyword in swift.
I will say they're basically the same. Under the hood, swift handles thrown exceptions
as sum type values. A function that has throws in the signature is equivalent to a
function that has a Result type with an error in rust.

Because the `throws` signature is mandatory in swift, exceptions are safe.
In javascript (to be fair, most dynamic typed languages do the same),
you can throw an error from anywhere and handle it god knows where so that's why
they became a bad idea. But in principle, with the correct clever syntax, you can make them work.

In conclusion, early returns or error propagation are very nice quality of life feature.
How would we model it with our blocks.

Basically if a block returns a `Result` sum type (it works with `Optional` too btw)
we can check output of the block. If it's an error, it will be propagated out
of the chain of blocks. If it's a success, it will be safely unwrapped,
(destructuring the `Result` into is success type) and passed to the next block.
Therefor, we don't need to do pattern matching a each step, and escort the error
with us the last block.

## Data and process

### Polymorphism

Ouff, that was a ride, but we still have a long way to go.
As I mentioned [before](#the-good), polymorphism is one of the very useful concepts.
But polymorphism is a million $ name for a $100 concept, so let's call it
what it really is, function overloading.

Let's imagine 3 functions with the same argument and output types,
but with different input types.

The input types can be completely different, have completely different structure,
layout and content, however the types structure is irrelevant, because I can call the
same function on these 3 types, they are interchangeable.

Golang has an interesting but (in my opinion) flawed approach to this concept.

> Just like most Golang features, they make practical sense, but are not
> theoretically sound. I don't know I haven't written enough Go to judge it without
> bias. But, I feel that's why people like it, it just works and is good enough.

Go has kind of a unique approach with its type system. It used structural typing
instead of nominal type.

> Oh dear one extra concept... alright here we go

### Tangent about Type systems

This topic deserves a whole book on its own, and is truly fascinating.

When we talk about type systems we are more or less talking about the types
and the function we call with these types.
One important aspect of any type system is subtyping.
Subtyping is not exclusive to OOP. The idea is to combine multiple different types
that share common behavior (which means have methods with similar semantics)
into a super type that defines those behaviors. 
Now, the super type can be used instead of specifying a subtype.

A good example of how subtyping is used in practice is the Java collections framework.
It defines interfaces (we will later talk about what exactly interfaces are) 
for common use-cases like Lists, Queues, Sets, Maps, ... as well as different
implementations with different characteristics which support those different use-cases.

If I want to use a list of objects, I can just specify that I need a List interface.
The implementation of the list does not matter, it can be an array list, a linked list
or some other weird exotic type. What matters is that it conforms to what a list is
(which means have a concrete implementation defined
for all the methods that can be called on a list).

#### What are interfaces then

Interface is a useful concept that I thing started with objective-c protocols.
> Interestingly Brad Cox started working on objective-c in the early 80s
> Bjarne Stroustrup at the same time started working on what later became c++
> Objective-c was influence by smalltalk, c++ by simula.
> Both of these languages wanted to achieve OOP on top of C.
> Both had completely different approaches, c++ might have become more popular
> but objective-c introduced underrated features that later became more influential

##### Objective c vs C++

Ok I decided that this needed its own section.

I can write a book on the reasons why I don't like c++ and they all revolve around
the type system and how it interacts with memory management.

- Inheritances was for the most part the only way to model subtyping
- Function overriding makes implementing virtual functions trickier.
  Instead of virtual functions being just signatures they can be overriden
  multiple times, and children implementation can call parent implementation.
  This means every object needs to track its implementation of methods, as well as
  a pointer to its parent so that it can access its parent implementation
- It allows multiple inheritance, matter of fact it's the only way to do multiple interface
  implementation
- Forgetting the virtual keyword meant that a function is not overridable.
  But you can override it anyways, the compiler might warn you, but this will lead
  to different behavior if you call a method on the object directly, or through a pointer
  to the parent.
- C++ decided to pollute C structs with its class features. I don't know why they did this.
  They could've left C structs alone, like how ...

Objective-c did.
Look, I thing objective-c was a terrible language, but they did a couple of things right.
Objective-C classes are completely different from C structs, (way to different to be honest).
The syntax was so different and foreign that the code looked inconsistent.
To this day, I still don't fully grasp how memory management worked in objective c,
maybe cause I only wrote in this language in the beginning of my career, so I didn't have the 
insight I have today, or maybe is that Objective-c was confusing as hell.
But, looking back at it, it deserves a little bit of love.

- Objective c introduced classes with their own memory pool
  and builtin automatic reference counting
- It introduced interfaces with protocols
- It also introduced categories, which lets you add methods to existing types.

##### Back to interfaces

Interfaces are like contracts (I don't know why no language called them contracts,
different names for them are protocols, and traits (rust)).
They define function signatures, without any implementation.

In Go, structs and interfaces are both considered types, because they can be used
in the same way, with the same syntax.
However, they are fundamentally different.
Interfaces are not really types, but functions declarations that run on an abstract type

Here, it's important to define what is an abstract type, or if it is useful as a concept.

I would argue that abstract classes (they way they're implemented and used in C++ and Java)
are not, but, abstract types are.

What are abstract types then. Well, just names. It doesn't make sense for an abstract type
to have data inside of it, in this case it not abstract anymore, it's concrete, but disabled.
It can't walk on its own, it's incomplete.

#### Nominal Typing

The most common type of typing, is nominal typing.
It just means that types are known by their names, and like I said above,
abstract types are just names.
It's as if we're saying "hey yo arraylist, you're a list", and then we turn
to the linkedlist and tell it "and you too, linkedlist, you're a list too"
And list is just an abstract type, which means that it is not defined in terms of data.
It can be anything. The thing that's special about lists is that if you're labeled
as a list, people expect you to behave as a list. So you need to know how to behave like a list,
and the compiler will yell at you if you don't behave as a list. 
That's basically nominal typing.
We define an interface that have a list of function signatures.
We assign the interface name to types, we implement the function, and that's it.

#### Structural Typing

In contrast to nominal typing, structural typing doesn't care about names.

It can be applied in 2 different scenarios
- imagine a language that doesn't have custom structures with named params,
  all it supports is sum types and product types. Managing your types in this language
  is quite hard, so the language designer gives you the possibility of creating
  typealiases. However, these typealiases are not hard label, the preprocesser will skim
  through the code and replace the typealiases with the actual types. So you could use the
  typealiases, or the actual full types interchangeably, as long as the type you're expecting
  has the same structure, things will work.
- imagine a language where you can pass a variable of a generic type to a function.
  By generic, I mean that it can be anything. The compiler knows that this object can be anything
  so it let's do with it whatever you want. You can even call methods on it that might
  yet exist.
  ```c++
  template<typename T>
  void takeArgument(T t) {
       t.freeToDoWhatever()
  }

  class FreeClass {
    public:
      void freeToDoWhatever()
  };

  class AnotherFreeClass {
    public:
      void freeToDoWhatever()
  };

  takeArgument(FreeClass()); //this works
  takeArgument(AnotherFreeClass()); // this also works
  takeArgument(0); // can not call freeToDoWhatever on an int, this will fail

  ```

  Well this language exists, and it's c++ with templates

Structural typing is basically duck typing, but at compile time

> Side note: C++20 introduced concepts which made working with templates
> a little bit more constrained and easier to manage.
> But templates are literally insane. They're a fascinating theoretical concept,
> and I wish c++ had a better compilation error messaging (and better copy/move semantics)
> I would definitely play with templates more.
> They might not be very useful but they're fascinating theoretically

#### Duck typing

Duck typing is basically structural typing, but at run time.

Everything is a hashmap, labels are keys in the hashmap,
calling a function with a name checks if function name exists in certain hashmap,
if it exists it is called, if it doesn't your code throws an exception.

### Choosing your type system

When designing a programming language, a very important decision is choosing your type system.
Or at least a combination of features that would hopefully create
a consistent and useful typing system.

But I'm here to choose the most minimal one, while simultaneously being the most useful one.

Nominal typing.


## Meta features

### Namespaces and scopes

### Access modifiers

### Packaging
