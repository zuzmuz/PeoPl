/**
 * @file a simpl programming language
 * @author zuzmuz <hamadehzaher0@gmail.com>
 * @license MIT
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check
//


const PREC = {
  UNARY: 6,
  MULT: 5,
  ADD: 4,
  COMP: 3,
  AND: 2,
  OR: 1,
};

module.exports = grammar({
  name: "simpl",
  extras: $ => [
    $.comment, /\s|\\\r?\n/,
  ],

  rules: {
    source_file: $ => repeat($._statement),
    comment: _ => seq('* ', /(\\+(.|\r?\n)|[^\\\n])*/),
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
      field("type", $.type_identifier),
    ),

    type_identifier: $ => choice(
      /[A-Z][a-zA-Z0-9_]*/,
      $.inline_function_declaration,
    ),
    field_identifier: $ => /[a-z][a-zA-Z0-9_]*/,

    inline_function_declaration: $ => seq(
      '(',
      repeat($.param_declaration),
      ')',
      $.type_identifier,
    ),

    expression: $ => choice(
      $.single_expression,
      // $.unary_expression,
      // $.binary_expression,
      $.pipe_expression,
      $.call_expression,
      // $.parenthised_expression,
    ),

    single_expression: $ => choice(
      $.int_literal,
      $.float_literal,
      $.string_literal,
      $.true,
      $.false,
      $.field_identifier
    ),

    parenthised_expression: $ => seq(
      '(',
      $.expression,
      ')',
    ),

    pipe_expression: $ => prec.left(10, seq(
        field("field", $.expression),
        '|',
        $.call_expression,
    )),

    call_expression: $ => prec.left(11, seq(
        field("function", $.field_identifier),
        field("params", optional($.param_list_call)),
    )),

    param_list_call: $ => prec.left(12, repeat1($.param_definition)),

    param_definition: $ => seq(
      field("name", $.field_identifier),
      field("value", $.single_expression),
    ),

    unary_expression: $ => prec.left(PREC.UNARY,
      seq(
        field("operator", choice($.additive_operator, 'not')),
        field("operand", $.expression),
      )
    ),

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
