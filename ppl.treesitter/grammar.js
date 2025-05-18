/**
 * @file the peopl's language
 * @author zuzmuz <hamadeh0@gmail.com>
 * @license MIT
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check
//
const PREC = {
  FUNC: 20,
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
    [$.value_field_list, $.expression],
    [$.value_field_list, $.parenthisized_expression]
  ],

  rules: {
    source_file: $ => repeat(
      seq(
        $.definition,
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

    // DEFINITIONS
    // -----------
     
    small_identifier: $ => token(choice('_', /_*[a-z][a-zA-Z0-9_]*/)),
    big_identifier: $ => /_*[A-Z][a-zA-Z0-9_]*/,

    definition: $ => choice(
      $.type_definition,
      $.value_field,
    ),

    type_definition: $ => seq(
      field('identifier', $.big_identifier),
      ':',
      field('definition', $.type_specifier)
    ),

    type_specifier: $ => choice(
      $.product,
      $.sum,
      $.subset,
      $.some,
      $.any,
      $.nominal,
      $.function,
    ),

    product: $ => $.type_field_list,
    sum: $ => seq(
      'choice',
      $.type_field_list
    ),

    subset: $ => seq(
      'subset',
      optional(field('protocol', $.type_field_list))
    ),

    some: $ => prec.left(seq(
      'some',
      field('subset', $.big_identifier),
      optional(field('alias', $.big_identifier))
    )),

    any: $ => seq(
      'any',
      field('subset', $.big_identifier)
    ),

    nominal: $ => seq(
      field('identifier', $.big_identifier),
      optional(field('type_arguments', $.type_field_list)),
    ),

    function: $ => seq(
      choice(
        seq('(', optional(field('input_type', $.type_specifier)), ')'),
        field('arguments', $.type_field_list),
        seq(
          '(', field('input_type', $.type_specifier), ')',
          field('arguments', $.type_field_list),
        ),
      ),
      '->',
      field('output_type', $.type_specifier)
    ),

    type_field: $ => seq(
      field("identifier", $.small_identifier),
      ":",
      field("type", $.type_specifier),
    ),


    type_field_list: $ => seq(
      '[',
        optional(
          seq(
           choice($.type_field, $.type_specifier),
           repeat(
             seq(',', choice( $.type_field, $.type_specifier))
           ),
           optional(','),
          ),
        ),
      ']'
    ),

    // Expression
    // ----------

    value_field: $ => seq(
      field("identifier", $.small_identifier),
      ":",
      field("expression", $.expression),
    ),

    value_field_list: $ => seq(
      '(',
        optional(
          seq(
           choice($.value_field, $.expression),
           repeat(
             seq(',', choice( $.value_field, $.expression))
           ),
           optional(','),
          ),
        ),
      ')'
    ),

    expression: $ => choice(
      $._simple_expression,
      $.value_field,
      $.branched_expression,
      $.piped_expression
    ),

    call_expression: $ => seq(
      field("prefix", $._simple_expression),
      field("arguments", $.value_field_list),
    ),

    initializer_expression: $ => seq(
      field("prefix", optional($.nominal)),
      field("arguments", $.value_field_list),
    ),

    // Function Definitions
    // --------------------
    
    function_definition: $ => seq(
      optional(field("signature", $.function)),
      field("body", $.function_body),
    ),

    function_body: $ => seq(
      '{',
        $.expression,
      '}'
    ),

    nothing: _ => 'nothing',
    never: _ => 'never',

    _simple_expression: $ => choice(
      $.literal,
      $.unary_expression,
      $.binary_expression,
      $.small_identifier,
      $.parenthisized_expression,
      $.function_definition,
      $.call_expression,
      $.initializer_expression,
      $.access_expression,
      $.binding
    ),

    parenthisized_expression: $ => seq(
      '(',
      $.expression,
      ')',
    ),

    access_expression: $ => seq(
      field("prefix", $._simple_expression),
      '.',
      field("field", $.small_identifier),
    ),

    binding: $ => seq('$', $.small_identifier),

    // Literals
    // --------

    literal: $ => choice(
      $.nothing,
      $.never,
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
    bool_literal: $ => choice('true', 'false'),

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
      '|', 
      field("match_expression", $._simple_expression),
      optional(seq(':', field("guard_expression", $._simple_expression))),
      '|',
      field("body",
        choice(
          $._simple_expression,
          $.looped_expression,
        )
      )
    ),

    looped_expression: $ => seq(
      $.parenthisized_expression,
      '^'
    ),

    piped_expression: $ => prec.left(PREC.PIPE, seq(
        field("left", $.expression),
        field("operator", $.pipe_operator),
        field("right", $.expression),
    )),

    pipe_operator: $ => '|>',
  }
});
