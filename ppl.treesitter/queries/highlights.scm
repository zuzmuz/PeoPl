[
 "choice"
 "func"
 "local"
 "public"
] @keyword.type

(tagged_type_specifier
  identifier: (identifier) @variable.member)

; (tagged_type_specifier
;   type_specifier: (nominal
;                     identifier: (qualified_identifier
;                                   identifier: (identifier) @type.definition)))
(tagged_expression
  identifier: (identifier) @variable.member)

(qualified_identifier
  identifier: (identifier) @type.definition)

(access_expression
  field: (identifier) @function.call)

; (trailing_closure_list
;   identifier: (identifier) @variable.member)

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

; [
;   ; "^"
;   "**"
;   "and"
; ] @keyword.operator

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
 ; "."
 "\\"
 ","
 "->"
 "=>"
] @punctuation.delimiter

; [
;  "_"
; ] @constant.builtin

; (nothing_type) @constant.builtin
; (never_type) @constant.builtin
(nothing) @constant.builtin
(never) @constant.builtin
; (never_value) @constant.builtin

(binding) @function.call
"if" @keyword.control

(comment) @comment
