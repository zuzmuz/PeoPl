
[
  "type"
] @keyword.type

[
 "func"
] @keyword.function


; (type_identifier) @type
;
; (function_definition
;   name: (argument_name) @function)
;
; (function_definition
;   input_type: (type_identifier) @type)
;
; (param_definition
;   name: (argument_name) @variable.member)
;

; (call_expression
;   command: (argument_name) @function.call)
; (call_param
;   name: (argument_name) @variable.parameter)

(int_literal) @number
(bool_literal) @boolean
(float_literal) @number.float
(string_literal) @string
[
  "+"
  "-"
  "*"
  "/"
  "%"
  "="
  "<"
  ">"
  "<="
  ">="
  ; "&"
  ; "&&"
  "|"
  ; "..."
] @operator

[
  "?"
  "^"
  ";"
  ","
  ".."
] @keyword.operator

[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

(comment) @comment
