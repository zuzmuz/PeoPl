[
  "contract"
  "type"
] @keyword.type

[
 "func"
] @keyword.function

(type_identifier) @type

(function_declaration
  name: (field_identifier) @function)

(function_declaration
  on_type: (type_identifier) @type)

(param_declaration
  name: (field_identifier) @variable.member)


(call_expression
  callee: (field_identifier) @function.call)
(param_definition
  name: (field_identifier) @variable.parameter)

(int_literal) @number
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
  "^"
  ";"
  ","
  "."
  ; "&"
  ; "&&"
  "|"
  ; "..."
] @operator

[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

(comment) @comment
