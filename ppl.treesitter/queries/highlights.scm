
[
  "type"
  ; "const"
] @keyword.type

[
 "func"
 ; "impl"
] @keyword.function

; [
;  "namespace"
;  ] @include


(nominal_type
    (type_name) @type.definition)

; (type_arguments
;   (type_identifier
;     (nominal_type
;       (type_name) @variable.member)))


; (type_arguments
;   (["<" ">"] @punctuation.bracket))

(function_definition
  (normal_function_definition
    (field_expression
      (argument_name) @function)))


(param_definition
  name: (argument_name) @variable.member)


(call_expression
  command: (field_expression
             (argument_name) @function.call))

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
  ","
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
 "->"
 "=>"
] @punctuation.delimiter

(nothing) @constant.builtin
(never) @constant.builtin

"_" @character.special

(comment) @comment
