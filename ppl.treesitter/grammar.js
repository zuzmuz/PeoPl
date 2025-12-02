const PREC = {
  ACCESS: 50,
  FUNCTION: 30,
  PARENTHESIS: 20,
  UNARY: 15,
  EXP: 12,
  MULT: 10,
  ADD: 9,
  BSHFT: 8,
  BAND: 7,
  BOR: 6,
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

  rules: {
    source_file: $ => optional($._expression_list),

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
    special: $ => "_",

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

    // -----------------------------------------
    // Expressions
    // everything is an expression
    // -----------------------------------------
    //

    _expression_list: $ => seq(
      $._complex_expression,
      repeat(
        seq(
          choice(',', '\n'),
          $._complex_expression,
        ),
      ),
      optional(choice(',', '\n'))  // Allow trailing separator
    ),
        


    // An expression list is used in function calls
    round_expression_list: $ => seq(
      '(',
        optional(
          $._expression_list
        ),
      ')'
    ),

    // a square expression list returns a tuple
    square_expression_list: $ => seq(
      '[',
        optional(
          $._expression_list
        ),
      ']'
    ),


    tagged_expression: $ => prec.right(PREC.TAGGED, seq(
      optional(field("hidden", $.special)),
      field("identifier", $.qualified_identifier),
      optional(
        seq(
          "'",
          field("type_specifier", $._basic_expression)),
      ),
      ":",
      optional(field("expression", $._expression))
    )),

    _basic_expression: $ => choice(
      $.literal,
      $.unary_expression,
      $.binary_expression,
      $.qualified_identifier,
      $.access_expression,
      $.parenthesis_expression,
      $.square_expression_list,
      $.round_call_expression,
      $.square_call_expression,
      $.brace_call_expression,
      $.binding,
      $.positional
    ),

    _expression: $ => choice(
      $._basic_expression,
      $.function_definition,
      $.piped_expression,
      $.branched_expression,
    ),

    // a complex expression is a superset of expressions that can't be parsed in specific contexts
    // therefore they need to be parenthisized
    _complex_expression: $ => choice(
      $._expression,
      $.tagged_expression,
    ),

    access_expression: $ => prec.left(PREC.ACCESS, seq(
      field("prefix", $._basic_expression),
      '.',
      choice(
        field("named_field", $.identifier),
        field("positional_field", $.int_literal),
      ),
    )),

    parenthesis_expression: $ => prec.left(PREC.PARENTHESIS, seq(
      '(', field('expression', $._complex_expression), ')'
    )),

    round_call_expression: $ => prec.left(PREC.PARENTHESIS, seq(
      optional(field("prefix", $._basic_expression)),
      field("arguments", $.round_expression_list),
    )),

    square_call_expression: $ => prec.left(PREC.PARENTHESIS, seq(
      field("prefix", $._basic_expression),
      field("arguments", $.square_expression_list),
    )),

    brace_call_expression: $ => prec.left(PREC.PARENTHESIS, seq(
      optional(field("prefix", $._basic_expression)),
      field("body", $.function_body)
    )),
    


    // -------------------------------------
    // Function literals
    // Used to define function definitions and expressions
    // -------------------------------------
    function_definition: $ => seq(
      optional("comp"),
      "fn",
      optional(seq('(', field('input', $._basic_expression), ')')),
      field("arguments", $.square_expression_list),
      "->",
      field("output", $._basic_expression)
    ),

    function_body: $ => seq(
      "{",
      optional(field("expression", $._complex_expression)),
      "}"
    ),


    
    binding: $ => /\@[a-zA-Z_][a-zA-Z0-9_]*/,
    positional: $ => token(seq(
      '$',
      token.immediate(choice(
        /[0-9][0-9_]*/,
        /0x[0-9a-fA-F_]+/,
        /0b[01_]+/,
        /0o[0-7_]+/,
      ))
    )),


    branched_expression: $ => prec.left(seq(
      repeat1($.branch),
    )),

    branch: $ => seq(
      $._branch_capture_group,
      field("body", choice($._basic_expression, $.tagged_expression))
    ),

    _branch_capture_group: $ => seq(
      '|', 
      choice(
        field("match_expression", choice($._basic_expression, $.tagged_expression)),
        seq('if', field("guard_expression", $._basic_expression)),
        seq(
          field("match_expression", choice($._basic_expression, $.tagged_expression)),
          'if', field("guard_expression", $._basic_expression)
        ),
      ),
      '|',
    ),

    piped_expression: $ => prec.left(PREC.PIPE, seq(
        field("left", $._expression),
        field("operator", choice($.pipe_operator, $.optional_pipe_operator)),
        field("right", $._expression),
    )),

    pipe_operator: $ => '|>',
    optional_pipe_operator: $ => seq('?', '|>'),


    // -------------------------------------
    // Literals
    // literals are the simplest expressions
    // -------------------------------------

    literal: $ => choice(
      $.nothing,
      $.never,
      $.special,
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
          $.additive_operator,
          $.not_operator,
          $.bitwise_not_operator,
        )),
        field("operand", $._basic_expression),
      )
    ),
    // two simple expressions surrounding a arithmetic or logic operator
    binary_expression: $ => {
      const binary_operators = [
        [PREC.EXP, $.exponential_operator],
        [PREC.MULT, $.multiplicative_operator],
        [PREC.ADD, $.additive_operator],
        [PREC.BSHFT, $.bitwise_shift_operator],
        [PREC.BAND, $.bitwise_and_operator],
        [PREC.BOR, $.bitwise_or_operator],
        [PREC.COMP, $.comparative_operator],
        [PREC.AND, $.and_operator],
        [PREC.OR, $.or_operator],
      ];

      return choice(
        ...binary_operators.map(([precedence, operator]) =>
          prec.left(precedence,
            seq(
              field("left", $._basic_expression),
              field("operator", operator),
              field("right", $._basic_expression),
            )
          )
        )
      );
    },

    exponential_operator: $ => '^',
    multiplicative_operator: $ => choice('*', '/', '%'),
    additive_operator: $ => choice('+', '-'),
    bitwise_shift_operator: $ => choice('<<', '>>'),
    bitwise_not_operator: $ => '~',
    bitwise_and_operator: $ => '.&',
    bitwise_or_operator: $ => '.|',
    comparative_operator: $ => choice('=', '!=', '>', '>=', '<', '<='),
    not_operator: $ => 'not',
    and_operator: $ => 'and',
    or_operator: $ => 'or',
  }
});
