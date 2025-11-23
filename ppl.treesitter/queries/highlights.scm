[
 "comp"
 "fn"
] @keyword.type

(qualified_identifier
  identifier: (identifier) @type.definition)
;
(access_expression
  field: (identifier) @function.call)


(int_literal) @number
(bool_literal) @boolean
(float_literal) @number.float
(string_literal) @string


(exponential_operator) @operator
(multiplicative_operator) @operator
(additive_operator) @operator
(bitwise_shift_operator) @operator
(bitwise_and_operator) @operator
(comparative_operator) @operator
(not_operator) @operator
(and_operator) @operator
(or_operator) @operator
(pipe_operator) @operator
(optional_pipe_operator) @operator

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
 "\\"
 ","
 "->"
 "'"
] @punctuation.delimiter

(nothing) @constant.builtin
(never) @constant.builtin
(special) @constant.builtin

(binding) @function.call
"if" @keyword.control

(comment) @comment
