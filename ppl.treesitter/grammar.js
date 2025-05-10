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

    // DEFINITIONS
    // -----------
     
    identifier: $ => /[A-Za-z_][A-Za-z-0-9_]*/,
    keyword: $ => choice(
      "'record",
      "'choice",
      "'set",
      "'in",
      "'any",
      "'some"
    ),

    labeled_type: $ => seq(
      field("name", $.identifier),
      ":",
      field("type", $._type),
    ),

    labeled_types: $ => seq(
      '[',
        $.labeled_type,
        repeat(seq(',', $.labeled_type)),
        optional(','),
      ']'
    ),

    unlabeled_types: $ => seq(
      '[',
        $._type,
        repeat(seq(',', $._type)),
        optional(','),
      '['
    ),

    constrained_type: $ => seq(
      field("name", $.identifier),
      ':',
      "'in",
      field("set", $.identifier)
    ),

    _type_argument: $ => choice(
      $.identifier,
      $.labeled_type,
      $.constrained_type
    ),

    type_arguments: $ => seq(
      '<',
        repeat(seq($._type_argument, ',')),
        $._type_argument,
      '>'
    ),

    _definition: $ => choice(
        $.product_definition,
        $.sum_definition,
        $.function_definition,
        $.set_definition,
        $.implementation_definition
    ),

    _statement: $ => seq(
      field("identifier", $.identifier),
      ':',
      field("type_arguments", optional($.type_arguments)),
      field("definition", $._definition)
    ),
    
    // Type Definitions
    // ----------------
  
    record_definition: $ => seq(
      field('name', $.identifier),
      ':',
      'record',
      field('fields', choice(
        $.field_list,
        $.type_list
      ))
    ),

    choice_definition: $ => seq(
      field('name', $.identifier),
      ':',
      'choice',
      field('variants', choice(
        $.field_list,
        $.type_list
      ))
    ),

    // Function Definitions
    // --------------------
    
    function_definition: $ => seq(
      field("signature", $.function_signature),
      field("body", optional($.function_body)),
    ),

    function_signature: $ => seq(
      "'func",
      optional(seq('(', field("input_type", $._type), ')')),
      field('arguments', $.labeled_types),
      '->',
      field("output_type", $._type),
    ),

    function_body: $ => seq(
      '{',
        $._expression,
      '}'
    ),

    // Set Definitions
    // ---------------
    
    set_definition: _ => "'set",

    // Implementation Definitions
    // --------------------------
    
    implementation_definition: $ => seq(
      "'in",
      $.identifier
    ),

    // Types
    // -----
    //

    existential_type: $ => seq(
      "'any",
      $.nominal_type
    ),

    opaque_type: $ => seq(
      "'some",
      $.nominal_type
    ),

    _type: $ => choice(
      $.nothing,
      $.never,
      $.nominal_type,
      $.product_definition,
      $.sum_definition,
      $.function_signature,
      $.existential_type,
      $.opaque_type
    ),

    nominal_type: $ => choice(
      field('identifier', $.identifier),
    ),

    nothing: _ => 'nothing',
    never: _ => 'never',

    // -----------
    // EXPRESSIONS
    // -----------

    _expression: $ => "hi"
  }
});
