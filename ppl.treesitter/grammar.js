const PREC = {
  FUNCTION: 30,
  PARENTHESIS: 20,
  UNARY: 10,
  MULT: 8,
  ADD: 6,
  COMP: 5,
  AND: 4,
  OR: 3,
  SUBPIPE: 2,
  PIPE: 1,
};


module.exports = grammar({
  name: "peopl",

  extras: $ => [
    $.comment, /\s|\\\r?\n/,
  ],

  conflicts: $ => [
    // [$.nothing_value, $.nothing_type],
    // [$.nominal, $._simple_expression]
  ],

  rules: {
    source_file: $ => repeat(
      $.definition,
    ),

    // Comments
    // --------

    comment: _ => token(
      seq('//', /(\\+(.|\r?\n)|[^\\\n])*/),
    ),

    // Identifiers
    // -----------

    identifier: $ => /[a-zA-Z_][a-zA-Z0-9_]*/,

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

    // Definitions
    // -----------
    
    access_modifier: $ => choice(
      "'local",
      "'public"
    ),

    definition: $ => seq(
      optional(field("access_modifier", $.access_modifier)),
      field("identifier", $.qualified_identifier),
      optional(field("type_specifier", $._type_specifier)),
      ':',
      optional(
        seq(
          field("type_arguments", $.type_field_list),
          "=>",
        )
      ),
      field("definition", $._simple_expression)
    ),


    _type_specifier: $ => choice(
      $.record_type,
      $.choice_type,
      $.nominal,
      $.function_type
    ),

    nominal: $ => seq(
      field('identifier', $.qualified_identifier),
      optional(field('type_arguments', $.type_field_list)),
    ),

    record_type: $ => seq(
      "'record",
      $.type_field_list,
    ),

    choice_type: $ => seq(
      "'choice",
      $.type_field_list,
    ),

    function_type: $ => seq(
      "'func",
      optional(seq('(', field('input_type', $.type_field), ')')),
      $._function_arguments
    ),

    repeated_argument_list: $ => seq(
      $.type_field_list,
      repeat1($.type_field_list)
    ),

    _function_arguments: $ => choice(
      field('arguments', $.type_field_list),
      field('argument_list', $.repeated_argument_list)
    ),

    type_field_list: $ => seq(
      '[',
        optional(
          seq(
            $.type_field,
            repeat(
              seq(',', $.type_field)
            ),
            optional(','),
          ),
        ),
      ']'
    ),

    // homogeneous_product: $ => seq(
    //   field('type_specifier', $._type_specifier),
    //   '**',
    //   field('exponent', choice(
    //     $.int_literal,
    //     $.scoped_identifier
    //   ))
    // ),

    tagged_type_specifier: $ => seq(
      optional(field('hidden', '_')),
      field("identifier", $.identifier),
      field("type", $._type_specifier),
    ),

    type_field: $ => seq(
      optional(field('access_modifier', 'private')),
      choice(
        $.tagged_type_specifier,
        $._type_specifier,
        // $.homogeneous_product
      )
    ),

    _expression: $ => choice(
      $._simple_expression,
      $.tagged_expression
    ),

    tagged_expression: $ => seq(
      field("identifier", $.identifier),
      optional(field("type_specifier", $._type_specifier)),
      ":",
      field("expression", $._simple_expression)
    ),

    _simple_expression: $ => choice(
      $.literal,
      $.unary_expression,
      $.binary_expression,
      $._type_specifier,
      $.parenthisized_expression,
      $.binding,
      $.function_value
    ),

    function_value: $ => seq(
      optional(field("function_signature", $.function_type)),
      "{",
      $._expression,
      "}"
    ),


    parenthisized_expression: $ => prec.left(PREC.PARENTHESIS, seq(
      '(',
      $._expression,
      ')',
    )),

    binding: $ => /\$[a-zA-Z_][a-zA-Z0-9_]*/,

    // Literals
    // --------

    literal: $ => choice(
      $.nothing_value,
      // $.never_value,
      $.int_literal,
      $.float_literal,
      $.string_literal,
      $.bool_literal,
    ),

    nothing_value: _ => choice("nothing", '_'),
    // never_value: _ => "never",

    int_literal: $ => token(choice(
        /[0-9][0-9_]*/,
        /0x[0-9a-fA-F_]+/,
        /0b[01_]+/,
        /0o[0-7_]+/,
    )),

    float_literal: $ => /\d+\.\d+/,
    string_literal: $ => /"[^"]*"/,
    bool_literal: $ => choice("true", "false"),

    // Operators
    // ---------

    // a unary operator followed by a simple expression 
    unary_expression: $ => prec.left(PREC.UNARY,
      seq(
        field("operator", choice(
          $.multiplicative_operator,
          $.additive_operator,
          $.comparative_operator,
          $.and_operator,
          $.or_operator,
          $.not_operator,
        )),
        field("operand", $._simple_expression),
      )
    ),
    // two simple expressions surrounding a arithmetic or logic operator
    binary_expression: $ => choice(
      prec.left(PREC.MULT,
        seq(
          field("left", $._simple_expression),
          field("operator", $.multiplicative_operator),
          field("right", $._simple_expression),
        )
      ),
      prec.left(PREC.ADD,
        seq(
          field("left", $._simple_expression),
          field("operator", $.additive_operator),
          field("right", $._simple_expression),
        )
      ),
      prec.left(PREC.COMP,
        seq(
          field("left", $._simple_expression),
          field("operator", $.comparative_operator),
          field("right", $._simple_expression),
        )
      ),
      prec.left(PREC.AND,
        seq(
          field("left", $._simple_expression),
          field("operator", $.and_operator),
          field("right", $._simple_expression),
        )
      ),
      prec.left(PREC.OR,
        seq(
          field("left", $._simple_expression),
          field("operator", $.or_operator),
          field("right", $._simple_expression),
        )
      )
    ),

    multiplicative_operator: $ => choice('*', '/', '%'),
    additive_operator: $ => choice('+', '-'),
    comparative_operator: $ => choice('=', '!=', '>', '>=', '<', '<='),
    not_operator: $ => 'not',
    and_operator: $ => 'and',
    or_operator: $ => 'or',
  }
});







