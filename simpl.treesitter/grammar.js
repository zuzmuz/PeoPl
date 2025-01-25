/**
 * @file a simpl programming language
 * @author zuzmuz <hamadehzaher0@gmail.com>
 * @license MIT
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check
//


const PREC = {
  PARAM: 20,
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
      $._expression,
    ),

    _declaration: $ => seq(
      choice(
        $.type_declaration,
        // $.meta_type_declaration,
        $.contract_declaration,
        $.function_declaration,
      ),
      '.',
      '\n',
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
      field("body", $._expression),
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

    _expression: $ => choice(
      $._simple_expression,
      $.subpipe_expression,
      $.pipe_expression,
      $.call_expression,
      $.looped_expression,
      // $.lambda_expression,
    ),

    _single_expression: $ => choice(
      $.int_literal,
      $.float_literal,
      $.string_literal,
      $.array_literal,
      $.true,
      $.false,
      $.field_identifier
    ),

    looped_expression: $ => seq(
      $.parenthised_expression,
      '^'
    ),

    parenthised_expression: $ => seq(
      '(',
      $._expression,
      ')',
    ),

    pipe_expression: $ => prec.left(PREC.PIPE, seq(
        field("left", $._expression),
        ';',
        field("right", choice(
          $._simple_expression,
          $.call_expression,
          $.subpipe_expression,
          $.looped_expression))
    )),

    subpipe_branch_expresssion: $ => seq(
      '|', field("capture_group", $._expression), '|',
      field("subpipe", choice(
        $._simple_expression,
        $.call_expression,
        $.looped_expression,
      ))
    ),

    subpipe_expression: $ => prec.left(PREC.SUBPIPE, seq(
      $.subpipe_branch_expresssion,
      repeat(seq(',', $.subpipe_branch_expresssion)),
      optional(seq(',', choice($.call_expression, $._simple_expression))),
    )),

    call_expression: $ => prec.left(PREC.PIPE, seq(
        field("callee", choice($.field_identifier, $.type_identifier)),
        field("params", optional($.param_list_call)),
    )),

    param_list_call: $ => prec.left(PREC.PARAM, repeat1($.param_definition)),

    param_definition: $ => seq(
      field("name", $.field_identifier),
      ":",
      field("value", $._simple_expression),
    ),

    _simple_expression: $ => choice(
        $._single_expression,
        $.unary_expression,
        $.binary_expression,
        $.parenthised_expression,
    ),

    unary_expression: $ => prec.left(PREC.UNARY,
      seq(
        field("operator", choice($.additive_operator, 'not')),
        field("operand", $._simple_expression),
      )
    ),

    lambda_expression: $ => seq(
      '{',
      optional(seq('|', $.lambda_argument_list, '|')),
      $._expression,
      '}'
    ),

    lambda_argument_list: $ => repeat1($.field_identifier),

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

    true: $ => 'true',
    false: $ => 'false',
    int_literal: $ => /\d+/,
    float_literal: $ => /\d+\.\d+/,
    string_literal: $ => /"[^"]*"/,
    array_literal: $ => seq('[', repeat($._simple_expression), ']'),

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
