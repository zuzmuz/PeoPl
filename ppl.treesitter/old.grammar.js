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

    _statement: $ => choice(
      $._definition,
    ),

    // DEFINITIONS
    // -----------
     
    small_identifier: $ => token(choice('_', /_*[a-z][a-zA-Z0-9_]*/)),
    big_identifier: $ => /_*[A-Z][a-zA-Z0-9_]*/,

    param_definition: $ => seq(
      field("name", $.small_identifier),
      ":",
      field("type", $._type),
    ),
    param_list: $ => seq(
      repeat1(seq($.param_definition, optional(',')))
    ),

    _definition: $ => seq(
      choice(
        $.type_definition,
        $.function_definition,
      ),
    ),
    
    // Type Definitions
    // ----------------
    
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
      field('params', optional($.param_list)),
    ),


    // Function Definitions
    // --------------------
    
    function_definition: $ => seq(
      'func',
      choice($.operator_overload_definition, $.normal_function_definition)
    ),

    normal_function_definition: $ => seq(
      optional(seq('(', field("input_type", $._type), ')')),
      field("name", $.scoped_identifier),
      seq('(', field("params", optional($.param_list)), ')'),
      '=>',
      field("output_type", $._type),
      optional(field("body", $._expression)),
    ),

    operator_overload_definition: $ => seq(
      optional(field("left_type", $.param_definition)),
      field("operator", choice($.multiplicative_operator, $.additive_operator, $.comparative_operator)),
      field("right_type", $.param_definition),
      '=>',
      field("output_type", $._type),
      optional(field("body", $._expression)),
    ),


    // Types
    // -----

    _type: $ => choice(
      $.nothing,
      $.never,
      $.nominal_type,
      $._tuple_structural_type,
    ),

    nominal_type: $ => choice(
      field("name", $.big_identifier),
      prec.left(PREC.ACCESS,
        seq(
          field("scope", $.nominal_type),
          '::',
          field('name', $.big_identifier)
        )
      )
    ),

    named_tuple_structural_type: $ => seq(
      '[',
        $.param_definition,
        repeat(seq(',', $.param_definition)),
        optional(','),
      ']'
    ),
    unnamed_tuple_structural_type: $ => seq(
      '[',
        $._type,
        repeat(seq(',', $._type)),
        optional(','),
      ']'
    ),

    _tuple_structural_type: $ => choice(
      $.unnamed_tuple_structural_type,
      $.named_tuple_structural_type
    ),

    // -----------
    // EXPRESSIONS
    // -----------

    _expression: $ => choice(
      $._simple_expression,
      $.branched_expression,
      $.piped_expression,
    ),

    nothing: $ => 'Nothing',
    never: $ => 'Never',
    int_literal: $ => token(choice(
        /[0-9][0-9_]*/,
        /0x[0-9a-fA-F_]+/,
        /0b[01_]+/,
        /0o[0-7_]+/,
    )),

    float_literal: $ => /\d+\.\d+/,
    string_literal: $ => /"[^"]*"/,
    bool_literal: $ => choice('true', 'false'),

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
    
    binding_name: $ => seq('$', $.small_identifier),

    _match_expression: $ => choice(
      $.literal,
      $.scoped_identifier,
      $.binding_name,
      $.tuple_binding_literal,
      $.type_binding
    ),

    tuple_binding_literal: $ => seq(
      '[',
        $._match_expression,
        repeat(seq(',', $._match_expression)),
        optional(','),
      ']'
    ),

    type_binding: $ => seq(
      field("prefix", $.nominal_type),
      optional(seq(
      '(',
        field("arguments", $.argument_list_binding),
      ')',
      ))
    ),

    argument_list_binding: $ => seq(
      $.argument_binding,
      repeat(seq(',', $.argument_binding))
    ),

    argument_binding: $ => seq(
      field("name", $.small_identifier),
      ":",
      field("value", $._match_expression),
    ),

    // simple expressions can be unambiguousely inserted anywhere
    _simple_expression: $ => choice(
        $.literal,
        $.unary_expression,
        $.binary_expression,
        $._tuple_literal,
        $.parenthisized_expression,
        $.lambda_expression,
        $.scoped_identifier,
        $.function_call_expression,
        $.type_initializer_expression,
        $.access_expression,
    ),
    
    // single expressions are usually single tokens
    literal: $ => choice(
      $.nothing,
      $.never,
      $.int_literal,
      $.float_literal,
      $.string_literal,
      $.bool_literal,
    ),

    parenthisized_expression: $ => seq(
      '(',
      $._expression,
      ')',
    ),

    
    unnamed_tuple_literal: $ => seq(
      '[',
        $._expression,
        repeat(seq(',', $._expression)),
        optional(','),
      ']'
    ),

    named_tuple_literal: $ => seq(
      '[',
        $.argument,
        repeat(seq(',', $.argument)),
        optional(','),
      ']'
    ),

    _tuple_literal: $ =>  choice(
      $.unnamed_tuple_literal,
      $.named_tuple_literal
    ),

    lambda_expression: $ => seq(
      '{',
       $._expression,
      '}'
    ),

    scoped_identifier: $ => choice(
      field('name', $.small_identifier),
      seq(
        field('scope', $.nominal_type),
        '::',
        field('name', $.small_identifier),
      )
    ),

    type_initializer_expression: $ => prec.right(PREC.PARAM, seq(
      field("prefix", $.nominal_type),
      '(',
      field("arguments", optional($.argument_list)),
      ')',
    )),


    function_call_expression: $ => prec.right(PREC.PARAM, seq(
      field("prefix", $._simple_expression),
      '(',
      field("arguments", optional($.argument_list)),
      ')',
    )),

    // a call param list is the list of arguments to pass to a command
    // the only exist in a call expression
    // it is a list of call params
    argument_list: $ => seq(
      $.argument,
      repeat(seq(',', $.argument))
    ),
    
    // a call param is a pair of param name and a simple expression
    // non simple expression needs to be parenthised to be unambiguousely
    // inserted as param values
    argument: $ => seq(
      field("name", $.small_identifier),
      ":",
      field("value", $._expression),
    ),
    
    // Precedences here are necessary for accessing parenthesized expression
    access_expression: $ => prec.left(PREC.ACCESS, seq(
      field("prefix", $._simple_expression),
      '.',
      field("field", $.small_identifier),
    )),

    // a subpipe is one contained expression
    // it can contain multiple subpipe branch expression separated by ,
    // the last branch can be a call or a simple expression
    // all the other branches need to be a subpipe branch expressions
    branched_expression: $ => prec.left(PREC.SUBPIPE, seq(
      $.branch_expression,
      repeat(seq(',', $.branch_expression)),
    )),

    // a subpipe branch is expression with a capture group
    // it is called a branch because it is made to branch out
    // the subpipe.
    // it has a capture group followed by the subpipe body
    // the subpipe body can be a simple or a call expression
    // or a looped expression which is just are regular parenthesized expression
    // followed by ^
    branch_expression: $ => seq(
      '|', 
      field("match_expression", $._match_expression),
      optional(seq(':', field("guard_expression", $._simple_expression))),
      '|',
      field("body", choice(
        $._simple_expression,
        $.looped_expression,
      ))
    ),

    looped_expression: $ => seq(
      $.parenthisized_expression,
      '^'
    ),


    // the pipe expression is a binary expression
    // 2 expressions separated by the pipe operator
    piped_expression: $ => prec.left(PREC.PIPE, seq(
        field("left", $._expression),
        field("operator", $.pipe_operator),
        field("right", $._expression),
    )),

    pipe_operator: $ => '|>',
  }
});
