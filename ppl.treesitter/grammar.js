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
  TYPES: 15,
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
        '..'
      )
    ),

    comment: _ => seq('** ', /(\\+(.|\r?\n)|[^\\\n])*/),

    _statement: $ => choice(
      $.namespace_state,
      $.implementation_statement,
      $.constants_statement,
      $._definition,
    ),

    namespace_state: $ => seq(
      'namespace',
      '[',
      seq(
        optional($.nominal_type),
        repeat(seq(',', $.nominal_type))
      ),
      ']'
    ),

    implementation_statement: $ => seq(
      $.nominal_type,
      '=',
      $.nominal_type,
    ),

    constants_statement: $ => seq(
      optional(seq($.nominal_type, '.')),
      $.argument_name,
      '=',
      $._simple_expression, //can be a simple expression
    ),

    // DEFEINTIONS
    // -----------
    
    _definition: $ => seq(
      choice(
        $.type_definition,
        $.function_definition,
      ),
    ),
    
    type_definition: $ => seq(
      'type',
      choice($.enum_type_definition, $.simple_type_definition)
    ),

    enum_type_definition: $ => seq(
      field('meta_type', $.nominal_type),
      field('case_type', repeat1($.simple_type_definition)),
    ),

    simple_type_definition: $ => seq(
      field('name', $.nominal_type),
      field("params", optional($.param_list)),
    ),

    param_list: $ => repeat1($.param_definition),
    param_definition: $ => seq(
      field("name", $.argument_name),
      ":",
      field("type", $.type_identifier),
      optional(seq(
        '(',
        field("default_value", $._simple_expression),
        ')',
      )),
      optional(',')
    ),

    argument_name: $ => choice('_', /_*[a-z][a-zA-Z0-9_]*/),
    type_name: $ => /_*[A-Z][a-zA-Z0-9_]*/,

    type_identifier: $ => choice(
      $.nothing,
      $.never,
      $.nominal_type,
      $.lambda_structural_type,
      $.tuple_structural_type,
    ),

    nominal_type: $ => prec.left(PREC.TYPES, seq(
      $.flat_nominal_type,
      repeat(seq('::', $.flat_nominal_type))
    )),

    flat_nominal_type: $ => prec.left(PREC.TYPES,seq(
      field('type_name', $.type_name),
      field('type_arguments', optional($.type_arguments)),
    )),


    type_arguments: $ => seq(
      '<',
      seq($.type_identifier, repeat(seq(',', $.type_identifier))),
      '>',
    ),


    tuple_structural_type: $ => seq(
      '[',
        seq($.type_identifier, repeat(seq(',', $.type_identifier))),
      ']'
    ),

    lambda_structural_type: $ => seq(
      '{',
      field('input_type', optional(seq(
        $.type_identifier,
        repeat(seq(',', $.type_identifier))
      ))),
      '}',
      '->',
      field('return_type', $.type_identifier),
    ),

    function_definition: $ => seq(
      'func',
      optional(seq('(', field("input_type", $.type_identifier), ')')),
      field("scope", optional(seq($.nominal_type, '.'))),
      field("name", $.argument_name),
      field("params", seq('(', optional($.param_list), ')')),
      '=>',
      field("output_type", $.type_identifier),
      field("body", $._expression),
    ),

    // -----------
    // EXPRESSIONS
    // -----------

    _expression: $ => choice(
      $._simple_expression,
      $.branched_expression,
      $.piped_expression,
    ),

    // simple expressions can be unambiguousely inserted anywhere
    _simple_expression: $ => choice(
        $._single_expression,
        $.unary_expression,
        $.binary_expression,
        $.tuple_literal,
        $.parenthisized_expression,
        $.lambda_expression,
        $.argument_name,
        $.call_expression,
        $.access_expression,
    ),
    
    // single expressions are usually single tokens
    _single_expression: $ => choice(
      $.nothing,
      $.never,
      $.int_literal,
      $.float_literal,
      $.string_literal,
      $.bool_literal,
    ),
    
    nothing: $ => 'Nothing',
    never: $ => 'Never',
    bool_literal: $ => choice('true', 'false'),
    int_literal: $ => /\d+/,
    float_literal: $ => /\d+\.\d+/,
    string_literal: $ => /"[^"]*"/,
    tuple_literal: $ => seq('[',
      $._expression,
      repeat(seq(',', $._expression)),
    ']'),

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

    parenthisized_expression: $ => seq(
      '(',
      $._expression,
      ')',
    ),

    // a call expression is not a simple expression and need to be paranthesised to be
    // unambiguousely inserted anywhere, it fits in special places
    // it is constructed by a callee which is the command name
    // and a list of param calls
    call_expression: $ => seq(
      field("command", choice($._simple_expression, $.nominal_type)),
      '(',
      field("params", optional($.call_param_list)),
      ')',
    ),
    // a call param list is the list of arguments to pass to a command
    // the only exist in a call expression
    // it is a list of call params
    call_param_list: $ => repeat1($.call_param),
    
    // a call param is a pair of param name and a simple expression
    // non simple expression needs to be parenthised to be unambiguousely
    // inserted as param values
    call_param: $ => seq(
      field("name", $.argument_name),
      ":",
      field("value", $._simple_expression),
      optional(',')
    ),

    // the pipe expression is a binary expression
    // 2 expressions separated by the pipe operator
    piped_expression: $ => prec.left(PREC.PIPE, seq(
        field("left", $._expression),
        field("operator", $.pipe_operator),
        field("right", $._expression),
    )),

    pipe_operator: $ => choice('?', ';'),

    // a subpipe is one contained expression
    // it can contain multiple subpipe branch expression separated by ,
    // the last branch can be a call or a simple expression
    // all the other branches need to be a subpipe branch expressions
    branched_expression: $ => prec.left(PREC.SUBPIPE, seq(
      $.branch_expression,
      repeat(seq(',', $.branch_expression)),
      optional(seq(',', $._simple_expression)),
    )),

    // a subpipe branch is expression with a capture group
    // it is called a branch because it is made to branch out
    // the subpipe.
    // it has a capture group followed by the subpipe body
    // the subpipe body can be a simple or a call expression
    // or a looped expression which is just are regular parenthesized expression
    // followed by ^
    branch_expression: $ => seq(
      '|', field("capture_group", $.capture_group), '|',
      field("body", choice(
        $._simple_expression,
        $.looped_expression,
      ))
    ),

    capture_group: $ => seq(
      choice($._simple_expression, $.nominal_type),
      repeat(seq(',', $._simple_expression)),
    ),


    looped_expression: $ => seq(
      $.parenthisized_expression,
      '^'
    ),

    lambda_expression: $ => seq(
      '{',
       $._expression,
      '}'
    ),

    access_expression: $ => seq(
      choice($._simple_expression, $.nominal_type),
      '.',
      $.argument_name,
    ),
  }
});
