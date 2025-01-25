/**
 * @file a simpl programming language
 * @author zuzmuz <hamadehzaher0@gmail.com>
 * @license MIT
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check
//


const PREC = {
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
  name: "simpl",
  extras: $ => [
    $.comment, /\s|\\\r?\n/,
  ],

  rules: {
    source_file: $ => repeat($._statement),
    comment: _ => seq('** ', /(\\+(.|\r?\n)|[^\\\n])*/),
    _statement: $ => choice(
      $._declaration,
      $.expression,
    ),

    _declaration: $ => seq(
      choice(
        $.type_declaration,
        // $.meta_type_declaration,
        $.contract_declaration,
        $.function_declaration,
      ),
      '.\n',
    ),
    
    type_declaration: $ => seq(
      'type',
      field("name", $.type_identifier),
      field("params", optional($.param_list)),
    ),

    contract_declaration: $ => seq(
      'contract',
      field("name", $.type_identifier),
      field("params", optional($.param_list)),
    ),

    function_declaration: $ => seq(
      'func',
      field("on_type", optional($.type_identifier)),
      field("name", $.field_identifier),
      field("params", optional($.param_list)),
      field("return", $.type_identifier),
      field("body", $.expression),
    ),

    param_list: $ => repeat1($.param_declaration),
    param_declaration: $ => seq(
      field("name", $.field_identifier),
      ":",
      field("type", $.type_identifier),
    ),

    type_identifier: $ => choice(
      /[A-Z][a-zA-Z0-9_]*/,
      $.inline_function_declaration,
    ),
    field_identifier: $ => /[a-z][a-zA-Z0-9_]*/,

    inline_function_declaration: $ => seq(
      '{',
      repeat($.param_declaration),
      '}',
      $.type_identifier,
    ),

    expression: $ => choice(
      $.single_expression,
      $.unary_expression,
      $.binary_expression,
      $.branchsubpipe_expression,
      $.pipe_expression,
      $.call_expression,
      // $.lambda_expression,
      $.parenthised_expression,
    ),

    single_expression: $ => choice(
      $.int_literal,
      $.float_literal,
      $.string_literal,
      $.array_literal,
      $.true,
      $.false,
      $.field_identifier
    ),

    parenthised_expression: $ => seq(
      '(',
      $.expression,
      ')',
    ),

    pipe_expression: $ => prec.left(PREC.PIPE, seq(
        field("field", $.expression),
        ';',
        choice(
          $.single_expression,
          $.call_expression,
          $.branchsubpipe_expression,
          $.parenthised_expression)
    )),

    subpipe_expresssion: $ => seq(
      '|', $.expression, '|',
      choice($.single_expression, $.call_expression, $.parenthised_expression)
    ),

    branchsubpipe_expression: $ => prec.left(PREC.SUBPIPE, seq(
      $.subpipe_expresssion, 
      repeat(seq(',', $.subpipe_expresssion)),
      optional(seq(',', choice($.call_expression, $.single_expression)),
    )),

    call_expression: $ => prec.left(PREC.PIPE, seq(
        field("function", $.field_identifier),
        field("params", optional($.param_list_call)),
    )),

    param_list_call: $ => prec.left(PREC.PIPE, repeat1($.param_definition)),

    param_definition: $ => seq(
      field("name", $.field_identifier),
      ":",
      field("value", choice(
        $.single_expression,
        $.parenthised_expression,
        // $.lambda_expression,
      )),
    ),

    unary_expression: $ => prec.left(PREC.UNARY,
      seq(
        field("operator", choice($.additive_operator, 'not')),
        field("operand", $.expression),
      )
    ),

    lambda_expression: $ => seq(
      '{',
      optional(seq('|', $.lambda_argument_list, '|')),
      $.expression,
      '}'
    ),

    lambda_argument_list: $ => repeat1($.field_identifier),

    binary_expression: $ => choice(
      prec.left(PREC.MULT,
        seq(
          field("left", $.expression),
          field("operator", $.multiplicative_operator),
          field("right", $.expression),
        )
      ),
      prec.left(PREC.ADD,
        seq(
          field("left", $.expression),
          field("operator", $.additive_operator),
          field("right", $.expression),
        )
      ),
      prec.left(PREC.COMP,
        seq(
          field("left", $.expression),
          field("operator", $.comparative_operator),
          field("right", $.expression),
        )
      ),
      prec.left(PREC.AND,
        seq(
          field("left", $.expression),
          field("operator", $.and_operator),
          field("right", $.expression),
        )
      ),
      prec.left(PREC.OR,
        seq(
          field("left", $.expression),
          field("operator", $.or_operator),
          field("right", $.expression),
        )
      )
    ),

    true: $ => 'true',
    false: $ => 'false',
    int_literal: $ => /\d+/,
    float_literal: $ => /\d+\.\d+/,
    string_literal: $ => /"[^"]*"/,
    array_literal: $ => seq('[', repeat($.expression), ']'),

    multiplicative_operator: $ => choice('*', '/', '%'),
    additive_operator: $ => choice('+', '-'),
    comparative_operator: $ => choice('=', '!=', '>', '>=', '<', '<='),
    and_operator: $ => 'and',
    or_operator: $ => 'or',

    operator: $ => choice(
      $.additive_operator, 
      $.multiplicative_operator,
      $.comparative_operator,
      $.and_operator,
      $.or_operator,
    ),
  }
});
