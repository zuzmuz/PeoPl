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
      $._declaration,
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

    _declaration: $ => seq(
      choice(
        $.type_declaration,
        $.function_declaration,
      ),
    ),
    
    type_declaration: $ => seq(
      'type',
      choice($.meta_type_declaration, $.simple_type_declaration)
    ),

    meta_type_declaration: $ => seq(
      field('meta_type', choice($.type_name, $.generic_type_identifier)),
      field('case_type', repeat1($.simple_type_declaration)),
    ),

    simple_type_declaration: $ => prec.left(seq(
      field('name', choice($.type_name, $.generic_type_identifier)),
      field("params", optional($.param_list)),
    )),

    function_declaration: $ => seq(
      'func',
      field("on_type", optional($.type_identifier)),
      field("name", $.field_identifier),
      field("params", optional($.param_list)),
      field("return", $.type_identifier),
      field("body", $._expression),
    ),

    param_list: $ => prec.left(PREC.PARAM, repeat1($.param_declaration)),
    param_declaration: $ => seq(
      field("name", $.field_identifier),
      ":",
      field("type", $.type_identifier),
    ),

    type_name: $ => prec.left(seq(
      /_*[A-Z][a-zA-Z0-9_]*/,
      repeat(seq('.', /_*[A-Z][a-zA-Z0-9_]*/))
    )),

    type_identifier: $ => choice(
      $.type_name,
      $.inline_function_declaration,
      $.tupled_type_identifer,
      $.generic_type_identifier,
    ),

    tupled_type_identifer: $ => prec.left(PREC.ACCESS, seq(
      '[',
        repeat($.type_identifier),
      ']'
    )),

    generic_type_identifier: $ => seq(
      field('generic_type', $.type_name),
      '<',
      field('associated_type', repeat($.type_identifier)),
      '>'
    ),

    inline_function_declaration: $ => seq(
      '{',
      field('input_type', repeat($.type_identifier)),
      '}',
      field('return_type', $.type_identifier),
    ),


    field_identifier: $ => choice(
      /[a-z_][a-zA-Z0-9_]*/,
      seq(repeat(seq($.type_name, '.')), /[a-z_][a-zA-Z0-9_]*/)
    ),


    // -----------
    // EXPRESSIONS
    // -----------

    _expression: $ => choice(
      $._simple_expression,
      $.call_expression,
      $.pipe_expression,
      $.subpipe_expression,
    ),

    // simple expressions can be unambiguousely inserted anywhere
    _simple_expression: $ => choice(
        $._single_expression,
        $.unary_expression,
        $.binary_expression,
        $.array_literal,
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
    array_literal: $ => seq('[', repeat($._simple_expression), ']'),

    // a unary operator followed by a simple expression 
    unary_expression: $ => prec.left(PREC.UNARY,
      seq(
        field("operator", choice($.additive_operator, 'not')),
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
          field("operator", 'and'),
          field("right", $._simple_expression),
        )
      ),
      prec.left(PREC.OR,
        seq(
          field("left", $._simple_expression),
          field("operator", 'or'),
          field("right", $._simple_expression),
        )
      )
    ),

    multiplicative_operator: $ => choice('*', '/', '%'),
    additive_operator: $ => choice('+', '-'),
    comparative_operator: $ => choice('=', '!=', '>', '>=', '<', '<='),

    operator: $ => choice(
      $.additive_operator, 
      $.multiplicative_operator,
      $.comparative_operator,
      'and', 'or'
    ),

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
    pipe_expression: $ => prec.left(PREC.PIPE, seq(
        field("left", $._expression),
        optional('?'), ';',
        field("right", $._expression),
    )),

    // a subpipe is one contained expression
    // it can contain multiple subpipe branch expression separated by ,
    // the last branch can be a call or a simple expression
    // all the other branches need to be a subpipe branch expressions
    subpipe_expression: $ => prec.left(PREC.SUBPIPE, seq(
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
