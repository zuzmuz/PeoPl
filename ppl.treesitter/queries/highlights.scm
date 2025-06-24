
[
 "choice"
 "typeset"
 "some"
 "any"
 "in"
 "private"
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

(access_expression
  field: (small_identifier) @function.call)

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
(value_definition
  identifier: (scoped_identifier
                (small_identifier) @function.call))

(choice_type_field_list
  (small_identifier) @variable.member)

(tagged_expression
  identifier: (small_identifier) @variable.member)

(tagged_type_specifier
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
(optional_pipe_operator) @operator

[
  ; "^"
  "**"
  "and"
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

(binding) @function.call
"if" @keyword.control

(comment) @comment
