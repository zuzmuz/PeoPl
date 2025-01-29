/**
 * @file the peopl's language
 * @author zuzmuz <hamadeh0@gmail.com>
 * @license MIT
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check
//
const PREC = {
  ACCESS: 30,
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
  name: "peopl",

  extras: $ => [
    $.comment, /\s|\\\r?\n/,
  ],

  rules: {
    source_file: $ => repeat(
      seq(
        $._statement,
        '..',
        '\n',
      )
    ),
    comment: _ => seq('** ', /(\\+(.|\r?\n)|[^\\\n])*/),
    _statement: $ => choice(
      $._definition,
      $.implementation_statement,
      $.constants_statement,
    ),

    implementation_statement: $ => seq(
      $.type_identifier,
      '=',
      $.type_identifier,
    ),

    constants_statement: $ => seq(
      $.field_identifier,
      '=',
      $._single_expression, //can be a simple expression
    ),

    _definition: $ => seq(
      choice(
        $.type_definition,
        $.function_definition,
      ),
    ),
    
    type_definition: $ => seq(
      'type',
      choice($.meta_type_definition, $.simple_type_definition)
    ),

    meta_type_definition: $ => seq(
      field('meta_type', choice($.specific_nominal_type, $.generic_nominal_type)),
      field('case_type', repeat1($.simple_type_definition)),
    ),

    simple_type_definition: $ => prec.left(seq(
      field('name', choice($.specific_nominal_type, $.generic_nominal_type)),
      field("params", optional($.param_list)),
    )),

    param_list: $ => prec.left(PREC.PARAM, repeat1($.param_definition)),
    param_definition: $ => seq(
      field("name", $.field_identifier),
      ":",
      field("type", $.type_identifier),
    ),

    specific_nominal_type: $ => prec.left(seq(
      /_*[A-Z][a-zA-Z0-9_]*/,
      repeat(seq('.', /_*[A-Z][a-zA-Z0-9_]*/))
    )),

    type_identifier: $ => choice(
      $.specific_nominal_type,
      $.generic_nominal_type,
      $.lambda_structural_type,
      $.tuple_structural_type,
    ),

    tuple_structural_type: $ => seq(
      '[',
        repeat($.type_identifier),
      ']'
    ),

    generic_nominal_type: $ => seq(
      field('generic_type', $.specific_nominal_type),
      '<',
      field('associated_type', repeat($.type_identifier)),
      '>'
    ),

    lambda_structural_type: $ => seq(
      '{',
      field('input_type', repeat($.type_identifier)),
      '}',
      field('return_type', $.type_identifier),
    ),

    field_identifier: $ => choice(
      /[a-z_][a-zA-Z0-9_]*/,
      seq(repeat(seq($.specific_nominal_type, '.')), /[a-z_][a-zA-Z0-9_]*/)
    ),

    function_definition: $ => seq(
      'func',
      field("input_type", optional($.type_identifier)),
      field("name", $.field_identifier),
      field("params", optional($.param_list)),
      field("output_type", $.type_identifier),
      field("body", $._expression),
    ),

    // -----------
    // EXPRESSIONS
    // -----------

    _expression: $ => choice(
      $._simple_expression,
      $.call_expression,
      $.branched_expression,
      $.piped_expression,
    ),

    // simple expressions can be unambiguousely inserted anywhere
    _simple_expression: $ => choice(
        $._single_expression,
        $.unary_expression,
        $.binary_expression,
        $.tuple_literal,
        $.parenthised_expression,
        $.lambda_expression,
        $.field_identifier,
        $.accessed_identifier,
    ),
    
    // single expressions are usually single tokens
    _single_expression: $ => choice(
      $.int_literal,
      $.float_literal,
      $.string_literal,
      $.bool_literal,
    ),

    bool_literal: $ => choice('true', 'false'),
    int_literal: $ => /\d+/,
    float_literal: $ => /\d+\.\d+/,
    string_literal: $ => /"[^"]*"/,
    tuple_literal: $ => seq('[',
      choice($.call_expression, $._simple_expression),
      repeat(seq(',', choice($.call_expression, $._simple_expression))), ']'),

    // a unary operator followed by a simple expression 
    unary_expression: $ => prec.left(PREC.UNARY,
      seq(
        field("operator", choice($.additive_operator, $.not_operator)),
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

    parenthised_expression: $ => seq(
      '(',
      $._expression,
      ')',
    ),

    // a call expression is not a simple expression and need to be paranthesised to be
    // unambiguousely inserted anywhere, it fits in special places
    // it is constructed by a callee which is the command name
    // and a list of param calls
    call_expression: $ => prec.left(PREC.PIPE, seq(
        field("callee", choice($.field_identifier, $.type_identifier)),
        field("params", optional($.call_param_list)),
    )),
    // a call param list is the list of arguments to pass to a command
    // the only exist in a call expression
    // it is a list of call params
    call_param_list: $ => repeat1($.call_param),
    
    // a call param is a pair of param name and a simple expression
    // non simple expression needs to be parenthised to be unambiguousely
    // inserted as param values
    call_param: $ => seq(
      field("name", $.field_identifier),
      ":",
      field("value", $._simple_expression),
    ),

    // the pipe expression is a binary expression
    // 2 expressions separated by the pipe operator
    piped_expression: $ => prec.left(PREC.PIPE, seq(
        field("left", $._expression),
        optional('?'), ';',
        field("right", $._expression),
    )),

    // a subpipe is one contained expression
    // it can contain multiple subpipe branch expression separated by ,
    // the last branch can be a call or a simple expression
    // all the other branches need to be a subpipe branch expressions
    branched_expression: $ => prec.left(PREC.SUBPIPE, seq(
      $.subpipe_branch_expresssion,
      repeat(seq(',', $.subpipe_branch_expresssion)),
      optional(seq(',', choice($.call_expression, $._simple_expression))),
    )),

    // a subpipe branch is expression with a capture group
    // it is called a branch because it is made to branch out
    // the subpipe.
    // it has a capture group followed by the subpipe body
    // the subpipe body can be a simple or a call expression
    // or a looped expression which is just are regular parenthesized expression
    // followed by ^
    subpipe_branch_expresssion: $ => seq(
      '|', field("capture_group", seq(
        choice($.call_expression, $._simple_expression),
        repeat(seq(',', choice($.call_expression, $._simple_expression))),
      )), '|',
      field("body", choice(
        $._simple_expression,
        $.call_expression,
        $.looped_expression,
      ))
    ),

    looped_expression: $ => seq(
      $.parenthised_expression,
      '^'
    ),

    lambda_expression: $ => seq(
      '{',
       $._expression,
      '}'
    ),

    accessed_identifier: $ => seq(
      $._simple_expression,
      '.',
      $.field_identifier
    ),
  }
});
