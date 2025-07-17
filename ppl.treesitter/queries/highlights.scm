[
 "'choice"
 "'record"
 "'func"
 "'local"
 "'public"
] @keyword.type


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
; (pipe_operator) @operator
; (optional_pipe_operator) @operator

; [
;   ; "^"
;   "**"
;   "and"
; ] @keyword.operator

[
  ; "("
  ; ")"
  "["
  "]"
  "{"
  "}"
  ; "|"
] @punctuation.bracket

[
 ":"
 ; "."
 "\\"
 ","
 ; "->"
 "=>"
] @punctuation.delimiter

; [
;  "_"
; ] @constant.builtin

; (nothing_type) @constant.builtin
; (never_type) @constant.builtin
(nothing_value) @constant.builtin
; (never_value) @constant.builtin

(binding) @function.call
; "if" @keyword.control

(comment) @comment
