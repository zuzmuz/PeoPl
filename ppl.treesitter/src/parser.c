#include "tree_sitter/parser.h"

#if defined(__GNUC__) || defined(__clang__)
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#endif

#define LANGUAGE_VERSION 14
#define STATE_COUNT 76
#define LARGE_STATE_COUNT 2
#define SYMBOL_COUNT 48
#define ALIAS_COUNT 0
#define TOKEN_COUNT 24
#define EXTERNAL_TOKEN_COUNT 0
#define FIELD_COUNT 12
#define MAX_ALIAS_SEQUENCE_LENGTH 7
#define PRODUCTION_ID_COUNT 13

enum ts_symbol_identifiers {
  sym_comment = 1,
  sym_identifier = 2,
  anon_sym_COLON = 3,
  anon_sym_LBRACK = 4,
  anon_sym_COMMA = 5,
  anon_sym_RBRACK = 6,
  anon_sym_SQUOTEin = 7,
  anon_sym_LT = 8,
  anon_sym_GT = 9,
  anon_sym_SQUOTErecord = 10,
  anon_sym_SQUOTEchoice = 11,
  anon_sym_SQUOTEfunc = 12,
  anon_sym_LPAREN = 13,
  anon_sym_RPAREN = 14,
  anon_sym_DASH_GT = 15,
  anon_sym_LBRACE = 16,
  anon_sym_RBRACE = 17,
  sym_set_definition = 18,
  anon_sym_SQUOTEany = 19,
  anon_sym_SQUOTEsome = 20,
  sym_nothing = 21,
  sym_never = 22,
  anon_sym_hi = 23,
  sym_source_file = 24,
  sym_labeled_type = 25,
  sym_labeled_types = 26,
  sym_unlabeled_types = 27,
  sym_constrained_type = 28,
  sym__type_argument = 29,
  sym_type_arguments = 30,
  sym__definition = 31,
  sym__statement = 32,
  sym_product_definition = 33,
  sym_sum_definition = 34,
  sym_function_definition = 35,
  sym_function_signature = 36,
  sym_function_body = 37,
  sym_implementation_definition = 38,
  sym_existential_type = 39,
  sym_opaque_type = 40,
  sym__type = 41,
  sym_nominal_type = 42,
  sym__expression = 43,
  aux_sym_source_file_repeat1 = 44,
  aux_sym_labeled_types_repeat1 = 45,
  aux_sym_unlabeled_types_repeat1 = 46,
  aux_sym_type_arguments_repeat1 = 47,
};

static const char * const ts_symbol_names[] = {
  [ts_builtin_sym_end] = "end",
  [sym_comment] = "comment",
  [sym_identifier] = "identifier",
  [anon_sym_COLON] = ":",
  [anon_sym_LBRACK] = "[",
  [anon_sym_COMMA] = ",",
  [anon_sym_RBRACK] = "]",
  [anon_sym_SQUOTEin] = "'in",
  [anon_sym_LT] = "<",
  [anon_sym_GT] = ">",
  [anon_sym_SQUOTErecord] = "'record",
  [anon_sym_SQUOTEchoice] = "'choice",
  [anon_sym_SQUOTEfunc] = "'func",
  [anon_sym_LPAREN] = "(",
  [anon_sym_RPAREN] = ")",
  [anon_sym_DASH_GT] = "->",
  [anon_sym_LBRACE] = "{",
  [anon_sym_RBRACE] = "}",
  [sym_set_definition] = "set_definition",
  [anon_sym_SQUOTEany] = "'any",
  [anon_sym_SQUOTEsome] = "'some",
  [sym_nothing] = "nothing",
  [sym_never] = "never",
  [anon_sym_hi] = "hi",
  [sym_source_file] = "source_file",
  [sym_labeled_type] = "labeled_type",
  [sym_labeled_types] = "labeled_types",
  [sym_unlabeled_types] = "unlabeled_types",
  [sym_constrained_type] = "constrained_type",
  [sym__type_argument] = "_type_argument",
  [sym_type_arguments] = "type_arguments",
  [sym__definition] = "_definition",
  [sym__statement] = "_statement",
  [sym_product_definition] = "product_definition",
  [sym_sum_definition] = "sum_definition",
  [sym_function_definition] = "function_definition",
  [sym_function_signature] = "function_signature",
  [sym_function_body] = "function_body",
  [sym_implementation_definition] = "implementation_definition",
  [sym_existential_type] = "existential_type",
  [sym_opaque_type] = "opaque_type",
  [sym__type] = "_type",
  [sym_nominal_type] = "nominal_type",
  [sym__expression] = "_expression",
  [aux_sym_source_file_repeat1] = "source_file_repeat1",
  [aux_sym_labeled_types_repeat1] = "labeled_types_repeat1",
  [aux_sym_unlabeled_types_repeat1] = "unlabeled_types_repeat1",
  [aux_sym_type_arguments_repeat1] = "type_arguments_repeat1",
};

static const TSSymbol ts_symbol_map[] = {
  [ts_builtin_sym_end] = ts_builtin_sym_end,
  [sym_comment] = sym_comment,
  [sym_identifier] = sym_identifier,
  [anon_sym_COLON] = anon_sym_COLON,
  [anon_sym_LBRACK] = anon_sym_LBRACK,
  [anon_sym_COMMA] = anon_sym_COMMA,
  [anon_sym_RBRACK] = anon_sym_RBRACK,
  [anon_sym_SQUOTEin] = anon_sym_SQUOTEin,
  [anon_sym_LT] = anon_sym_LT,
  [anon_sym_GT] = anon_sym_GT,
  [anon_sym_SQUOTErecord] = anon_sym_SQUOTErecord,
  [anon_sym_SQUOTEchoice] = anon_sym_SQUOTEchoice,
  [anon_sym_SQUOTEfunc] = anon_sym_SQUOTEfunc,
  [anon_sym_LPAREN] = anon_sym_LPAREN,
  [anon_sym_RPAREN] = anon_sym_RPAREN,
  [anon_sym_DASH_GT] = anon_sym_DASH_GT,
  [anon_sym_LBRACE] = anon_sym_LBRACE,
  [anon_sym_RBRACE] = anon_sym_RBRACE,
  [sym_set_definition] = sym_set_definition,
  [anon_sym_SQUOTEany] = anon_sym_SQUOTEany,
  [anon_sym_SQUOTEsome] = anon_sym_SQUOTEsome,
  [sym_nothing] = sym_nothing,
  [sym_never] = sym_never,
  [anon_sym_hi] = anon_sym_hi,
  [sym_source_file] = sym_source_file,
  [sym_labeled_type] = sym_labeled_type,
  [sym_labeled_types] = sym_labeled_types,
  [sym_unlabeled_types] = sym_unlabeled_types,
  [sym_constrained_type] = sym_constrained_type,
  [sym__type_argument] = sym__type_argument,
  [sym_type_arguments] = sym_type_arguments,
  [sym__definition] = sym__definition,
  [sym__statement] = sym__statement,
  [sym_product_definition] = sym_product_definition,
  [sym_sum_definition] = sym_sum_definition,
  [sym_function_definition] = sym_function_definition,
  [sym_function_signature] = sym_function_signature,
  [sym_function_body] = sym_function_body,
  [sym_implementation_definition] = sym_implementation_definition,
  [sym_existential_type] = sym_existential_type,
  [sym_opaque_type] = sym_opaque_type,
  [sym__type] = sym__type,
  [sym_nominal_type] = sym_nominal_type,
  [sym__expression] = sym__expression,
  [aux_sym_source_file_repeat1] = aux_sym_source_file_repeat1,
  [aux_sym_labeled_types_repeat1] = aux_sym_labeled_types_repeat1,
  [aux_sym_unlabeled_types_repeat1] = aux_sym_unlabeled_types_repeat1,
  [aux_sym_type_arguments_repeat1] = aux_sym_type_arguments_repeat1,
};

static const TSSymbolMetadata ts_symbol_metadata[] = {
  [ts_builtin_sym_end] = {
    .visible = false,
    .named = true,
  },
  [sym_comment] = {
    .visible = true,
    .named = true,
  },
  [sym_identifier] = {
    .visible = true,
    .named = true,
  },
  [anon_sym_COLON] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_LBRACK] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_COMMA] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_RBRACK] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_SQUOTEin] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_LT] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_GT] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_SQUOTErecord] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_SQUOTEchoice] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_SQUOTEfunc] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_LPAREN] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_RPAREN] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_DASH_GT] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_LBRACE] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_RBRACE] = {
    .visible = true,
    .named = false,
  },
  [sym_set_definition] = {
    .visible = true,
    .named = true,
  },
  [anon_sym_SQUOTEany] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_SQUOTEsome] = {
    .visible = true,
    .named = false,
  },
  [sym_nothing] = {
    .visible = true,
    .named = true,
  },
  [sym_never] = {
    .visible = true,
    .named = true,
  },
  [anon_sym_hi] = {
    .visible = true,
    .named = false,
  },
  [sym_source_file] = {
    .visible = true,
    .named = true,
  },
  [sym_labeled_type] = {
    .visible = true,
    .named = true,
  },
  [sym_labeled_types] = {
    .visible = true,
    .named = true,
  },
  [sym_unlabeled_types] = {
    .visible = true,
    .named = true,
  },
  [sym_constrained_type] = {
    .visible = true,
    .named = true,
  },
  [sym__type_argument] = {
    .visible = false,
    .named = true,
  },
  [sym_type_arguments] = {
    .visible = true,
    .named = true,
  },
  [sym__definition] = {
    .visible = false,
    .named = true,
  },
  [sym__statement] = {
    .visible = false,
    .named = true,
  },
  [sym_product_definition] = {
    .visible = true,
    .named = true,
  },
  [sym_sum_definition] = {
    .visible = true,
    .named = true,
  },
  [sym_function_definition] = {
    .visible = true,
    .named = true,
  },
  [sym_function_signature] = {
    .visible = true,
    .named = true,
  },
  [sym_function_body] = {
    .visible = true,
    .named = true,
  },
  [sym_implementation_definition] = {
    .visible = true,
    .named = true,
  },
  [sym_existential_type] = {
    .visible = true,
    .named = true,
  },
  [sym_opaque_type] = {
    .visible = true,
    .named = true,
  },
  [sym__type] = {
    .visible = false,
    .named = true,
  },
  [sym_nominal_type] = {
    .visible = true,
    .named = true,
  },
  [sym__expression] = {
    .visible = false,
    .named = true,
  },
  [aux_sym_source_file_repeat1] = {
    .visible = false,
    .named = false,
  },
  [aux_sym_labeled_types_repeat1] = {
    .visible = false,
    .named = false,
  },
  [aux_sym_unlabeled_types_repeat1] = {
    .visible = false,
    .named = false,
  },
  [aux_sym_type_arguments_repeat1] = {
    .visible = false,
    .named = false,
  },
};

enum ts_field_identifiers {
  field_arguments = 1,
  field_body = 2,
  field_definition = 3,
  field_identifier = 4,
  field_input_type = 5,
  field_name = 6,
  field_output_type = 7,
  field_params = 8,
  field_set = 9,
  field_signature = 10,
  field_type = 11,
  field_type_arguments = 12,
};

static const char * const ts_field_names[] = {
  [0] = NULL,
  [field_arguments] = "arguments",
  [field_body] = "body",
  [field_definition] = "definition",
  [field_identifier] = "identifier",
  [field_input_type] = "input_type",
  [field_name] = "name",
  [field_output_type] = "output_type",
  [field_params] = "params",
  [field_set] = "set",
  [field_signature] = "signature",
  [field_type] = "type",
  [field_type_arguments] = "type_arguments",
};

static const TSFieldMapSlice ts_field_map_slices[PRODUCTION_ID_COUNT] = {
  [1] = {.index = 0, .length = 3},
  [2] = {.index = 3, .length = 6},
  [3] = {.index = 9, .length = 2},
  [4] = {.index = 11, .length = 1},
  [5] = {.index = 12, .length = 1},
  [6] = {.index = 13, .length = 3},
  [7] = {.index = 16, .length = 2},
  [8] = {.index = 18, .length = 1},
  [9] = {.index = 19, .length = 2},
  [10] = {.index = 21, .length = 2},
  [11] = {.index = 23, .length = 2},
  [12] = {.index = 25, .length = 3},
};

static const TSFieldMapEntry ts_field_map_entries[] = {
  [0] =
    {field_definition, 0, .inherited = true},
    {field_identifier, 0, .inherited = true},
    {field_type_arguments, 0, .inherited = true},
  [3] =
    {field_definition, 0, .inherited = true},
    {field_definition, 1, .inherited = true},
    {field_identifier, 0, .inherited = true},
    {field_identifier, 1, .inherited = true},
    {field_type_arguments, 0, .inherited = true},
    {field_type_arguments, 1, .inherited = true},
  [9] =
    {field_definition, 2},
    {field_identifier, 0},
  [11] =
    {field_signature, 0},
  [12] =
    {field_params, 1},
  [13] =
    {field_definition, 3},
    {field_identifier, 0},
    {field_type_arguments, 2},
  [16] =
    {field_body, 1},
    {field_signature, 0},
  [18] =
    {field_identifier, 0},
  [19] =
    {field_name, 0},
    {field_type, 2},
  [21] =
    {field_arguments, 1},
    {field_output_type, 3},
  [23] =
    {field_name, 0},
    {field_set, 3},
  [25] =
    {field_arguments, 4},
    {field_input_type, 2},
    {field_output_type, 6},
};

static const TSSymbol ts_alias_sequences[PRODUCTION_ID_COUNT][MAX_ALIAS_SEQUENCE_LENGTH] = {
  [0] = {0},
};

static const uint16_t ts_non_terminal_alias_map[] = {
  0,
};

static const TSStateId ts_primary_state_ids[STATE_COUNT] = {
  [0] = 0,
  [1] = 1,
  [2] = 2,
  [3] = 3,
  [4] = 4,
  [5] = 5,
  [6] = 6,
  [7] = 7,
  [8] = 8,
  [9] = 9,
  [10] = 10,
  [11] = 11,
  [12] = 12,
  [13] = 13,
  [14] = 14,
  [15] = 15,
  [16] = 16,
  [17] = 17,
  [18] = 18,
  [19] = 19,
  [20] = 20,
  [21] = 21,
  [22] = 22,
  [23] = 23,
  [24] = 24,
  [25] = 25,
  [26] = 26,
  [27] = 27,
  [28] = 28,
  [29] = 29,
  [30] = 30,
  [31] = 31,
  [32] = 32,
  [33] = 33,
  [34] = 34,
  [35] = 35,
  [36] = 36,
  [37] = 37,
  [38] = 38,
  [39] = 39,
  [40] = 40,
  [41] = 41,
  [42] = 42,
  [43] = 43,
  [44] = 44,
  [45] = 45,
  [46] = 46,
  [47] = 47,
  [48] = 48,
  [49] = 49,
  [50] = 50,
  [51] = 51,
  [52] = 52,
  [53] = 53,
  [54] = 54,
  [55] = 55,
  [56] = 56,
  [57] = 57,
  [58] = 58,
  [59] = 59,
  [60] = 60,
  [61] = 61,
  [62] = 62,
  [63] = 63,
  [64] = 64,
  [65] = 65,
  [66] = 66,
  [67] = 67,
  [68] = 68,
  [69] = 69,
  [70] = 70,
  [71] = 71,
  [72] = 72,
  [73] = 73,
  [74] = 74,
  [75] = 75,
};

static bool ts_lex(TSLexer *lexer, TSStateId state) {
  START_LEXER();
  eof = lexer->eof(lexer);
  switch (state) {
    case 0:
      if (eof) ADVANCE(41);
      ADVANCE_MAP(
        '\'', 12,
        '(', 68,
        ')', 69,
        ',', 60,
        '-', 11,
        '/', 7,
        ':', 58,
        '<', 63,
        '>', 64,
        '[', 59,
      );
      if (lookahead == '\\') SKIP(37);
      if (lookahead == ']') ADVANCE(61);
      if (lookahead == 'h') ADVANCE(50);
      if (lookahead == 'n') ADVANCE(46);
      if (lookahead == '{') ADVANCE(71);
      if (lookahead == '}') ADVANCE(72);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(0);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(56);
      END_STATE();
    case 1:
      if (lookahead == '\n') SKIP(6);
      END_STATE();
    case 2:
      if (lookahead == '\n') SKIP(6);
      if (lookahead == '\r') SKIP(1);
      END_STATE();
    case 3:
      if (lookahead == '\n') SKIP(10);
      END_STATE();
    case 4:
      if (lookahead == '\n') SKIP(10);
      if (lookahead == '\r') SKIP(3);
      END_STATE();
    case 5:
      if (lookahead == '\r') ADVANCE(45);
      if (lookahead == '\\') ADVANCE(43);
      if (lookahead != 0) ADVANCE(44);
      END_STATE();
    case 6:
      if (lookahead == '\'') ADVANCE(13);
      if (lookahead == '/') ADVANCE(7);
      if (lookahead == '[') ADVANCE(59);
      if (lookahead == '\\') SKIP(2);
      if (lookahead == 'n') ADVANCE(46);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(6);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(56);
      END_STATE();
    case 7:
      if (lookahead == '*') ADVANCE(9);
      if (lookahead == '/') ADVANCE(44);
      END_STATE();
    case 8:
      if (lookahead == '*') ADVANCE(8);
      if (lookahead == '/') ADVANCE(42);
      if (lookahead != 0) ADVANCE(9);
      END_STATE();
    case 9:
      if (lookahead == '*') ADVANCE(8);
      if (lookahead != 0) ADVANCE(9);
      END_STATE();
    case 10:
      if (lookahead == '/') ADVANCE(7);
      if (lookahead == '\\') SKIP(4);
      if (lookahead == 'h') ADVANCE(23);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(10);
      END_STATE();
    case 11:
      if (lookahead == '>') ADVANCE(70);
      END_STATE();
    case 12:
      if (lookahead == 'a') ADVANCE(26);
      if (lookahead == 'c') ADVANCE(22);
      if (lookahead == 'f') ADVANCE(34);
      if (lookahead == 'i') ADVANCE(27);
      if (lookahead == 'r') ADVANCE(18);
      if (lookahead == 's') ADVANCE(19);
      END_STATE();
    case 13:
      if (lookahead == 'a') ADVANCE(26);
      if (lookahead == 'c') ADVANCE(22);
      if (lookahead == 'f') ADVANCE(34);
      if (lookahead == 'i') ADVANCE(27);
      if (lookahead == 'r') ADVANCE(18);
      if (lookahead == 's') ADVANCE(29);
      END_STATE();
    case 14:
      if (lookahead == 'c') ADVANCE(67);
      END_STATE();
    case 15:
      if (lookahead == 'c') ADVANCE(31);
      END_STATE();
    case 16:
      if (lookahead == 'c') ADVANCE(21);
      END_STATE();
    case 17:
      if (lookahead == 'd') ADVANCE(65);
      END_STATE();
    case 18:
      if (lookahead == 'e') ADVANCE(15);
      END_STATE();
    case 19:
      if (lookahead == 'e') ADVANCE(33);
      if (lookahead == 'o') ADVANCE(25);
      END_STATE();
    case 20:
      if (lookahead == 'e') ADVANCE(75);
      END_STATE();
    case 21:
      if (lookahead == 'e') ADVANCE(66);
      END_STATE();
    case 22:
      if (lookahead == 'h') ADVANCE(30);
      END_STATE();
    case 23:
      if (lookahead == 'i') ADVANCE(78);
      END_STATE();
    case 24:
      if (lookahead == 'i') ADVANCE(16);
      END_STATE();
    case 25:
      if (lookahead == 'm') ADVANCE(20);
      END_STATE();
    case 26:
      if (lookahead == 'n') ADVANCE(35);
      END_STATE();
    case 27:
      if (lookahead == 'n') ADVANCE(62);
      END_STATE();
    case 28:
      if (lookahead == 'n') ADVANCE(14);
      END_STATE();
    case 29:
      if (lookahead == 'o') ADVANCE(25);
      END_STATE();
    case 30:
      if (lookahead == 'o') ADVANCE(24);
      END_STATE();
    case 31:
      if (lookahead == 'o') ADVANCE(32);
      END_STATE();
    case 32:
      if (lookahead == 'r') ADVANCE(17);
      END_STATE();
    case 33:
      if (lookahead == 't') ADVANCE(73);
      END_STATE();
    case 34:
      if (lookahead == 'u') ADVANCE(28);
      END_STATE();
    case 35:
      if (lookahead == 'y') ADVANCE(74);
      END_STATE();
    case 36:
      if (eof) ADVANCE(41);
      if (lookahead == '\n') SKIP(0);
      END_STATE();
    case 37:
      if (eof) ADVANCE(41);
      if (lookahead == '\n') SKIP(0);
      if (lookahead == '\r') SKIP(36);
      END_STATE();
    case 38:
      if (eof) ADVANCE(41);
      if (lookahead == '\n') SKIP(40);
      END_STATE();
    case 39:
      if (eof) ADVANCE(41);
      if (lookahead == '\n') SKIP(40);
      if (lookahead == '\r') SKIP(38);
      END_STATE();
    case 40:
      if (eof) ADVANCE(41);
      if (lookahead == ')') ADVANCE(69);
      if (lookahead == ',') ADVANCE(60);
      if (lookahead == '-') ADVANCE(11);
      if (lookahead == '/') ADVANCE(7);
      if (lookahead == '>') ADVANCE(64);
      if (lookahead == '[') ADVANCE(59);
      if (lookahead == '\\') SKIP(39);
      if (lookahead == ']') ADVANCE(61);
      if (lookahead == '{') ADVANCE(71);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(40);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(56);
      END_STATE();
    case 41:
      ACCEPT_TOKEN(ts_builtin_sym_end);
      END_STATE();
    case 42:
      ACCEPT_TOKEN(sym_comment);
      END_STATE();
    case 43:
      ACCEPT_TOKEN(sym_comment);
      if (lookahead == '\r') ADVANCE(45);
      if (lookahead == '\\') ADVANCE(43);
      if (lookahead != 0) ADVANCE(44);
      END_STATE();
    case 44:
      ACCEPT_TOKEN(sym_comment);
      if (lookahead == '\\') ADVANCE(5);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(44);
      END_STATE();
    case 45:
      ACCEPT_TOKEN(sym_comment);
      if (lookahead == '\\') ADVANCE(5);
      if (lookahead != 0) ADVANCE(44);
      END_STATE();
    case 46:
      ACCEPT_TOKEN(sym_identifier);
      if (lookahead == 'e') ADVANCE(55);
      if (lookahead == 'o') ADVANCE(54);
      if (lookahead == '-' ||
          ('0' <= lookahead && lookahead <= '9')) ADVANCE(57);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(56);
      END_STATE();
    case 47:
      ACCEPT_TOKEN(sym_identifier);
      if (lookahead == 'e') ADVANCE(53);
      if (lookahead == '-' ||
          ('0' <= lookahead && lookahead <= '9')) ADVANCE(57);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(56);
      END_STATE();
    case 48:
      ACCEPT_TOKEN(sym_identifier);
      if (lookahead == 'g') ADVANCE(76);
      if (lookahead == '-' ||
          ('0' <= lookahead && lookahead <= '9')) ADVANCE(57);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(56);
      END_STATE();
    case 49:
      ACCEPT_TOKEN(sym_identifier);
      if (lookahead == 'h') ADVANCE(51);
      if (lookahead == '-' ||
          ('0' <= lookahead && lookahead <= '9')) ADVANCE(57);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(56);
      END_STATE();
    case 50:
      ACCEPT_TOKEN(sym_identifier);
      if (lookahead == 'i') ADVANCE(79);
      if (lookahead == '-' ||
          ('0' <= lookahead && lookahead <= '9')) ADVANCE(57);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(56);
      END_STATE();
    case 51:
      ACCEPT_TOKEN(sym_identifier);
      if (lookahead == 'i') ADVANCE(52);
      if (lookahead == '-' ||
          ('0' <= lookahead && lookahead <= '9')) ADVANCE(57);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(56);
      END_STATE();
    case 52:
      ACCEPT_TOKEN(sym_identifier);
      if (lookahead == 'n') ADVANCE(48);
      if (lookahead == '-' ||
          ('0' <= lookahead && lookahead <= '9')) ADVANCE(57);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(56);
      END_STATE();
    case 53:
      ACCEPT_TOKEN(sym_identifier);
      if (lookahead == 'r') ADVANCE(77);
      if (lookahead == '-' ||
          ('0' <= lookahead && lookahead <= '9')) ADVANCE(57);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(56);
      END_STATE();
    case 54:
      ACCEPT_TOKEN(sym_identifier);
      if (lookahead == 't') ADVANCE(49);
      if (lookahead == '-' ||
          ('0' <= lookahead && lookahead <= '9')) ADVANCE(57);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(56);
      END_STATE();
    case 55:
      ACCEPT_TOKEN(sym_identifier);
      if (lookahead == 'v') ADVANCE(47);
      if (lookahead == '-' ||
          ('0' <= lookahead && lookahead <= '9')) ADVANCE(57);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(56);
      END_STATE();
    case 56:
      ACCEPT_TOKEN(sym_identifier);
      if (lookahead == '-' ||
          ('0' <= lookahead && lookahead <= '9')) ADVANCE(57);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(56);
      END_STATE();
    case 57:
      ACCEPT_TOKEN(sym_identifier);
      if (lookahead == '-' ||
          ('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(57);
      END_STATE();
    case 58:
      ACCEPT_TOKEN(anon_sym_COLON);
      END_STATE();
    case 59:
      ACCEPT_TOKEN(anon_sym_LBRACK);
      END_STATE();
    case 60:
      ACCEPT_TOKEN(anon_sym_COMMA);
      END_STATE();
    case 61:
      ACCEPT_TOKEN(anon_sym_RBRACK);
      END_STATE();
    case 62:
      ACCEPT_TOKEN(anon_sym_SQUOTEin);
      END_STATE();
    case 63:
      ACCEPT_TOKEN(anon_sym_LT);
      END_STATE();
    case 64:
      ACCEPT_TOKEN(anon_sym_GT);
      END_STATE();
    case 65:
      ACCEPT_TOKEN(anon_sym_SQUOTErecord);
      END_STATE();
    case 66:
      ACCEPT_TOKEN(anon_sym_SQUOTEchoice);
      END_STATE();
    case 67:
      ACCEPT_TOKEN(anon_sym_SQUOTEfunc);
      END_STATE();
    case 68:
      ACCEPT_TOKEN(anon_sym_LPAREN);
      END_STATE();
    case 69:
      ACCEPT_TOKEN(anon_sym_RPAREN);
      END_STATE();
    case 70:
      ACCEPT_TOKEN(anon_sym_DASH_GT);
      END_STATE();
    case 71:
      ACCEPT_TOKEN(anon_sym_LBRACE);
      END_STATE();
    case 72:
      ACCEPT_TOKEN(anon_sym_RBRACE);
      END_STATE();
    case 73:
      ACCEPT_TOKEN(sym_set_definition);
      END_STATE();
    case 74:
      ACCEPT_TOKEN(anon_sym_SQUOTEany);
      END_STATE();
    case 75:
      ACCEPT_TOKEN(anon_sym_SQUOTEsome);
      END_STATE();
    case 76:
      ACCEPT_TOKEN(sym_nothing);
      if (lookahead == '-' ||
          ('0' <= lookahead && lookahead <= '9')) ADVANCE(57);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(56);
      END_STATE();
    case 77:
      ACCEPT_TOKEN(sym_never);
      if (lookahead == '-' ||
          ('0' <= lookahead && lookahead <= '9')) ADVANCE(57);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(56);
      END_STATE();
    case 78:
      ACCEPT_TOKEN(anon_sym_hi);
      END_STATE();
    case 79:
      ACCEPT_TOKEN(anon_sym_hi);
      if (lookahead == '-' ||
          ('0' <= lookahead && lookahead <= '9')) ADVANCE(57);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(56);
      END_STATE();
    default:
      return false;
  }
}

static const TSLexMode ts_lex_modes[STATE_COUNT] = {
  [0] = {.lex_state = 0},
  [1] = {.lex_state = 40},
  [2] = {.lex_state = 6},
  [3] = {.lex_state = 6},
  [4] = {.lex_state = 6},
  [5] = {.lex_state = 6},
  [6] = {.lex_state = 6},
  [7] = {.lex_state = 6},
  [8] = {.lex_state = 6},
  [9] = {.lex_state = 6},
  [10] = {.lex_state = 6},
  [11] = {.lex_state = 0},
  [12] = {.lex_state = 0},
  [13] = {.lex_state = 40},
  [14] = {.lex_state = 40},
  [15] = {.lex_state = 40},
  [16] = {.lex_state = 40},
  [17] = {.lex_state = 40},
  [18] = {.lex_state = 40},
  [19] = {.lex_state = 40},
  [20] = {.lex_state = 40},
  [21] = {.lex_state = 40},
  [22] = {.lex_state = 40},
  [23] = {.lex_state = 40},
  [24] = {.lex_state = 40},
  [25] = {.lex_state = 40},
  [26] = {.lex_state = 40},
  [27] = {.lex_state = 40},
  [28] = {.lex_state = 0},
  [29] = {.lex_state = 40},
  [30] = {.lex_state = 0},
  [31] = {.lex_state = 40},
  [32] = {.lex_state = 40},
  [33] = {.lex_state = 40},
  [34] = {.lex_state = 0},
  [35] = {.lex_state = 0},
  [36] = {.lex_state = 0},
  [37] = {.lex_state = 0},
  [38] = {.lex_state = 0},
  [39] = {.lex_state = 40},
  [40] = {.lex_state = 0},
  [41] = {.lex_state = 0},
  [42] = {.lex_state = 0},
  [43] = {.lex_state = 40},
  [44] = {.lex_state = 0},
  [45] = {.lex_state = 0},
  [46] = {.lex_state = 0},
  [47] = {.lex_state = 0},
  [48] = {.lex_state = 0},
  [49] = {.lex_state = 0},
  [50] = {.lex_state = 40},
  [51] = {.lex_state = 40},
  [52] = {.lex_state = 40},
  [53] = {.lex_state = 40},
  [54] = {.lex_state = 0},
  [55] = {.lex_state = 0},
  [56] = {.lex_state = 40},
  [57] = {.lex_state = 0},
  [58] = {.lex_state = 40},
  [59] = {.lex_state = 40},
  [60] = {.lex_state = 40},
  [61] = {.lex_state = 0},
  [62] = {.lex_state = 40},
  [63] = {.lex_state = 10},
  [64] = {.lex_state = 40},
  [65] = {.lex_state = 0},
  [66] = {.lex_state = 0},
  [67] = {.lex_state = 0},
  [68] = {.lex_state = 40},
  [69] = {.lex_state = 0},
  [70] = {.lex_state = 0},
  [71] = {.lex_state = 0},
  [72] = {.lex_state = 40},
  [73] = {.lex_state = 0},
  [74] = {.lex_state = 40},
  [75] = {.lex_state = 0},
};

static const uint16_t ts_parse_table[LARGE_STATE_COUNT][SYMBOL_COUNT] = {
  [0] = {
    [ts_builtin_sym_end] = ACTIONS(1),
    [sym_comment] = ACTIONS(3),
    [sym_identifier] = ACTIONS(1),
    [anon_sym_COLON] = ACTIONS(1),
    [anon_sym_LBRACK] = ACTIONS(1),
    [anon_sym_COMMA] = ACTIONS(1),
    [anon_sym_RBRACK] = ACTIONS(1),
    [anon_sym_SQUOTEin] = ACTIONS(1),
    [anon_sym_LT] = ACTIONS(1),
    [anon_sym_GT] = ACTIONS(1),
    [anon_sym_SQUOTErecord] = ACTIONS(1),
    [anon_sym_SQUOTEchoice] = ACTIONS(1),
    [anon_sym_SQUOTEfunc] = ACTIONS(1),
    [anon_sym_LPAREN] = ACTIONS(1),
    [anon_sym_RPAREN] = ACTIONS(1),
    [anon_sym_DASH_GT] = ACTIONS(1),
    [anon_sym_LBRACE] = ACTIONS(1),
    [anon_sym_RBRACE] = ACTIONS(1),
    [sym_set_definition] = ACTIONS(1),
    [anon_sym_SQUOTEany] = ACTIONS(1),
    [anon_sym_SQUOTEsome] = ACTIONS(1),
    [sym_nothing] = ACTIONS(1),
    [sym_never] = ACTIONS(1),
    [anon_sym_hi] = ACTIONS(1),
  },
  [1] = {
    [sym_source_file] = STATE(66),
    [sym__statement] = STATE(53),
    [aux_sym_source_file_repeat1] = STATE(32),
    [ts_builtin_sym_end] = ACTIONS(5),
    [sym_comment] = ACTIONS(3),
    [sym_identifier] = ACTIONS(7),
  },
};

static const uint16_t ts_small_parse_table[] = {
  [0] = 10,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(9), 1,
      sym_identifier,
    ACTIONS(11), 1,
      anon_sym_SQUOTEin,
    ACTIONS(13), 1,
      anon_sym_SQUOTErecord,
    ACTIONS(15), 1,
      anon_sym_SQUOTEchoice,
    ACTIONS(17), 1,
      anon_sym_SQUOTEfunc,
    ACTIONS(19), 1,
      anon_sym_SQUOTEany,
    ACTIONS(21), 1,
      anon_sym_SQUOTEsome,
    ACTIONS(23), 2,
      sym_nothing,
      sym_never,
    STATE(37), 7,
      sym_product_definition,
      sym_sum_definition,
      sym_function_signature,
      sym_existential_type,
      sym_opaque_type,
      sym__type,
      sym_nominal_type,
  [38] = 10,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(13), 1,
      anon_sym_SQUOTErecord,
    ACTIONS(15), 1,
      anon_sym_SQUOTEchoice,
    ACTIONS(17), 1,
      anon_sym_SQUOTEfunc,
    ACTIONS(19), 1,
      anon_sym_SQUOTEany,
    ACTIONS(21), 1,
      anon_sym_SQUOTEsome,
    ACTIONS(25), 1,
      sym_identifier,
    STATE(36), 1,
      sym_labeled_type,
    ACTIONS(27), 2,
      sym_nothing,
      sym_never,
    STATE(35), 7,
      sym_product_definition,
      sym_sum_definition,
      sym_function_signature,
      sym_existential_type,
      sym_opaque_type,
      sym__type,
      sym_nominal_type,
  [76] = 10,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(9), 1,
      sym_identifier,
    ACTIONS(13), 1,
      anon_sym_SQUOTErecord,
    ACTIONS(15), 1,
      anon_sym_SQUOTEchoice,
    ACTIONS(17), 1,
      anon_sym_SQUOTEfunc,
    ACTIONS(19), 1,
      anon_sym_SQUOTEany,
    ACTIONS(21), 1,
      anon_sym_SQUOTEsome,
    ACTIONS(29), 1,
      anon_sym_LBRACK,
    ACTIONS(31), 2,
      sym_nothing,
      sym_never,
    STATE(61), 7,
      sym_product_definition,
      sym_sum_definition,
      sym_function_signature,
      sym_existential_type,
      sym_opaque_type,
      sym__type,
      sym_nominal_type,
  [114] = 10,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(9), 1,
      sym_identifier,
    ACTIONS(13), 1,
      anon_sym_SQUOTErecord,
    ACTIONS(15), 1,
      anon_sym_SQUOTEchoice,
    ACTIONS(17), 1,
      anon_sym_SQUOTEfunc,
    ACTIONS(19), 1,
      anon_sym_SQUOTEany,
    ACTIONS(21), 1,
      anon_sym_SQUOTEsome,
    ACTIONS(33), 1,
      anon_sym_LBRACK,
    ACTIONS(31), 2,
      sym_nothing,
      sym_never,
    STATE(61), 7,
      sym_product_definition,
      sym_sum_definition,
      sym_function_signature,
      sym_existential_type,
      sym_opaque_type,
      sym__type,
      sym_nominal_type,
  [152] = 9,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(9), 1,
      sym_identifier,
    ACTIONS(13), 1,
      anon_sym_SQUOTErecord,
    ACTIONS(15), 1,
      anon_sym_SQUOTEchoice,
    ACTIONS(17), 1,
      anon_sym_SQUOTEfunc,
    ACTIONS(19), 1,
      anon_sym_SQUOTEany,
    ACTIONS(21), 1,
      anon_sym_SQUOTEsome,
    ACTIONS(35), 2,
      sym_nothing,
      sym_never,
    STATE(65), 7,
      sym_product_definition,
      sym_sum_definition,
      sym_function_signature,
      sym_existential_type,
      sym_opaque_type,
      sym__type,
      sym_nominal_type,
  [187] = 9,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(9), 1,
      sym_identifier,
    ACTIONS(13), 1,
      anon_sym_SQUOTErecord,
    ACTIONS(15), 1,
      anon_sym_SQUOTEchoice,
    ACTIONS(17), 1,
      anon_sym_SQUOTEfunc,
    ACTIONS(19), 1,
      anon_sym_SQUOTEany,
    ACTIONS(21), 1,
      anon_sym_SQUOTEsome,
    ACTIONS(37), 2,
      sym_nothing,
      sym_never,
    STATE(21), 7,
      sym_product_definition,
      sym_sum_definition,
      sym_function_signature,
      sym_existential_type,
      sym_opaque_type,
      sym__type,
      sym_nominal_type,
  [222] = 9,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(9), 1,
      sym_identifier,
    ACTIONS(13), 1,
      anon_sym_SQUOTErecord,
    ACTIONS(15), 1,
      anon_sym_SQUOTEchoice,
    ACTIONS(17), 1,
      anon_sym_SQUOTEfunc,
    ACTIONS(19), 1,
      anon_sym_SQUOTEany,
    ACTIONS(21), 1,
      anon_sym_SQUOTEsome,
    ACTIONS(23), 2,
      sym_nothing,
      sym_never,
    STATE(37), 7,
      sym_product_definition,
      sym_sum_definition,
      sym_function_signature,
      sym_existential_type,
      sym_opaque_type,
      sym__type,
      sym_nominal_type,
  [257] = 9,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(9), 1,
      sym_identifier,
    ACTIONS(13), 1,
      anon_sym_SQUOTErecord,
    ACTIONS(15), 1,
      anon_sym_SQUOTEchoice,
    ACTIONS(17), 1,
      anon_sym_SQUOTEfunc,
    ACTIONS(19), 1,
      anon_sym_SQUOTEany,
    ACTIONS(21), 1,
      anon_sym_SQUOTEsome,
    ACTIONS(31), 2,
      sym_nothing,
      sym_never,
    STATE(61), 7,
      sym_product_definition,
      sym_sum_definition,
      sym_function_signature,
      sym_existential_type,
      sym_opaque_type,
      sym__type,
      sym_nominal_type,
  [292] = 9,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(9), 1,
      sym_identifier,
    ACTIONS(13), 1,
      anon_sym_SQUOTErecord,
    ACTIONS(15), 1,
      anon_sym_SQUOTEchoice,
    ACTIONS(17), 1,
      anon_sym_SQUOTEfunc,
    ACTIONS(19), 1,
      anon_sym_SQUOTEany,
    ACTIONS(21), 1,
      anon_sym_SQUOTEsome,
    ACTIONS(39), 2,
      sym_nothing,
      sym_never,
    STATE(25), 7,
      sym_product_definition,
      sym_sum_definition,
      sym_function_signature,
      sym_existential_type,
      sym_opaque_type,
      sym__type,
      sym_nominal_type,
  [327] = 10,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(13), 1,
      anon_sym_SQUOTErecord,
    ACTIONS(15), 1,
      anon_sym_SQUOTEchoice,
    ACTIONS(17), 1,
      anon_sym_SQUOTEfunc,
    ACTIONS(41), 1,
      anon_sym_SQUOTEin,
    ACTIONS(43), 1,
      anon_sym_LT,
    ACTIONS(45), 1,
      sym_set_definition,
    STATE(12), 1,
      sym_type_arguments,
    STATE(33), 1,
      sym_function_signature,
    STATE(51), 5,
      sym__definition,
      sym_product_definition,
      sym_sum_definition,
      sym_function_definition,
      sym_implementation_definition,
  [362] = 8,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(13), 1,
      anon_sym_SQUOTErecord,
    ACTIONS(15), 1,
      anon_sym_SQUOTEchoice,
    ACTIONS(17), 1,
      anon_sym_SQUOTEfunc,
    ACTIONS(41), 1,
      anon_sym_SQUOTEin,
    ACTIONS(47), 1,
      sym_set_definition,
    STATE(33), 1,
      sym_function_signature,
    STATE(62), 5,
      sym__definition,
      sym_product_definition,
      sym_sum_definition,
      sym_function_definition,
      sym_implementation_definition,
  [391] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(49), 9,
      ts_builtin_sym_end,
      sym_identifier,
      anon_sym_LBRACK,
      anon_sym_COMMA,
      anon_sym_RBRACK,
      anon_sym_GT,
      anon_sym_RPAREN,
      anon_sym_DASH_GT,
      anon_sym_LBRACE,
  [406] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(51), 9,
      ts_builtin_sym_end,
      sym_identifier,
      anon_sym_LBRACK,
      anon_sym_COMMA,
      anon_sym_RBRACK,
      anon_sym_GT,
      anon_sym_RPAREN,
      anon_sym_DASH_GT,
      anon_sym_LBRACE,
  [421] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(53), 9,
      ts_builtin_sym_end,
      sym_identifier,
      anon_sym_LBRACK,
      anon_sym_COMMA,
      anon_sym_RBRACK,
      anon_sym_GT,
      anon_sym_RPAREN,
      anon_sym_DASH_GT,
      anon_sym_LBRACE,
  [436] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(55), 8,
      ts_builtin_sym_end,
      sym_identifier,
      anon_sym_LBRACK,
      anon_sym_COMMA,
      anon_sym_RBRACK,
      anon_sym_GT,
      anon_sym_RPAREN,
      anon_sym_LBRACE,
  [450] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(57), 8,
      ts_builtin_sym_end,
      sym_identifier,
      anon_sym_LBRACK,
      anon_sym_COMMA,
      anon_sym_RBRACK,
      anon_sym_GT,
      anon_sym_RPAREN,
      anon_sym_LBRACE,
  [464] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(59), 8,
      ts_builtin_sym_end,
      sym_identifier,
      anon_sym_LBRACK,
      anon_sym_COMMA,
      anon_sym_RBRACK,
      anon_sym_GT,
      anon_sym_RPAREN,
      anon_sym_LBRACE,
  [478] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(61), 8,
      ts_builtin_sym_end,
      sym_identifier,
      anon_sym_LBRACK,
      anon_sym_COMMA,
      anon_sym_RBRACK,
      anon_sym_GT,
      anon_sym_RPAREN,
      anon_sym_LBRACE,
  [492] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(63), 8,
      ts_builtin_sym_end,
      sym_identifier,
      anon_sym_LBRACK,
      anon_sym_COMMA,
      anon_sym_RBRACK,
      anon_sym_GT,
      anon_sym_RPAREN,
      anon_sym_LBRACE,
  [506] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(65), 8,
      ts_builtin_sym_end,
      sym_identifier,
      anon_sym_LBRACK,
      anon_sym_COMMA,
      anon_sym_RBRACK,
      anon_sym_GT,
      anon_sym_RPAREN,
      anon_sym_LBRACE,
  [520] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(67), 8,
      ts_builtin_sym_end,
      sym_identifier,
      anon_sym_LBRACK,
      anon_sym_COMMA,
      anon_sym_RBRACK,
      anon_sym_GT,
      anon_sym_RPAREN,
      anon_sym_LBRACE,
  [534] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(69), 8,
      ts_builtin_sym_end,
      sym_identifier,
      anon_sym_LBRACK,
      anon_sym_COMMA,
      anon_sym_RBRACK,
      anon_sym_GT,
      anon_sym_RPAREN,
      anon_sym_LBRACE,
  [548] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(71), 8,
      ts_builtin_sym_end,
      sym_identifier,
      anon_sym_LBRACK,
      anon_sym_COMMA,
      anon_sym_RBRACK,
      anon_sym_GT,
      anon_sym_RPAREN,
      anon_sym_LBRACE,
  [562] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(73), 8,
      ts_builtin_sym_end,
      sym_identifier,
      anon_sym_LBRACK,
      anon_sym_COMMA,
      anon_sym_RBRACK,
      anon_sym_GT,
      anon_sym_RPAREN,
      anon_sym_LBRACE,
  [576] = 4,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(75), 1,
      sym_identifier,
    STATE(29), 1,
      aux_sym_type_arguments_repeat1,
    STATE(48), 3,
      sym_labeled_type,
      sym_constrained_type,
      sym__type_argument,
  [591] = 4,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(75), 1,
      sym_identifier,
    STATE(26), 1,
      aux_sym_type_arguments_repeat1,
    STATE(49), 3,
      sym_labeled_type,
      sym_constrained_type,
      sym__type_argument,
  [606] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(77), 5,
      anon_sym_SQUOTEin,
      anon_sym_SQUOTErecord,
      anon_sym_SQUOTEchoice,
      anon_sym_SQUOTEfunc,
      sym_set_definition,
  [617] = 4,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(79), 1,
      sym_identifier,
    STATE(29), 1,
      aux_sym_type_arguments_repeat1,
    STATE(73), 3,
      sym_labeled_type,
      sym_constrained_type,
      sym__type_argument,
  [632] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(82), 5,
      anon_sym_SQUOTEin,
      anon_sym_SQUOTErecord,
      anon_sym_SQUOTEchoice,
      anon_sym_SQUOTEfunc,
      sym_set_definition,
  [643] = 5,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(84), 1,
      ts_builtin_sym_end,
    ACTIONS(86), 1,
      sym_identifier,
    STATE(31), 1,
      aux_sym_source_file_repeat1,
    STATE(53), 1,
      sym__statement,
  [659] = 5,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(7), 1,
      sym_identifier,
    ACTIONS(89), 1,
      ts_builtin_sym_end,
    STATE(31), 1,
      aux_sym_source_file_repeat1,
    STATE(53), 1,
      sym__statement,
  [675] = 4,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(93), 1,
      anon_sym_LBRACE,
    STATE(58), 1,
      sym_function_body,
    ACTIONS(91), 2,
      ts_builtin_sym_end,
      sym_identifier,
  [689] = 3,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(95), 1,
      anon_sym_COLON,
    ACTIONS(59), 2,
      anon_sym_LBRACK,
      anon_sym_COMMA,
  [700] = 4,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(97), 1,
      anon_sym_LBRACK,
    ACTIONS(99), 1,
      anon_sym_COMMA,
    STATE(41), 1,
      aux_sym_unlabeled_types_repeat1,
  [713] = 4,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(101), 1,
      anon_sym_COMMA,
    ACTIONS(103), 1,
      anon_sym_RBRACK,
    STATE(40), 1,
      aux_sym_labeled_types_repeat1,
  [726] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(105), 3,
      anon_sym_COMMA,
      anon_sym_RBRACK,
      anon_sym_GT,
  [735] = 3,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(107), 1,
      anon_sym_COLON,
    ACTIONS(109), 2,
      anon_sym_COMMA,
      anon_sym_GT,
  [746] = 4,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(111), 1,
      sym_identifier,
    ACTIONS(113), 1,
      anon_sym_RBRACK,
    STATE(57), 1,
      sym_labeled_type,
  [759] = 4,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(113), 1,
      anon_sym_RBRACK,
    ACTIONS(115), 1,
      anon_sym_COMMA,
    STATE(44), 1,
      aux_sym_labeled_types_repeat1,
  [772] = 4,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(33), 1,
      anon_sym_LBRACK,
    ACTIONS(117), 1,
      anon_sym_COMMA,
    STATE(45), 1,
      aux_sym_unlabeled_types_repeat1,
  [785] = 3,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(119), 1,
      anon_sym_LBRACK,
    STATE(17), 2,
      sym_labeled_types,
      sym_unlabeled_types,
  [796] = 4,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(111), 1,
      sym_identifier,
    ACTIONS(121), 1,
      anon_sym_RBRACK,
    STATE(57), 1,
      sym_labeled_type,
  [809] = 4,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(123), 1,
      anon_sym_COMMA,
    ACTIONS(126), 1,
      anon_sym_RBRACK,
    STATE(44), 1,
      aux_sym_labeled_types_repeat1,
  [822] = 4,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(128), 1,
      anon_sym_LBRACK,
    ACTIONS(130), 1,
      anon_sym_COMMA,
    STATE(45), 1,
      aux_sym_unlabeled_types_repeat1,
  [835] = 3,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(119), 1,
      anon_sym_LBRACK,
    STATE(16), 2,
      sym_labeled_types,
      sym_unlabeled_types,
  [846] = 4,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(133), 1,
      anon_sym_LBRACK,
    ACTIONS(135), 1,
      anon_sym_LPAREN,
    STATE(70), 1,
      sym_labeled_types,
  [859] = 3,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(137), 1,
      anon_sym_COMMA,
    ACTIONS(139), 1,
      anon_sym_GT,
  [869] = 3,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(137), 1,
      anon_sym_COMMA,
    ACTIONS(141), 1,
      anon_sym_GT,
  [879] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(143), 2,
      ts_builtin_sym_end,
      sym_identifier,
  [887] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(145), 2,
      ts_builtin_sym_end,
      sym_identifier,
  [895] = 3,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(147), 1,
      sym_identifier,
    STATE(19), 1,
      sym_nominal_type,
  [905] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(149), 2,
      ts_builtin_sym_end,
      sym_identifier,
  [913] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(151), 2,
      anon_sym_COMMA,
      anon_sym_GT,
  [921] = 3,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(133), 1,
      anon_sym_LBRACK,
    STATE(71), 1,
      sym_labeled_types,
  [931] = 3,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(111), 1,
      sym_identifier,
    STATE(36), 1,
      sym_labeled_type,
  [941] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(126), 2,
      anon_sym_COMMA,
      anon_sym_RBRACK,
  [949] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(153), 2,
      ts_builtin_sym_end,
      sym_identifier,
  [957] = 3,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(147), 1,
      sym_identifier,
    STATE(22), 1,
      sym_nominal_type,
  [967] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(155), 2,
      ts_builtin_sym_end,
      sym_identifier,
  [975] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(128), 2,
      anon_sym_LBRACK,
      anon_sym_COMMA,
  [983] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(157), 2,
      ts_builtin_sym_end,
      sym_identifier,
  [991] = 3,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(159), 1,
      anon_sym_hi,
    STATE(69), 1,
      sym__expression,
  [1001] = 3,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(111), 1,
      sym_identifier,
    STATE(57), 1,
      sym_labeled_type,
  [1011] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(161), 1,
      anon_sym_RPAREN,
  [1018] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(163), 1,
      ts_builtin_sym_end,
  [1025] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(165), 1,
      anon_sym_COLON,
  [1032] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(167), 1,
      sym_identifier,
  [1039] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(169), 1,
      anon_sym_RBRACE,
  [1046] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(171), 1,
      anon_sym_DASH_GT,
  [1053] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(173), 1,
      anon_sym_DASH_GT,
  [1060] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(175), 1,
      sym_identifier,
  [1067] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(137), 1,
      anon_sym_COMMA,
  [1074] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(177), 1,
      sym_identifier,
  [1081] = 2,
    ACTIONS(3), 1,
      sym_comment,
    ACTIONS(95), 1,
      anon_sym_COLON,
};

static const uint32_t ts_small_parse_table_map[] = {
  [SMALL_STATE(2)] = 0,
  [SMALL_STATE(3)] = 38,
  [SMALL_STATE(4)] = 76,
  [SMALL_STATE(5)] = 114,
  [SMALL_STATE(6)] = 152,
  [SMALL_STATE(7)] = 187,
  [SMALL_STATE(8)] = 222,
  [SMALL_STATE(9)] = 257,
  [SMALL_STATE(10)] = 292,
  [SMALL_STATE(11)] = 327,
  [SMALL_STATE(12)] = 362,
  [SMALL_STATE(13)] = 391,
  [SMALL_STATE(14)] = 406,
  [SMALL_STATE(15)] = 421,
  [SMALL_STATE(16)] = 436,
  [SMALL_STATE(17)] = 450,
  [SMALL_STATE(18)] = 464,
  [SMALL_STATE(19)] = 478,
  [SMALL_STATE(20)] = 492,
  [SMALL_STATE(21)] = 506,
  [SMALL_STATE(22)] = 520,
  [SMALL_STATE(23)] = 534,
  [SMALL_STATE(24)] = 548,
  [SMALL_STATE(25)] = 562,
  [SMALL_STATE(26)] = 576,
  [SMALL_STATE(27)] = 591,
  [SMALL_STATE(28)] = 606,
  [SMALL_STATE(29)] = 617,
  [SMALL_STATE(30)] = 632,
  [SMALL_STATE(31)] = 643,
  [SMALL_STATE(32)] = 659,
  [SMALL_STATE(33)] = 675,
  [SMALL_STATE(34)] = 689,
  [SMALL_STATE(35)] = 700,
  [SMALL_STATE(36)] = 713,
  [SMALL_STATE(37)] = 726,
  [SMALL_STATE(38)] = 735,
  [SMALL_STATE(39)] = 746,
  [SMALL_STATE(40)] = 759,
  [SMALL_STATE(41)] = 772,
  [SMALL_STATE(42)] = 785,
  [SMALL_STATE(43)] = 796,
  [SMALL_STATE(44)] = 809,
  [SMALL_STATE(45)] = 822,
  [SMALL_STATE(46)] = 835,
  [SMALL_STATE(47)] = 846,
  [SMALL_STATE(48)] = 859,
  [SMALL_STATE(49)] = 869,
  [SMALL_STATE(50)] = 879,
  [SMALL_STATE(51)] = 887,
  [SMALL_STATE(52)] = 895,
  [SMALL_STATE(53)] = 905,
  [SMALL_STATE(54)] = 913,
  [SMALL_STATE(55)] = 921,
  [SMALL_STATE(56)] = 931,
  [SMALL_STATE(57)] = 941,
  [SMALL_STATE(58)] = 949,
  [SMALL_STATE(59)] = 957,
  [SMALL_STATE(60)] = 967,
  [SMALL_STATE(61)] = 975,
  [SMALL_STATE(62)] = 983,
  [SMALL_STATE(63)] = 991,
  [SMALL_STATE(64)] = 1001,
  [SMALL_STATE(65)] = 1011,
  [SMALL_STATE(66)] = 1018,
  [SMALL_STATE(67)] = 1025,
  [SMALL_STATE(68)] = 1032,
  [SMALL_STATE(69)] = 1039,
  [SMALL_STATE(70)] = 1046,
  [SMALL_STATE(71)] = 1053,
  [SMALL_STATE(72)] = 1060,
  [SMALL_STATE(73)] = 1067,
  [SMALL_STATE(74)] = 1074,
  [SMALL_STATE(75)] = 1081,
};

static const TSParseActionEntry ts_parse_actions[] = {
  [0] = {.entry = {.count = 0, .reusable = false}},
  [1] = {.entry = {.count = 1, .reusable = false}}, RECOVER(),
  [3] = {.entry = {.count = 1, .reusable = true}}, SHIFT_EXTRA(),
  [5] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_source_file, 0, 0, 0),
  [7] = {.entry = {.count = 1, .reusable = true}}, SHIFT(67),
  [9] = {.entry = {.count = 1, .reusable = false}}, SHIFT(18),
  [11] = {.entry = {.count = 1, .reusable = true}}, SHIFT(72),
  [13] = {.entry = {.count = 1, .reusable = true}}, SHIFT(42),
  [15] = {.entry = {.count = 1, .reusable = true}}, SHIFT(46),
  [17] = {.entry = {.count = 1, .reusable = true}}, SHIFT(47),
  [19] = {.entry = {.count = 1, .reusable = true}}, SHIFT(52),
  [21] = {.entry = {.count = 1, .reusable = true}}, SHIFT(59),
  [23] = {.entry = {.count = 1, .reusable = false}}, SHIFT(37),
  [25] = {.entry = {.count = 1, .reusable = false}}, SHIFT(34),
  [27] = {.entry = {.count = 1, .reusable = false}}, SHIFT(35),
  [29] = {.entry = {.count = 1, .reusable = true}}, SHIFT(20),
  [31] = {.entry = {.count = 1, .reusable = false}}, SHIFT(61),
  [33] = {.entry = {.count = 1, .reusable = true}}, SHIFT(23),
  [35] = {.entry = {.count = 1, .reusable = false}}, SHIFT(65),
  [37] = {.entry = {.count = 1, .reusable = false}}, SHIFT(21),
  [39] = {.entry = {.count = 1, .reusable = false}}, SHIFT(25),
  [41] = {.entry = {.count = 1, .reusable = true}}, SHIFT(68),
  [43] = {.entry = {.count = 1, .reusable = true}}, SHIFT(27),
  [45] = {.entry = {.count = 1, .reusable = true}}, SHIFT(51),
  [47] = {.entry = {.count = 1, .reusable = true}}, SHIFT(62),
  [49] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_labeled_types, 3, 0, 0),
  [51] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_labeled_types, 5, 0, 0),
  [53] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_labeled_types, 4, 0, 0),
  [55] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_sum_definition, 2, 0, 5),
  [57] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_product_definition, 2, 0, 5),
  [59] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_nominal_type, 1, 0, 8),
  [61] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_existential_type, 2, 0, 0),
  [63] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_unlabeled_types, 5, 0, 0),
  [65] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_function_signature, 4, 0, 10),
  [67] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_opaque_type, 2, 0, 0),
  [69] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_unlabeled_types, 4, 0, 0),
  [71] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_unlabeled_types, 3, 0, 0),
  [73] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_function_signature, 7, 0, 12),
  [75] = {.entry = {.count = 1, .reusable = true}}, SHIFT(38),
  [77] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_type_arguments, 3, 0, 0),
  [79] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_type_arguments_repeat1, 2, 0, 0), SHIFT_REPEAT(38),
  [82] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_type_arguments, 4, 0, 0),
  [84] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 2),
  [86] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 2), SHIFT_REPEAT(67),
  [89] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_source_file, 1, 0, 1),
  [91] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_function_definition, 1, 0, 4),
  [93] = {.entry = {.count = 1, .reusable = true}}, SHIFT(63),
  [95] = {.entry = {.count = 1, .reusable = true}}, SHIFT(8),
  [97] = {.entry = {.count = 1, .reusable = true}}, SHIFT(24),
  [99] = {.entry = {.count = 1, .reusable = true}}, SHIFT(5),
  [101] = {.entry = {.count = 1, .reusable = true}}, SHIFT(39),
  [103] = {.entry = {.count = 1, .reusable = true}}, SHIFT(13),
  [105] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_labeled_type, 3, 0, 9),
  [107] = {.entry = {.count = 1, .reusable = true}}, SHIFT(2),
  [109] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym__type_argument, 1, 0, 0),
  [111] = {.entry = {.count = 1, .reusable = true}}, SHIFT(75),
  [113] = {.entry = {.count = 1, .reusable = true}}, SHIFT(15),
  [115] = {.entry = {.count = 1, .reusable = true}}, SHIFT(43),
  [117] = {.entry = {.count = 1, .reusable = true}}, SHIFT(4),
  [119] = {.entry = {.count = 1, .reusable = true}}, SHIFT(3),
  [121] = {.entry = {.count = 1, .reusable = true}}, SHIFT(14),
  [123] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_labeled_types_repeat1, 2, 0, 0), SHIFT_REPEAT(64),
  [126] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_labeled_types_repeat1, 2, 0, 0),
  [128] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_unlabeled_types_repeat1, 2, 0, 0),
  [130] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_unlabeled_types_repeat1, 2, 0, 0), SHIFT_REPEAT(9),
  [133] = {.entry = {.count = 1, .reusable = true}}, SHIFT(56),
  [135] = {.entry = {.count = 1, .reusable = true}}, SHIFT(6),
  [137] = {.entry = {.count = 1, .reusable = true}}, SHIFT(74),
  [139] = {.entry = {.count = 1, .reusable = true}}, SHIFT(30),
  [141] = {.entry = {.count = 1, .reusable = true}}, SHIFT(28),
  [143] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_function_body, 3, 0, 0),
  [145] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym__statement, 3, 0, 3),
  [147] = {.entry = {.count = 1, .reusable = true}}, SHIFT(18),
  [149] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_source_file_repeat1, 1, 0, 1),
  [151] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_constrained_type, 4, 0, 11),
  [153] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_function_definition, 2, 0, 7),
  [155] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_implementation_definition, 2, 0, 0),
  [157] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym__statement, 4, 0, 6),
  [159] = {.entry = {.count = 1, .reusable = true}}, SHIFT(69),
  [161] = {.entry = {.count = 1, .reusable = true}}, SHIFT(55),
  [163] = {.entry = {.count = 1, .reusable = true}},  ACCEPT_INPUT(),
  [165] = {.entry = {.count = 1, .reusable = true}}, SHIFT(11),
  [167] = {.entry = {.count = 1, .reusable = true}}, SHIFT(60),
  [169] = {.entry = {.count = 1, .reusable = true}}, SHIFT(50),
  [171] = {.entry = {.count = 1, .reusable = true}}, SHIFT(7),
  [173] = {.entry = {.count = 1, .reusable = true}}, SHIFT(10),
  [175] = {.entry = {.count = 1, .reusable = true}}, SHIFT(54),
  [177] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_type_arguments_repeat1, 2, 0, 0),
};

#ifdef __cplusplus
extern "C" {
#endif
#ifdef TREE_SITTER_HIDE_SYMBOLS
#define TS_PUBLIC
#elif defined(_WIN32)
#define TS_PUBLIC __declspec(dllexport)
#else
#define TS_PUBLIC __attribute__((visibility("default")))
#endif

TS_PUBLIC const TSLanguage *tree_sitter_peopl(void) {
  static const TSLanguage language = {
    .version = LANGUAGE_VERSION,
    .symbol_count = SYMBOL_COUNT,
    .alias_count = ALIAS_COUNT,
    .token_count = TOKEN_COUNT,
    .external_token_count = EXTERNAL_TOKEN_COUNT,
    .state_count = STATE_COUNT,
    .large_state_count = LARGE_STATE_COUNT,
    .production_id_count = PRODUCTION_ID_COUNT,
    .field_count = FIELD_COUNT,
    .max_alias_sequence_length = MAX_ALIAS_SEQUENCE_LENGTH,
    .parse_table = &ts_parse_table[0][0],
    .small_parse_table = ts_small_parse_table,
    .small_parse_table_map = ts_small_parse_table_map,
    .parse_actions = ts_parse_actions,
    .symbol_names = ts_symbol_names,
    .field_names = ts_field_names,
    .field_map_slices = ts_field_map_slices,
    .field_map_entries = ts_field_map_entries,
    .symbol_metadata = ts_symbol_metadata,
    .public_symbol_map = ts_symbol_map,
    .alias_map = ts_non_terminal_alias_map,
    .alias_sequences = &ts_alias_sequences[0][0],
    .lex_modes = ts_lex_modes,
    .lex_fn = ts_lex,
    .primary_state_ids = ts_primary_state_ids,
  };
  return &language;
}
#ifdef __cplusplus
}
#endif
