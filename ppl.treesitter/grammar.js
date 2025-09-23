const PREC = {
  ACCESS: 50,
  FUNCTION: 30,
  PARENTHESIS: 20,
  UNARY: 10,
  MULT: 8,
  ADD: 6,
  COMP: 5,
  AND: 4,
  OR: 3,
  PIPE: 1,
  TAGGED: 0,
};


module.exports = grammar({
  name: "peopl",

  extras: $ => [
    $.comment, /\s|\\\r?\n/,
  ],

  conflicts: $ => [
    // [$.type_field, $._simple_expression]
  ],

  rules: {
    source_file: $ => repeat(
      $.definition,
    ),

    // --------------------------------------------
    // Comments
    // --------------------------------------------

    comment: _ => token(
      seq('//', /(\\+(.|\r?\n)|[^\\\n])*/),
    ),

    // --------------------------------------------
    // Identifiers
    // --------------------------------------------

    identifier: $ => /[a-zA-Z_][a-zA-Z0-9_]*/,

    // wildcard: $ => '_',
    //
    qualified_identifier: $ => choice(
      field("identifier", $.identifier),
      prec.left(
        seq(
          field("scope", $.qualified_identifier),
          '\\',
          field("identifier", $.identifier),
        )
      )
    ),

    // -------------------------------------------
    // Definitions
    // Top level definitions are treated specially,
    // - they can be qualified
    // - they can be generic
    // -------------------------------------------
    
    // access_modifier: $ => choice(
    //   "local",
    //   "public"
    // ),

    definition: $ => seq(
      // optional(field("access_modifier", $.access_modifier)),
      field("identifier", $.qualified_identifier),
      optional(seq("'", field("type_specifier", $._basic_expression))),
      ':',
      // optional(
      //   seq(
      //     field("type_arguments", $.type_field_list),
      //     "=>",
      //   )
      // ),
      field("definition", $._expression)
    ),

    // -----------------------------------------
    // Expressions
    // everything is an expression
    // -----------------------------------------

    // A nominal expression is technically a label, that can reference anything
    // that is already defined
    nominal: $ => seq(
      field('identifier', $.qualified_identifier),
    ),

    round_expression_list: $ => seq(
      '(',
        optional(
          seq(
            $._complex_expression,
            repeat(
              seq(',', $._complex_expression)
            ),
            optional(','),
          ),
        ),
      ')'
    ),

    // record_type: $ => seq(
    //   field("type_field_list", $.square_expression_list),
    // ),

    // choice_type: $ => seq(
    //   "choice",
    //   field("type_field_list", $.square_expression_list),
    // ),

    // function_type: $ => seq(
    //   "func",
    //   optional(seq('(', field('input_type', $._simple_expression), ')')),
    //   field("arguments", $.square_expression_list),
    //   optional(
    //     seq(
    //       "->",
    //       field("output_type", $._simple_expression)
    //     )
    //   )
    // ),

    // homogeneous_product: $ => seq(
    //   field('type_specifier', $._simple_expression),
    //   '**',
    //   field('exponent', choice(
    //     $.int_literal,
    //     $.qualified_identifier
    //   ))
    // ),

    // _expression: $ => choice(
    //   $._simple_expression,
    //   $.tagged_expression,
    //   $.branched_expression,
    //   $.piped_expression
    // ),

    tagged_expression: $ => prec.right(PREC.TAGGED, seq(
      field("identifier", $.identifier),
      optional(
        seq(
          "'",
          field("type_specifier", $._basic_expression)),
      ),
      ":",
      optional(field("expression", $._expression))
    )),

    // _simple_expression: $ => choice(
    //   $.literal,
    //   $.unary_expression,
    //   $.binary_expression,
    //   $.record_type,
    //   $.choice_type,
    //   $.nominal,
    //   $.function_type,
    //   $.nothing,
    //   $.never,
    //   $.parenthisized_expression,
    //   $.binding,
    //   $.function_value,
    //   $.call_expression,
    //   $.access_expression,
    // ),
    //
    _basic_expression: $ => choice(
      $.literal,
      $.nothing,
      $.never,
      $.unary_expression,
      $.binary_expression,
      $.nominal,
      $.access_expression,
      $.call_expression,
      $.round_expression_list,
    ),

    _expression: $ => choice(
      $._basic_expression,
    ),

    // a complex expression is a superset of expressions that can't be parsed in specific contexts
    // therefore they need to be parenthisized
    _complex_expression: $ => choice(
      $._expression,
      $.tagged_expression,
    ),

    access_expression: $ => prec.right(PREC.ACCESS, seq(
      field("prefix", $._basic_expression),
      '.',
      field("field", $.identifier),
    )),

    call_expression: $ => prec.right(PREC.FUNCTION, seq(
      optional(field("prefix", $._basic_expression)),
      field("arguments", $.round_expression_list),
    )),


    // square_expression_list: $ => seq(
    //   '[',
    //     optional(
    //       seq(
    //         $._expression,
    //         repeat(
    //           seq(',', $._expression)
    //         ),
    //         optional(','),
    //       ),
    //     ),
    //   ']'
    // ),

    // generic_expression_list: $ => seq(
    //   '<',
    //   optional(
    //     seq(
    //       $._expression,
    //       repeat(
    //         seq(',', $._expression)
    //       ),
    //       optional(','),
    //     ),
    //   ),
    //   '>'
    // ),

    //
    // function_value: $ => prec.left(seq(
    //   optional(field("signature", $.function_type)),
    //   field("body", $.function_body)
    // )),
    //
    // function_body: $ => seq(
    //   "{",
    //   $._expression,
    //   "}"
    // ),
    //
    //
    // parenthisized_expression: $ => prec.left(PREC.PARENTHESIS, seq(
    //   '(',
    //   $._expression,
    //   ')',
    // )),
    //
    // binding: $ => /\$[a-zA-Z_][a-zA-Z0-9_]*/,
    //
    // branched_expression: $ => prec.left(seq(
    //   repeat1($.branch),
    // )),
    //
    // branch: $ => seq(
    //   $._branch_capture_group,
    //   field("body", choice($._simple_expression, $.tagged_expression))
    // ),
    //
    // _branch_capture_group: $ => seq(
    //   '|', 
    //   choice(
    //     field("match_expression", choice($._simple_expression, $.tagged_expression)),
    //     seq('if', field("guard_expression", $._simple_expression)),
    //     seq(
    //       field("match_expression", choice($._simple_expression, $.tagged_expression)),
    //       'if', field("guard_expression", $._simple_expression)
    //     ),
    //   ),
    //   '|',
    // ),
    //
    // piped_expression: $ => prec.left(PREC.PIPE, seq(
    //     field("left", $._expression),
    //     field("operator", choice($.pipe_operator, $.optional_pipe_operator)),
    //     field("right", $._expression),
    // )),
    //
    // pipe_operator: $ => '|>',
    // optional_pipe_operator: $ => seq('?', '|>'),


    // -------------------------------------
    // Literals
    // literals are the simplest expressions
    // -------------------------------------

    literal: $ => choice(
      $.int_literal,
      $.float_literal,
      $.string_literal,
      $.bool_literal,
    ),

    nothing: _ => "nothing",
    never: _ => "Never",

    int_literal: $ => token(choice(
        /[0-9][0-9_]*/,
        /0x[0-9a-fA-F_]+/,
        /0b[01_]+/,
        /0o[0-7_]+/,
    )),

    float_literal: $ => /\d+\.\d+/,
    string_literal: $ => /"([^"\\\r\n]|\\.)*"/,
    bool_literal: $ => choice("true", "false"),

    // ----------------------------------------
    // Operators
    // for unary and binary operations
    // ----------------------------------------

    // a unary operator followed by a simple expression 
    // TODO: unary operators should 
    unary_expression: $ => prec.left(PREC.UNARY,
      seq(
        field("operator", choice(
          // $.multiplicative_operator,
          $.additive_operator,
          // $.comparative_operator,
          // $.and_operator,
          // $.or_operator,
          $.not_operator,
        )),
        field("operand", $._basic_expression),
      )
    ),
    // two simple expressions surrounding a arithmetic or logic operator
    binary_expression: $ => choice(
      prec.left(PREC.MULT,
        seq(
          field("left", $._basic_expression),
          field("operator", $.multiplicative_operator),
          field("right", $._basic_expression),
        )
      ),
      prec.left(PREC.ADD,
        seq(
          field("left", $._basic_expression),
          field("operator", $.additive_operator),
          field("right", $._basic_expression),
        )
      ),
      prec.left(PREC.COMP,
        seq(
          field("left", $._basic_expression),
          field("operator", $.comparative_operator),
          field("right", $._basic_expression),
        )
      ),
      prec.left(PREC.AND,
        seq(
          field("left", $._basic_expression),
          field("operator", $.and_operator),
          field("right", $._basic_expression),
        )
      ),
      prec.left(PREC.OR,
        seq(
          field("left", $._basic_expression),
          field("operator", $.or_operator),
          field("right", $._basic_expression),
        )
      )
    ),


    // TODO: bitwise operators
    multiplicative_operator: $ => choice('*', '/', '%'),
    additive_operator: $ => choice('+', '-'),
    comparative_operator: $ => choice('=', '!=', '>', '>=', '<', '<='),
    not_operator: $ => 'not',
    and_operator: $ => 'and',
    or_operator: $ => 'or',
  }
});
