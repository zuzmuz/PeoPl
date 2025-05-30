/**
 * @file the peopl's language
 * @author zuzmuz <hamadeh0@gmail.com>
 * @license MIT
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check
//
const PREC = {
  FUNCTION: 30,
  PARENTHESIS: 20,
  UNARY: 10,
  MULT: 8,
  ADD: 6,
  COMP: 5,
  AND: 4,
  OR: 3,
  PIPE: 2,
  SUBPIPE: 1,
};

module.exports = grammar({
  name: "peopl",

  extras: $ => [
    $.comment, /\s|\\\r?\n/,
  ],

  conflicts: $ => [
    [$.nothing_value, $.nothing_type],
  ],

  rules: {
    source_file: $ => repeat(
      seq(
        $._definition,
      )
    ),

    comment: _ => token(
      choice(
        seq('//', /(\\+(.|\r?\n)|[^\\\n])*/),
        seq(
          '/*',
          /[^*]*\*+([^/*][^*]*\*+)*/,
          '/',
        ),
      ),
    ),

    // Identifiers
    // -----------
     
    small_identifier: $ => /_*[a-z][a-zA-Z0-9_]*/,
    big_identifier: $ => /_*[A-Z][a-zA-Z0-9_]*/,

    scoped_big_identifier: $ => choice(
      field("identifier", $.big_identifier),
      prec.left(
        seq(
          field("scope", $.scoped_big_identifier),
          '::',
          field("identifier", $.big_identifier),
        )
      )
    ),

    scoped_identifier: $ => choice(
      field('identifier', $.small_identifier),
      seq(
        field('scope', $.scoped_big_identifier),
        '::',
        field('identifier', $.small_identifier),
      )
    ),


    // Definitions
    // -----------

    _definition: $ => choice(
      $.type_definition,
      $.value_definition,
    ),

    type_definition: $ => seq(
      field('identifier', $.scoped_big_identifier),
      optional(field('type_arguments', $.type_field_list)),
      ':',
      field('definition', $._type_specifier)
    ),

    value_definition: $ => seq(
      field("identifier", $.scoped_identifier),
      optional(field('type_arguments', $.type_field_list)),
      ":",
      field("expression", $._expression),
    ),

    // Types
    // -----

    _type_specifier: $ => choice(
      $.namespace,
      $.nothing_type,
      $.never_type,
      $.product,
      $.sum,
      $.subset,
      $.some,
      $.in,
      $.any,
      $.nominal,
      $.function,
    ),

    // homogeneous_product can only be part of a product
    homogeneous_product: $ => seq(
      field('type_specifier', $._type_specifier),
      '**',
      field('exponent', choice(
        $.int_literal,
        $.scoped_identifier
      ))
    ),

    tagged_type_specifier: $ => seq(
      field("identifier", $.small_identifier),
      ":",
      field("type", $._type_specifier),
    ),

    type_field: $ => choice(
      $.tagged_type_specifier, $._type_specifier, $.homogeneous_product
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


    namespace: _ => "namespace",

    nothing_type: _ => choice('Nothing', '_'),
    never_type: _ => 'Never',

    product: $ => $.type_field_list,

    sum: $ => seq(
      "choice",
      $.choice_type_field_list
    ),

    choice_type_field_list: $ => seq(
      '[',
        optional(
          seq(
            choice($.type_field, $.small_identifier),
            repeat(
              seq(',', choice($.type_field, $.small_identifier))
            ),
            optional(','),
          ),
        ),
      ']'
    ),

    subset: $ => seq(
      "subset",
      optional(field('protocol', $.type_field_list))
    ),

    subset_intersection: $ => choice(
      field('name', $.scoped_big_identifier),
      seq(
        field('scope', $.subset_intersection),
        '&',
        field('name', $.scoped_big_identifier),
      )
    ),

    in: $ => seq(
      field("identifier", $.big_identifier),
      "in",
      field("subset", $.subset_intersection),
    ),

    some: $ => prec.left(seq(
      "some",
      field('subset', $.scoped_big_identifier),
      optional(field('alias', $.big_identifier))
    )),

    any: $ => seq(
      "any",
      field('subset', $.scoped_big_identifier),
    ),

    nominal: $ => seq(
      field('identifier', $.scoped_big_identifier),
      optional(field('type_arguments', $.type_field_list)),
    ),

    function: $ => seq(
      choice(
        seq('(', optional(field('input_type', $._type_specifier)), ')'),
        field('arguments', $.type_field_list),
        seq(
          '(', field('input_type', $._type_specifier), ')',
          field('arguments', $.type_field_list),
        ),
      ),
      '->',
      field('output_type', $._type_specifier)
    ),

    // Expression
    // ----------
    
    tagged_expression: $ => seq(
      field("identifier", $.small_identifier),
      ":",
      field("expression", $._expression),
    ),

    expression_list: $ => seq(
      '(',
        optional(
          seq(
            $._expression,
            repeat(
              seq(',', $._expression)
            ),
            optional(','),
          ),
        ),
      ')'
    ),

    _expression: $ => choice(
      $._simple_expression,
      $.tagged_expression,
      $.branched_expression,
      $.piped_expression
    ),

    call_expression: $ => prec.right(PREC.FUNCTION, seq(
      field("prefix", $._simple_expression),
      choice(
        field('type_arguments', $.type_field_list),
        field("arguments", $.expression_list),
        field('trailing_closure', $.function_body),
        seq(
          field("arguments", $.expression_list),
          field('trailing_closure', $.function_body),
        ),
        seq(
          field('type_arguments', $.type_field_list),
          field("arguments", $.expression_list),
        ),
        seq(
          field('type_arguments', $.type_field_list),
          field('trailing_closure', $.function_body),
        ),
        seq(
          field('type_arguments', $.type_field_list),
          field("arguments", $.expression_list),
          field('trailing_closure', $.function_body),
        ),
      ),
    )),

    initializer_expression: $ => seq(
      field("prefix", optional($.nominal)),
      field("arguments", $.expression_list),
    ),

    // Function Definitions
    // --------------------
    
    function_definition: $ => seq(
      optional(field("signature", $.function)),
      field("body", $.function_body),
    ),

    function_body: $ => seq(
      '{',
        $._expression,
      '}'
    ),

    nothing_value: _ => choice("nothing", '_'),
    never_value: _ => "never",

    _simple_expression: $ => choice(
      $.literal,
      $.unary_expression,
      $.binary_expression,
      $.scoped_identifier,
      $.parenthisized_expression,
      $.function_definition,
      $.call_expression,
      $.initializer_expression,
      $.access_expression,
      $.binding
    ),

    parenthisized_expression: $ => prec.left(PREC.PARENTHESIS, seq(
      '(',
      $._expression,
      ')',
    )),

    access_expression: $ => seq(
      field("prefix", $._simple_expression),
      '.',
      field("field", $.small_identifier),
    ),

    binding: $ => /\$_*[a-z][a-zA-Z0-9_]*/,

    // Literals
    // --------

    literal: $ => choice(
      $.nothing_value,
      $.never_value,
      $.int_literal,
      $.float_literal,
      $.string_literal,
      $.bool_literal,
    ),

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

    branched_expression: $ => prec.left(seq(
      $.branch,
      repeat(seq(',', $.branch)),
    )),

    branch: $ => seq(
      field("capture_group", $.branch_capture_group),
      field("body", $._simple_expression)
    ),

    branch_capture_group: $ => seq(
      '|', 
      choice(
        field("match_expression", choice($._simple_expression, $.tagged_expression)),
        seq('if', field("guard_expression", $._simple_expression)),
        seq(
          field("match_expression", choice($._simple_expression, $.tagged_expression)),
          'if', field("guard_expression", $._simple_expression)
        ),
      ),
      '|',
    ),

    piped_expression: $ => prec.left(PREC.PIPE, seq(
        field("left", $._expression),
        field("operator", $.pipe_operator),
        field("right", $._expression),
    )),

    pipe_operator: $ => '|>',
  }
});
