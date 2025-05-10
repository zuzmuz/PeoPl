
[
  "'record"
  "'choice"
  "'in"
  "'some"
  "'any"
] @keyword.type

[
 "'func"
] @keyword.function

; [
;  "namespace"
;  ] @include


(nominal_type
    (identifier) @type.definition)

; (type_arguments
;   (type_identifier
;     (nominal_type
;       (type_name) @variable.member)))


; (type_arguments
;   (["<" ">"] @punctuation.bracket))

; (function_definition
;   (function_signature
;     (scoped_identifier
;       (small_identifier) @function)))
;
;
; (param_definition
;   name: (small_identifier) @variable.member)
;
;
; (function_call_expression
;   prefix: (scoped_identifier
;              (small_identifier) @function.call))
;
; (argument
;   name: (small_identifier) @variable.member)

; (int_literal) @number
; (bool_literal) @boolean
; (float_literal) @number.float
; (string_literal) @string
;
; (multiplicative_operator) @operator
; (additive_operator) @operator
; (comparative_operator) @operator
; (not_operator) @operator
; (and_operator) @operator
; (or_operator) @operator
; (pipe_operator) @operator
;
; [
;   "^"
;   ","
; ] @keyword.operator
;
; [
;   "("
;   ")"
;   "["
;   "]"
;   "{"
;   "}"
; ] @punctuation.bracket
;
; [
;  "::"
;  ":"
;  "."
;  "=>"
; ] @punctuation.delimiter

(nothing) @constant.builtin
(never) @constant.builtin

; "_" @character.special

(comment) @comment
