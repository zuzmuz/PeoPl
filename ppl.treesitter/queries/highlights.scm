
[
 (tuple)
 (record)
 (union)
 (choice)
] @keyword.type

(func) @keyword.function
;
;
; (nominal_type
;     identifier: (identifier) @type.definition)
;
; ; (type_arguments
; ;   (type_identifier
; ;     (nominal_type
; ;       (type_name) @variable.member)))
(call_expression
  prefix: (identifier) @function.call)
(access_expression
  field: (identifier) @variable.member)

;
;
; ; (type_arguments
; ;   (["<" ">"] @punctuation.bracket))
;
;
(field
  name: (identifier) @type.definition)
;
; (choice_definition
;   name: (identifier) @type.definition)
;
; (set_definition
;   name: (identifier) @type.definition)
;
; (function_definition
;   name: (identifier) @function)




(field_list
  (field
    name: (identifier) @variable.member))


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
  "|"
] @punctuation.bracket

[
 ":"
 "."
 ","
 "->"
] @punctuation.delimiter

(nothing) @constant.builtin
(never) @constant.builtin
;
"$" @character.special

(comment) @comment
