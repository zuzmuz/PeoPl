# What's the idea

Pipe Processing Language
PPL
pronounced people, or pee pee ell, whatever you like
stylized as PeoPl
is the people's language

# No really what is it about

My motivation was to boil down programming concepts to its essentials.
It is a very opinionated project on what (in my opinion)
are the most useful programming concepts.

BTW each heading can be skipped if you don't feel like reading everything.

## Cartesianism

If not interested skip to the [philosophy behind Peopl](#my-philosophy)

In his Discourse on the Method, French philosopher Rene Descartes
attempts to arrive to a set of principles that one can know as true without any doubt.

In his Meditations on First Philosophy, he establishes the thought experiment.
Imagine you have a basket of apples where you suspect some of them are rotten.
To prevent the rot from spreading, you remove all apples from the basket.
You then examine all apples, one by one, and only put back the ones that are good.

In the same way, I tried to reevaluate every programming concept, syntax and idioms.
Only keeping the ones I personally deem most useful, removing everything else.

### No keywords

Keywords are an easy way out for a language. They are needed in some cases,
but their problem is that whenever a new keyword is added, a new special syntax is needed.
This is more work on the language parser, more things for it to verify, 
the semantics of the code might change. It's also more things to learn as a programmer.

### The Bad and the Ugly

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
      a virtual function tables, so that objects know which methods to call on runtime.
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
    `should fill`
4. using objects to model behavior:
    OOP is great. I don't find anything wrong with it theoretically.
    It is much more intuitive to think about your code in terms of objects.
    This is why I think functional programming will still be niche.
    However, there's a big problem in programming languages that forces you,
    to model everything in terms of objects (looking at you Java).
    This lead to the unproductive habit of creating Services, Handlers, Managers, Observers
    Factories, and worrying about naming conventions, where all you needed was just a function.
    

There's many more that I will fill here whenever I remember them.

### The Good

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

## My Philosophy

Okay let's start from scratch.
Let's go an acid trip, forgetting all programming syntax, remembering all programming concepts.
How would we model our programs.

### Data and Behavior

Basically programming boils down to defining two things
- the shape and layout of your data
- the processes and transformations that this data goes through

A good programming language is a language that gives you the necessary tools
to express these two things concisely and meaningfully. Without being too verbose, nor cryptic.

Having too many words to express basic concepts will fill your code with syntactic noise
(looking at you public static void main(String args))
Having too few will make things cryptic and terse (APL, Perl as examples)

There's an elegant balance to find somewhere in between the two extremes.

### What about the Data

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
       (PS: structs are basically named product types, the struct members
       (each one having its name and type) constitute the element of the tuple
    3. enums, also called sum types, variant, choice types.
       They are called sum types cause it's basically TypeA "or" TypeB "or" etc...
    4. generic types, they are types with associated types.
       They are types that takes types as parameters.

These are in my opinion the most useful types in programming.
A programming language that provide a clean and meaningful syntax to define custom types.
Is a good programming language.

#### Tangent about object methods

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
    member int
    member int
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

### What about the process

Alright, now we delve into the advanced concepts.
As I said, defining your types is easy. We can just use a declarative syntax,
that will define the structure and layout of our data.

However defining our processes is much more nuanced, and is gonna be the gist of PeoPl.

#### Let's take a deep breath, and talk about expressions

When I started working on PeoPl, I was asking myself, what is the most basic processing unit.

We can give it a name 
*The Expression*


An expression is basically something that evaluates to something else.

For example:

5*5

This is an expression that evaluates to 25.

An expression is self contained, does not have side effects, and produce a value.

So I started thinking, is that all we need?

#### A tangent about shell scripting

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

#### Back to expressions

We talked about (5*5) which is a very basic expression. Let's zoom out a bit.

Let's consider a block

 ╭───────╮
─┤a block├─
 ╰───────╯

 This block is an atomic processing unit that evaluates to a value.
 It takes an input, maybe some extra arguments, and produces an output.

       extra arguments
       ╭┴──────╮
input ─┤a block├─ output
       ╰───────╯

Let's chain a bunch of these


       extra arguments    extra arguments 
       ╭┴──────╮          ╭┴──────╮
input ─┤a block├─ output ─┤a block├─ output
       ╰───────╯          ╰───────╯

The output of block 1 becomes the input of block 2.
Each block evaluates to an output. Each block is an expression.

If we're clever about with it, I can argue that a chain of blocks is everything we need to
express our logic.

We don't need statements, we don't need assignments, we don't need keywords.

But, there's still a lot of things we need

#### Branching

Branching might be the most important concept in programming.
It is what makes programming possible and gives us the possibility
of creating interesting software.

Furthermore, branching might be the first thing we learn in programming
(after the hello world, basic primitives and variable declaration)

How do we model branching with blocks?

                            extra arguments
                            ╭┴──────╮
       extra arguments    ╭─┤a block├───────╮          extra arguments 
       ╭┴──────╮          │ ╰───────╯       │          ╭┴──────╮
input ─┤a block├─ output ─┤ extra arguments ├─ output ─┤a block├─ output
       ╰───────╯          │ ╭┴──────╮       │          ╰───────╯
                          ╰─┤a block├───────╯
                            ╰───────╯

Like this
