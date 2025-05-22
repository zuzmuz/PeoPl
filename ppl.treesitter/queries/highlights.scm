
[
 "choice"
 "subset"
 "some"
 "any"
 "in"
] @keyword.type

(namespace) @keyword.import
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
  prefix: (scoped_identifier
    (small_identifier) @function.call))
; (square_call_expression
;   prefix: (identifier) @function.call)
; (access_expression
;   field: (identifier) @variable.member)

;
;
; ; (type_arguments
; ;   (["<" ">"] @punctuation.bracket))
;
;
(big_identifier) @type.definition
;
; (choice_definition
;   name: (identifier) @type.definition)
;
; (set_definition
;   name: (identifier) @type.definition)
;
(definition
  (value_definition
    identifier: (scoped_identifier
                  (small_identifier) @function.call)))

(value_field_list
  (value_field
    identifier: (small_identifier) @variable.member))

(type_field
  identifier: (small_identifier) @variable.member)

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
  "**"
  "&"
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
 "::"
 ","
 "->"
] @punctuation.delimiter

(nothing_type) @constant.builtin
(never_type) @constant.builtin
(nothing_value) @constant.builtin
(never_value) @constant.builtin

(binding) @keyword.operator
"if" @keyword.control

(comment) @comment
