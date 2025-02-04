
[
  "type"
  "const"
] @keyword.type

[
 "func"
 "impl"
] @keyword.function

[
 "namespace"
 ] @include


(nominal_type
  (flat_nominal_type
    (type_name) @type.definition))


(enum_type_definition
  (simple_type_definition
    (nominal_type
      (flat_nominal_type
        (type_name) @type.definition))))

(type_arguments
  (type_identifier
    (nominal_type
      (flat_nominal_type
        (type_name) @variable.member))))


(type_arguments
  (["<" ">"] @punctuation.bracket))

(function_definition
  name: (argument_name) @function)

(function_definition
  input_type: (type_identifier
                (nominal_type
                  (flat_nominal_type
                    (type_name) @type))))
(function_definition
  output_type: (type_identifier
                (nominal_type
                  (flat_nominal_type
                    (type_name) @type))))

(function_definition
  scope: (nominal_type 
           (flat_nominal_type 
             (type_name) @namespace)))

(constants_statement
  (nominal_type
    (flat_nominal_type
      (type_name) @type)))

(param_definition
  name: (argument_name) @variable.member)


(call_expression
  command: (argument_name) @function.call)

(call_param
  name: (argument_name) @variable.member)

(int_literal) @number
(bool_literal) @boolean
(float_literal) @number.float
(string_literal) @string

(multiplicative_operator) @operator
(additive_operator) @operator
(comparative_operator) @operator
(not_operator) @operator
(and_operator) @operator
(or_operator) @operator
(pipe_operator) @operator

[
  "^"
] @keyword.operator

[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

[
 "::"
 ":"
 "."
 ","
 ".."
 "->"
 "=>"
] @punctuation.delimiter

(nothing) @constant.builtin
(never) @constant.builtin

"_" @character.special

(comment) @comment
