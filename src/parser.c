#include "tree_sitter/parser.h"

#if defined(__GNUC__) || defined(__clang__)
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#endif

#define LANGUAGE_VERSION 14
#define STATE_COUNT 72
#define LARGE_STATE_COUNT 4
#define SYMBOL_COUNT 37
#define ALIAS_COUNT 0
#define TOKEN_COUNT 17
#define EXTERNAL_TOKEN_COUNT 0
#define FIELD_COUNT 9
#define MAX_ALIAS_SEQUENCE_LENGTH 6
#define PRODUCTION_ID_COUNT 12

enum ts_symbol_identifiers {
  anon_sym_STAR = 1,
  aux_sym_comment_token1 = 2,
  anon_sym_DOT_LF = 3,
  anon_sym_type = 4,
  anon_sym_contract = 5,
  anon_sym_func = 6,
  aux_sym_type_identifier_token1 = 7,
  sym_field_identifier = 8,
  anon_sym_LPAREN = 9,
  anon_sym_RPAREN = 10,
  anon_sym_PIPE = 11,
  sym_true = 12,
  sym_false = 13,
  sym_int_literal = 14,
  sym_float_literal = 15,
  sym_string_literal = 16,
  sym_source_file = 17,
  sym_comment = 18,
  sym__statement = 19,
  sym__declaration = 20,
  sym_type_declaration = 21,
  sym_contract_declaration = 22,
  sym_function_declaration = 23,
  sym_param_list = 24,
  sym_param_declaration = 25,
  sym_type_identifier = 26,
  sym_inline_function_declaration = 27,
  sym_expression = 28,
  sym_single_expression = 29,
  sym_pipe_expression = 30,
  sym_call_expression = 31,
  sym_param_list_call = 32,
  sym_param_definition = 33,
  aux_sym_source_file_repeat1 = 34,
  aux_sym_param_list_repeat1 = 35,
  aux_sym_param_list_call_repeat1 = 36,
};

static const char * const ts_symbol_names[] = {
  [ts_builtin_sym_end] = "end",
  [anon_sym_STAR] = "* ",
  [aux_sym_comment_token1] = "comment_token1",
  [anon_sym_DOT_LF] = ".\n",
  [anon_sym_type] = "type",
  [anon_sym_contract] = "contract",
  [anon_sym_func] = "func",
  [aux_sym_type_identifier_token1] = "type_identifier_token1",
  [sym_field_identifier] = "field_identifier",
  [anon_sym_LPAREN] = "(",
  [anon_sym_RPAREN] = ")",
  [anon_sym_PIPE] = "|",
  [sym_true] = "true",
  [sym_false] = "false",
  [sym_int_literal] = "int_literal",
  [sym_float_literal] = "float_literal",
  [sym_string_literal] = "string_literal",
  [sym_source_file] = "source_file",
  [sym_comment] = "comment",
  [sym__statement] = "_statement",
  [sym__declaration] = "_declaration",
  [sym_type_declaration] = "type_declaration",
  [sym_contract_declaration] = "contract_declaration",
  [sym_function_declaration] = "function_declaration",
  [sym_param_list] = "param_list",
  [sym_param_declaration] = "param_declaration",
  [sym_type_identifier] = "type_identifier",
  [sym_inline_function_declaration] = "inline_function_declaration",
  [sym_expression] = "expression",
  [sym_single_expression] = "single_expression",
  [sym_pipe_expression] = "pipe_expression",
  [sym_call_expression] = "call_expression",
  [sym_param_list_call] = "param_list_call",
  [sym_param_definition] = "param_definition",
  [aux_sym_source_file_repeat1] = "source_file_repeat1",
  [aux_sym_param_list_repeat1] = "param_list_repeat1",
  [aux_sym_param_list_call_repeat1] = "param_list_call_repeat1",
};

static const TSSymbol ts_symbol_map[] = {
  [ts_builtin_sym_end] = ts_builtin_sym_end,
  [anon_sym_STAR] = anon_sym_STAR,
  [aux_sym_comment_token1] = aux_sym_comment_token1,
  [anon_sym_DOT_LF] = anon_sym_DOT_LF,
  [anon_sym_type] = anon_sym_type,
  [anon_sym_contract] = anon_sym_contract,
  [anon_sym_func] = anon_sym_func,
  [aux_sym_type_identifier_token1] = aux_sym_type_identifier_token1,
  [sym_field_identifier] = sym_field_identifier,
  [anon_sym_LPAREN] = anon_sym_LPAREN,
  [anon_sym_RPAREN] = anon_sym_RPAREN,
  [anon_sym_PIPE] = anon_sym_PIPE,
  [sym_true] = sym_true,
  [sym_false] = sym_false,
  [sym_int_literal] = sym_int_literal,
  [sym_float_literal] = sym_float_literal,
  [sym_string_literal] = sym_string_literal,
  [sym_source_file] = sym_source_file,
  [sym_comment] = sym_comment,
  [sym__statement] = sym__statement,
  [sym__declaration] = sym__declaration,
  [sym_type_declaration] = sym_type_declaration,
  [sym_contract_declaration] = sym_contract_declaration,
  [sym_function_declaration] = sym_function_declaration,
  [sym_param_list] = sym_param_list,
  [sym_param_declaration] = sym_param_declaration,
  [sym_type_identifier] = sym_type_identifier,
  [sym_inline_function_declaration] = sym_inline_function_declaration,
  [sym_expression] = sym_expression,
  [sym_single_expression] = sym_single_expression,
  [sym_pipe_expression] = sym_pipe_expression,
  [sym_call_expression] = sym_call_expression,
  [sym_param_list_call] = sym_param_list_call,
  [sym_param_definition] = sym_param_definition,
  [aux_sym_source_file_repeat1] = aux_sym_source_file_repeat1,
  [aux_sym_param_list_repeat1] = aux_sym_param_list_repeat1,
  [aux_sym_param_list_call_repeat1] = aux_sym_param_list_call_repeat1,
};

static const TSSymbolMetadata ts_symbol_metadata[] = {
  [ts_builtin_sym_end] = {
    .visible = false,
    .named = true,
  },
  [anon_sym_STAR] = {
    .visible = true,
    .named = false,
  },
  [aux_sym_comment_token1] = {
    .visible = false,
    .named = false,
  },
  [anon_sym_DOT_LF] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_type] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_contract] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_func] = {
    .visible = true,
    .named = false,
  },
  [aux_sym_type_identifier_token1] = {
    .visible = false,
    .named = false,
  },
  [sym_field_identifier] = {
    .visible = true,
    .named = true,
  },
  [anon_sym_LPAREN] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_RPAREN] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_PIPE] = {
    .visible = true,
    .named = false,
  },
  [sym_true] = {
    .visible = true,
    .named = true,
  },
  [sym_false] = {
    .visible = true,
    .named = true,
  },
  [sym_int_literal] = {
    .visible = true,
    .named = true,
  },
  [sym_float_literal] = {
    .visible = true,
    .named = true,
  },
  [sym_string_literal] = {
    .visible = true,
    .named = true,
  },
  [sym_source_file] = {
    .visible = true,
    .named = true,
  },
  [sym_comment] = {
    .visible = true,
    .named = true,
  },
  [sym__statement] = {
    .visible = false,
    .named = true,
  },
  [sym__declaration] = {
    .visible = false,
    .named = true,
  },
  [sym_type_declaration] = {
    .visible = true,
    .named = true,
  },
  [sym_contract_declaration] = {
    .visible = true,
    .named = true,
  },
  [sym_function_declaration] = {
    .visible = true,
    .named = true,
  },
  [sym_param_list] = {
    .visible = true,
    .named = true,
  },
  [sym_param_declaration] = {
    .visible = true,
    .named = true,
  },
  [sym_type_identifier] = {
    .visible = true,
    .named = true,
  },
  [sym_inline_function_declaration] = {
    .visible = true,
    .named = true,
  },
  [sym_expression] = {
    .visible = true,
    .named = true,
  },
  [sym_single_expression] = {
    .visible = true,
    .named = true,
  },
  [sym_pipe_expression] = {
    .visible = true,
    .named = true,
  },
  [sym_call_expression] = {
    .visible = true,
    .named = true,
  },
  [sym_param_list_call] = {
    .visible = true,
    .named = true,
  },
  [sym_param_definition] = {
    .visible = true,
    .named = true,
  },
  [aux_sym_source_file_repeat1] = {
    .visible = false,
    .named = false,
  },
  [aux_sym_param_list_repeat1] = {
    .visible = false,
    .named = false,
  },
  [aux_sym_param_list_call_repeat1] = {
    .visible = false,
    .named = false,
  },
};

enum ts_field_identifiers {
  field_body = 1,
  field_field = 2,
  field_function = 3,
  field_name = 4,
  field_on_type = 5,
  field_params = 6,
  field_return = 7,
  field_type = 8,
  field_value = 9,
};

static const char * const ts_field_names[] = {
  [0] = NULL,
  [field_body] = "body",
  [field_field] = "field",
  [field_function] = "function",
  [field_name] = "name",
  [field_on_type] = "on_type",
  [field_params] = "params",
  [field_return] = "return",
  [field_type] = "type",
  [field_value] = "value",
};

static const TSFieldMapSlice ts_field_map_slices[PRODUCTION_ID_COUNT] = {
  [1] = {.index = 0, .length = 1},
  [2] = {.index = 1, .length = 1},
  [3] = {.index = 2, .length = 2},
  [4] = {.index = 4, .length = 2},
  [5] = {.index = 6, .length = 2},
  [6] = {.index = 8, .length = 1},
  [7] = {.index = 9, .length = 2},
  [8] = {.index = 11, .length = 3},
  [9] = {.index = 14, .length = 4},
  [10] = {.index = 18, .length = 4},
  [11] = {.index = 22, .length = 5},
};

static const TSFieldMapEntry ts_field_map_entries[] = {
  [0] =
    {field_function, 0},
  [1] =
    {field_name, 1},
  [2] =
    {field_function, 0},
    {field_params, 1},
  [4] =
    {field_name, 1},
    {field_params, 2},
  [6] =
    {field_name, 0},
    {field_value, 1},
  [8] =
    {field_field, 0},
  [9] =
    {field_name, 0},
    {field_type, 1},
  [11] =
    {field_body, 3},
    {field_name, 1},
    {field_return, 2},
  [14] =
    {field_body, 4},
    {field_name, 1},
    {field_params, 2},
    {field_return, 3},
  [18] =
    {field_body, 4},
    {field_name, 2},
    {field_on_type, 1},
    {field_return, 3},
  [22] =
    {field_body, 5},
    {field_name, 2},
    {field_on_type, 1},
    {field_params, 3},
    {field_return, 4},
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
  [26] = 24,
  [27] = 27,
  [28] = 5,
  [29] = 29,
  [30] = 4,
  [31] = 31,
  [32] = 32,
  [33] = 33,
  [34] = 34,
  [35] = 35,
  [36] = 36,
  [37] = 37,
  [38] = 31,
  [39] = 32,
  [40] = 7,
  [41] = 29,
  [42] = 6,
  [43] = 43,
  [44] = 44,
  [45] = 45,
  [46] = 46,
  [47] = 47,
  [48] = 48,
  [49] = 43,
  [50] = 45,
  [51] = 51,
  [52] = 52,
  [53] = 51,
  [54] = 54,
  [55] = 54,
  [56] = 8,
  [57] = 13,
  [58] = 14,
  [59] = 59,
  [60] = 60,
  [61] = 61,
  [62] = 62,
  [63] = 63,
  [64] = 59,
  [65] = 65,
  [66] = 66,
  [67] = 67,
  [68] = 68,
  [69] = 69,
  [70] = 70,
  [71] = 71,
};

static bool ts_lex(TSLexer *lexer, TSStateId state) {
  START_LEXER();
  eof = lexer->eof(lexer);
  switch (state) {
    case 0:
      if (eof) ADVANCE(15);
      if (lookahead == '"') ADVANCE(10);
      if (lookahead == '(') ADVANCE(50);
      if (lookahead == ')') ADVANCE(51);
      if (lookahead == '*') ADVANCE(8);
      if (lookahead == '.') ADVANCE(1);
      if (lookahead == '\\') SKIP(14);
      if (lookahead == 'c') ADVANCE(40);
      if (lookahead == 'f') ADVANCE(29);
      if (lookahead == 't') ADVANCE(42);
      if (lookahead == '|') ADVANCE(52);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(0);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(55);
      if (('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      if (('A' <= lookahead && lookahead <= 'Z')) ADVANCE(28);
      END_STATE();
    case 1:
      if (lookahead == '\n') ADVANCE(24);
      END_STATE();
    case 2:
      if (lookahead == '\n') SKIP(9);
      END_STATE();
    case 3:
      if (lookahead == '\n') SKIP(9);
      if (lookahead == '\r') SKIP(2);
      END_STATE();
    case 4:
      if (lookahead == '\n') SKIP(11);
      END_STATE();
    case 5:
      if (lookahead == '\n') SKIP(11);
      if (lookahead == '\r') SKIP(4);
      END_STATE();
    case 6:
      if (lookahead == '\n') ADVANCE(21);
      if (lookahead == '\r') ADVANCE(18);
      if (lookahead == '\\') ADVANCE(19);
      if (lookahead != 0) ADVANCE(22);
      END_STATE();
    case 7:
      if (lookahead == '\r') ADVANCE(23);
      if (lookahead == '\\') ADVANCE(19);
      if (lookahead != 0) ADVANCE(22);
      END_STATE();
    case 8:
      if (lookahead == ' ') ADVANCE(16);
      END_STATE();
    case 9:
      if (lookahead == '"') ADVANCE(10);
      if (lookahead == '*') ADVANCE(8);
      if (lookahead == '\\') SKIP(3);
      if (lookahead == 'f') ADVANCE(30);
      if (lookahead == 't') ADVANCE(43);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(9);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(55);
      if (('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 10:
      if (lookahead == '"') ADVANCE(57);
      if (lookahead != 0) ADVANCE(10);
      END_STATE();
    case 11:
      if (lookahead == '(') ADVANCE(50);
      if (lookahead == ')') ADVANCE(51);
      if (lookahead == '*') ADVANCE(8);
      if (lookahead == '.') ADVANCE(1);
      if (lookahead == '\\') SKIP(5);
      if (lookahead == '|') ADVANCE(52);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(11);
      if (('A' <= lookahead && lookahead <= 'Z')) ADVANCE(28);
      if (('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 12:
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(56);
      END_STATE();
    case 13:
      if (eof) ADVANCE(15);
      if (lookahead == '\n') SKIP(0);
      END_STATE();
    case 14:
      if (eof) ADVANCE(15);
      if (lookahead == '\n') SKIP(0);
      if (lookahead == '\r') SKIP(13);
      END_STATE();
    case 15:
      ACCEPT_TOKEN(ts_builtin_sym_end);
      END_STATE();
    case 16:
      ACCEPT_TOKEN(anon_sym_STAR);
      END_STATE();
    case 17:
      ACCEPT_TOKEN(anon_sym_STAR);
      if (lookahead == '\\') ADVANCE(7);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(22);
      END_STATE();
    case 18:
      ACCEPT_TOKEN(aux_sym_comment_token1);
      if (lookahead == '\n') ADVANCE(21);
      if (lookahead == '\\') ADVANCE(7);
      if (lookahead != 0) ADVANCE(22);
      END_STATE();
    case 19:
      ACCEPT_TOKEN(aux_sym_comment_token1);
      if (lookahead == '\r') ADVANCE(23);
      if (lookahead == '\\') ADVANCE(19);
      if (lookahead != 0) ADVANCE(22);
      END_STATE();
    case 20:
      ACCEPT_TOKEN(aux_sym_comment_token1);
      if (lookahead == ' ') ADVANCE(17);
      if (lookahead == '\\') ADVANCE(7);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(22);
      END_STATE();
    case 21:
      ACCEPT_TOKEN(aux_sym_comment_token1);
      if (lookahead == '*') ADVANCE(20);
      if (lookahead == '\\') ADVANCE(6);
      if (lookahead == '\t' ||
          (0x0b <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(21);
      if (lookahead != 0 &&
          (lookahead < '\t' || '\r' < lookahead)) ADVANCE(22);
      END_STATE();
    case 22:
      ACCEPT_TOKEN(aux_sym_comment_token1);
      if (lookahead == '\\') ADVANCE(7);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(22);
      END_STATE();
    case 23:
      ACCEPT_TOKEN(aux_sym_comment_token1);
      if (lookahead == '\\') ADVANCE(7);
      if (lookahead != 0) ADVANCE(22);
      END_STATE();
    case 24:
      ACCEPT_TOKEN(anon_sym_DOT_LF);
      END_STATE();
    case 25:
      ACCEPT_TOKEN(anon_sym_type);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 26:
      ACCEPT_TOKEN(anon_sym_contract);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 27:
      ACCEPT_TOKEN(anon_sym_func);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 28:
      ACCEPT_TOKEN(aux_sym_type_identifier_token1);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(28);
      END_STATE();
    case 29:
      ACCEPT_TOKEN(sym_field_identifier);
      if (lookahead == 'a') ADVANCE(37);
      if (lookahead == 'u') ADVANCE(39);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('b' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 30:
      ACCEPT_TOKEN(sym_field_identifier);
      if (lookahead == 'a') ADVANCE(37);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('b' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 31:
      ACCEPT_TOKEN(sym_field_identifier);
      if (lookahead == 'a') ADVANCE(33);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('b' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 32:
      ACCEPT_TOKEN(sym_field_identifier);
      if (lookahead == 'c') ADVANCE(27);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 33:
      ACCEPT_TOKEN(sym_field_identifier);
      if (lookahead == 'c') ADVANCE(47);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 34:
      ACCEPT_TOKEN(sym_field_identifier);
      if (lookahead == 'e') ADVANCE(53);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 35:
      ACCEPT_TOKEN(sym_field_identifier);
      if (lookahead == 'e') ADVANCE(25);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 36:
      ACCEPT_TOKEN(sym_field_identifier);
      if (lookahead == 'e') ADVANCE(54);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 37:
      ACCEPT_TOKEN(sym_field_identifier);
      if (lookahead == 'l') ADVANCE(45);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 38:
      ACCEPT_TOKEN(sym_field_identifier);
      if (lookahead == 'n') ADVANCE(46);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 39:
      ACCEPT_TOKEN(sym_field_identifier);
      if (lookahead == 'n') ADVANCE(32);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 40:
      ACCEPT_TOKEN(sym_field_identifier);
      if (lookahead == 'o') ADVANCE(38);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 41:
      ACCEPT_TOKEN(sym_field_identifier);
      if (lookahead == 'p') ADVANCE(35);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 42:
      ACCEPT_TOKEN(sym_field_identifier);
      if (lookahead == 'r') ADVANCE(48);
      if (lookahead == 'y') ADVANCE(41);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 43:
      ACCEPT_TOKEN(sym_field_identifier);
      if (lookahead == 'r') ADVANCE(48);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 44:
      ACCEPT_TOKEN(sym_field_identifier);
      if (lookahead == 'r') ADVANCE(31);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 45:
      ACCEPT_TOKEN(sym_field_identifier);
      if (lookahead == 's') ADVANCE(36);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 46:
      ACCEPT_TOKEN(sym_field_identifier);
      if (lookahead == 't') ADVANCE(44);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 47:
      ACCEPT_TOKEN(sym_field_identifier);
      if (lookahead == 't') ADVANCE(26);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 48:
      ACCEPT_TOKEN(sym_field_identifier);
      if (lookahead == 'u') ADVANCE(34);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 49:
      ACCEPT_TOKEN(sym_field_identifier);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 50:
      ACCEPT_TOKEN(anon_sym_LPAREN);
      END_STATE();
    case 51:
      ACCEPT_TOKEN(anon_sym_RPAREN);
      END_STATE();
    case 52:
      ACCEPT_TOKEN(anon_sym_PIPE);
      END_STATE();
    case 53:
      ACCEPT_TOKEN(sym_true);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 54:
      ACCEPT_TOKEN(sym_false);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 55:
      ACCEPT_TOKEN(sym_int_literal);
      if (lookahead == '.') ADVANCE(12);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(55);
      END_STATE();
    case 56:
      ACCEPT_TOKEN(sym_float_literal);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(56);
      END_STATE();
    case 57:
      ACCEPT_TOKEN(sym_string_literal);
      END_STATE();
    default:
      return false;
  }
}

static const TSLexMode ts_lex_modes[STATE_COUNT] = {
  [0] = {.lex_state = 0},
  [1] = {.lex_state = 0},
  [2] = {.lex_state = 0},
  [3] = {.lex_state = 0},
  [4] = {.lex_state = 0},
  [5] = {.lex_state = 0},
  [6] = {.lex_state = 0},
  [7] = {.lex_state = 0},
  [8] = {.lex_state = 0},
  [9] = {.lex_state = 0},
  [10] = {.lex_state = 0},
  [11] = {.lex_state = 0},
  [12] = {.lex_state = 0},
  [13] = {.lex_state = 0},
  [14] = {.lex_state = 0},
  [15] = {.lex_state = 9},
  [16] = {.lex_state = 0},
  [17] = {.lex_state = 9},
  [18] = {.lex_state = 0},
  [19] = {.lex_state = 9},
  [20] = {.lex_state = 0},
  [21] = {.lex_state = 9},
  [22] = {.lex_state = 11},
  [23] = {.lex_state = 11},
  [24] = {.lex_state = 9},
  [25] = {.lex_state = 11},
  [26] = {.lex_state = 9},
  [27] = {.lex_state = 11},
  [28] = {.lex_state = 11},
  [29] = {.lex_state = 9},
  [30] = {.lex_state = 11},
  [31] = {.lex_state = 9},
  [32] = {.lex_state = 9},
  [33] = {.lex_state = 11},
  [34] = {.lex_state = 11},
  [35] = {.lex_state = 11},
  [36] = {.lex_state = 11},
  [37] = {.lex_state = 11},
  [38] = {.lex_state = 11},
  [39] = {.lex_state = 11},
  [40] = {.lex_state = 11},
  [41] = {.lex_state = 11},
  [42] = {.lex_state = 11},
  [43] = {.lex_state = 0},
  [44] = {.lex_state = 0},
  [45] = {.lex_state = 0},
  [46] = {.lex_state = 0},
  [47] = {.lex_state = 0},
  [48] = {.lex_state = 0},
  [49] = {.lex_state = 0},
  [50] = {.lex_state = 0},
  [51] = {.lex_state = 11},
  [52] = {.lex_state = 0},
  [53] = {.lex_state = 11},
  [54] = {.lex_state = 11},
  [55] = {.lex_state = 11},
  [56] = {.lex_state = 11},
  [57] = {.lex_state = 11},
  [58] = {.lex_state = 11},
  [59] = {.lex_state = 11},
  [60] = {.lex_state = 0},
  [61] = {.lex_state = 0},
  [62] = {.lex_state = 0},
  [63] = {.lex_state = 0},
  [64] = {.lex_state = 11},
  [65] = {.lex_state = 21},
  [66] = {.lex_state = 0},
  [67] = {.lex_state = 0},
  [68] = {.lex_state = 11},
  [69] = {.lex_state = 0},
  [70] = {.lex_state = 0},
  [71] = {(TSStateId)(-1)},
};

static const uint16_t ts_parse_table[LARGE_STATE_COUNT][SYMBOL_COUNT] = {
  [0] = {
    [sym_comment] = STATE(0),
    [ts_builtin_sym_end] = ACTIONS(1),
    [anon_sym_STAR] = ACTIONS(3),
    [anon_sym_DOT_LF] = ACTIONS(1),
    [anon_sym_type] = ACTIONS(1),
    [anon_sym_contract] = ACTIONS(1),
    [anon_sym_func] = ACTIONS(1),
    [aux_sym_type_identifier_token1] = ACTIONS(1),
    [sym_field_identifier] = ACTIONS(1),
    [anon_sym_LPAREN] = ACTIONS(1),
    [anon_sym_RPAREN] = ACTIONS(1),
    [anon_sym_PIPE] = ACTIONS(1),
    [sym_true] = ACTIONS(1),
    [sym_false] = ACTIONS(1),
    [sym_int_literal] = ACTIONS(1),
    [sym_float_literal] = ACTIONS(1),
    [sym_string_literal] = ACTIONS(1),
  },
  [1] = {
    [sym_source_file] = STATE(66),
    [sym_comment] = STATE(1),
    [sym__statement] = STATE(18),
    [sym__declaration] = STATE(16),
    [sym_type_declaration] = STATE(69),
    [sym_contract_declaration] = STATE(69),
    [sym_function_declaration] = STATE(69),
    [sym_expression] = STATE(12),
    [sym_single_expression] = STATE(9),
    [sym_pipe_expression] = STATE(9),
    [sym_call_expression] = STATE(9),
    [aux_sym_source_file_repeat1] = STATE(2),
    [ts_builtin_sym_end] = ACTIONS(5),
    [anon_sym_STAR] = ACTIONS(3),
    [anon_sym_type] = ACTIONS(7),
    [anon_sym_contract] = ACTIONS(9),
    [anon_sym_func] = ACTIONS(11),
    [sym_field_identifier] = ACTIONS(13),
    [sym_true] = ACTIONS(15),
    [sym_false] = ACTIONS(15),
    [sym_int_literal] = ACTIONS(15),
    [sym_float_literal] = ACTIONS(17),
    [sym_string_literal] = ACTIONS(17),
  },
  [2] = {
    [sym_comment] = STATE(2),
    [sym__statement] = STATE(18),
    [sym__declaration] = STATE(16),
    [sym_type_declaration] = STATE(69),
    [sym_contract_declaration] = STATE(69),
    [sym_function_declaration] = STATE(69),
    [sym_expression] = STATE(12),
    [sym_single_expression] = STATE(9),
    [sym_pipe_expression] = STATE(9),
    [sym_call_expression] = STATE(9),
    [aux_sym_source_file_repeat1] = STATE(3),
    [ts_builtin_sym_end] = ACTIONS(19),
    [anon_sym_STAR] = ACTIONS(3),
    [anon_sym_type] = ACTIONS(7),
    [anon_sym_contract] = ACTIONS(9),
    [anon_sym_func] = ACTIONS(11),
    [sym_field_identifier] = ACTIONS(13),
    [sym_true] = ACTIONS(15),
    [sym_false] = ACTIONS(15),
    [sym_int_literal] = ACTIONS(15),
    [sym_float_literal] = ACTIONS(17),
    [sym_string_literal] = ACTIONS(17),
  },
  [3] = {
    [sym_comment] = STATE(3),
    [sym__statement] = STATE(18),
    [sym__declaration] = STATE(16),
    [sym_type_declaration] = STATE(69),
    [sym_contract_declaration] = STATE(69),
    [sym_function_declaration] = STATE(69),
    [sym_expression] = STATE(12),
    [sym_single_expression] = STATE(9),
    [sym_pipe_expression] = STATE(9),
    [sym_call_expression] = STATE(9),
    [aux_sym_source_file_repeat1] = STATE(3),
    [ts_builtin_sym_end] = ACTIONS(21),
    [anon_sym_STAR] = ACTIONS(3),
    [anon_sym_type] = ACTIONS(23),
    [anon_sym_contract] = ACTIONS(26),
    [anon_sym_func] = ACTIONS(29),
    [sym_field_identifier] = ACTIONS(32),
    [sym_true] = ACTIONS(35),
    [sym_false] = ACTIONS(35),
    [sym_int_literal] = ACTIONS(35),
    [sym_float_literal] = ACTIONS(38),
    [sym_string_literal] = ACTIONS(38),
  },
};

static const uint16_t ts_small_parse_table[] = {
  [0] = 7,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(4), 1,
      sym_comment,
    STATE(7), 1,
      aux_sym_param_list_call_repeat1,
    STATE(10), 1,
      sym_param_list_call,
    STATE(13), 1,
      sym_param_definition,
    ACTIONS(41), 4,
      ts_builtin_sym_end,
      anon_sym_PIPE,
      sym_float_literal,
      sym_string_literal,
    ACTIONS(43), 7,
      anon_sym_type,
      anon_sym_contract,
      anon_sym_func,
      sym_field_identifier,
      sym_true,
      sym_false,
      sym_int_literal,
  [31] = 7,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(5), 1,
      sym_comment,
    STATE(7), 1,
      aux_sym_param_list_call_repeat1,
    STATE(10), 1,
      sym_param_list_call,
    STATE(13), 1,
      sym_param_definition,
    ACTIONS(41), 4,
      ts_builtin_sym_end,
      anon_sym_PIPE,
      sym_float_literal,
      sym_string_literal,
    ACTIONS(43), 7,
      anon_sym_type,
      anon_sym_contract,
      anon_sym_func,
      sym_field_identifier,
      sym_true,
      sym_false,
      sym_int_literal,
  [62] = 6,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(49), 1,
      sym_field_identifier,
    STATE(13), 1,
      sym_param_definition,
    STATE(6), 2,
      sym_comment,
      aux_sym_param_list_call_repeat1,
    ACTIONS(45), 4,
      ts_builtin_sym_end,
      anon_sym_PIPE,
      sym_float_literal,
      sym_string_literal,
    ACTIONS(47), 6,
      anon_sym_type,
      anon_sym_contract,
      anon_sym_func,
      sym_true,
      sym_false,
      sym_int_literal,
  [90] = 6,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(6), 1,
      aux_sym_param_list_call_repeat1,
    STATE(7), 1,
      sym_comment,
    STATE(13), 1,
      sym_param_definition,
    ACTIONS(52), 4,
      ts_builtin_sym_end,
      anon_sym_PIPE,
      sym_float_literal,
      sym_string_literal,
    ACTIONS(54), 7,
      anon_sym_type,
      anon_sym_contract,
      anon_sym_func,
      sym_field_identifier,
      sym_true,
      sym_false,
      sym_int_literal,
  [118] = 4,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(8), 1,
      sym_comment,
    ACTIONS(56), 5,
      ts_builtin_sym_end,
      anon_sym_DOT_LF,
      anon_sym_PIPE,
      sym_float_literal,
      sym_string_literal,
    ACTIONS(58), 7,
      anon_sym_type,
      anon_sym_contract,
      anon_sym_func,
      sym_field_identifier,
      sym_true,
      sym_false,
      sym_int_literal,
  [141] = 4,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(9), 1,
      sym_comment,
    ACTIONS(60), 5,
      ts_builtin_sym_end,
      anon_sym_DOT_LF,
      anon_sym_PIPE,
      sym_float_literal,
      sym_string_literal,
    ACTIONS(62), 7,
      anon_sym_type,
      anon_sym_contract,
      anon_sym_func,
      sym_field_identifier,
      sym_true,
      sym_false,
      sym_int_literal,
  [164] = 4,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(10), 1,
      sym_comment,
    ACTIONS(64), 5,
      ts_builtin_sym_end,
      anon_sym_DOT_LF,
      anon_sym_PIPE,
      sym_float_literal,
      sym_string_literal,
    ACTIONS(66), 7,
      anon_sym_type,
      anon_sym_contract,
      anon_sym_func,
      sym_field_identifier,
      sym_true,
      sym_false,
      sym_int_literal,
  [187] = 4,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(11), 1,
      sym_comment,
    ACTIONS(68), 5,
      ts_builtin_sym_end,
      anon_sym_DOT_LF,
      anon_sym_PIPE,
      sym_float_literal,
      sym_string_literal,
    ACTIONS(70), 7,
      anon_sym_type,
      anon_sym_contract,
      anon_sym_func,
      sym_field_identifier,
      sym_true,
      sym_false,
      sym_int_literal,
  [210] = 5,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(76), 1,
      anon_sym_PIPE,
    STATE(12), 1,
      sym_comment,
    ACTIONS(72), 3,
      ts_builtin_sym_end,
      sym_float_literal,
      sym_string_literal,
    ACTIONS(74), 7,
      anon_sym_type,
      anon_sym_contract,
      anon_sym_func,
      sym_field_identifier,
      sym_true,
      sym_false,
      sym_int_literal,
  [234] = 4,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(13), 1,
      sym_comment,
    ACTIONS(78), 4,
      ts_builtin_sym_end,
      anon_sym_PIPE,
      sym_float_literal,
      sym_string_literal,
    ACTIONS(80), 7,
      anon_sym_type,
      anon_sym_contract,
      anon_sym_func,
      sym_field_identifier,
      sym_true,
      sym_false,
      sym_int_literal,
  [256] = 4,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(14), 1,
      sym_comment,
    ACTIONS(82), 4,
      ts_builtin_sym_end,
      anon_sym_PIPE,
      sym_float_literal,
      sym_string_literal,
    ACTIONS(84), 7,
      anon_sym_type,
      anon_sym_contract,
      anon_sym_func,
      sym_field_identifier,
      sym_true,
      sym_false,
      sym_int_literal,
  [278] = 7,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(86), 1,
      sym_field_identifier,
    STATE(15), 1,
      sym_comment,
    STATE(60), 1,
      sym_expression,
    ACTIONS(17), 2,
      sym_float_literal,
      sym_string_literal,
    ACTIONS(15), 3,
      sym_true,
      sym_false,
      sym_int_literal,
    STATE(9), 3,
      sym_single_expression,
      sym_pipe_expression,
      sym_call_expression,
  [305] = 4,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(16), 1,
      sym_comment,
    ACTIONS(72), 3,
      ts_builtin_sym_end,
      sym_float_literal,
      sym_string_literal,
    ACTIONS(74), 7,
      anon_sym_type,
      anon_sym_contract,
      anon_sym_func,
      sym_field_identifier,
      sym_true,
      sym_false,
      sym_int_literal,
  [326] = 7,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(86), 1,
      sym_field_identifier,
    STATE(17), 1,
      sym_comment,
    STATE(61), 1,
      sym_expression,
    ACTIONS(17), 2,
      sym_float_literal,
      sym_string_literal,
    ACTIONS(15), 3,
      sym_true,
      sym_false,
      sym_int_literal,
    STATE(9), 3,
      sym_single_expression,
      sym_pipe_expression,
      sym_call_expression,
  [353] = 4,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(18), 1,
      sym_comment,
    ACTIONS(88), 3,
      ts_builtin_sym_end,
      sym_float_literal,
      sym_string_literal,
    ACTIONS(90), 7,
      anon_sym_type,
      anon_sym_contract,
      anon_sym_func,
      sym_field_identifier,
      sym_true,
      sym_false,
      sym_int_literal,
  [374] = 7,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(86), 1,
      sym_field_identifier,
    STATE(19), 1,
      sym_comment,
    STATE(62), 1,
      sym_expression,
    ACTIONS(17), 2,
      sym_float_literal,
      sym_string_literal,
    ACTIONS(15), 3,
      sym_true,
      sym_false,
      sym_int_literal,
    STATE(9), 3,
      sym_single_expression,
      sym_pipe_expression,
      sym_call_expression,
  [401] = 4,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(20), 1,
      sym_comment,
    ACTIONS(92), 3,
      ts_builtin_sym_end,
      sym_float_literal,
      sym_string_literal,
    ACTIONS(94), 7,
      anon_sym_type,
      anon_sym_contract,
      anon_sym_func,
      sym_field_identifier,
      sym_true,
      sym_false,
      sym_int_literal,
  [422] = 7,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(86), 1,
      sym_field_identifier,
    STATE(21), 1,
      sym_comment,
    STATE(63), 1,
      sym_expression,
    ACTIONS(17), 2,
      sym_float_literal,
      sym_string_literal,
    ACTIONS(15), 3,
      sym_true,
      sym_false,
      sym_int_literal,
    STATE(9), 3,
      sym_single_expression,
      sym_pipe_expression,
      sym_call_expression,
  [449] = 10,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(96), 1,
      aux_sym_type_identifier_token1,
    ACTIONS(98), 1,
      sym_field_identifier,
    ACTIONS(100), 1,
      anon_sym_LPAREN,
    STATE(21), 1,
      sym_type_identifier,
    STATE(22), 1,
      sym_comment,
    STATE(27), 1,
      aux_sym_param_list_repeat1,
    STATE(29), 1,
      sym_inline_function_declaration,
    STATE(34), 1,
      sym_param_declaration,
    STATE(44), 1,
      sym_param_list,
  [480] = 10,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(96), 1,
      aux_sym_type_identifier_token1,
    ACTIONS(98), 1,
      sym_field_identifier,
    ACTIONS(100), 1,
      anon_sym_LPAREN,
    STATE(15), 1,
      sym_type_identifier,
    STATE(23), 1,
      sym_comment,
    STATE(27), 1,
      aux_sym_param_list_repeat1,
    STATE(29), 1,
      sym_inline_function_declaration,
    STATE(34), 1,
      sym_param_declaration,
    STATE(52), 1,
      sym_param_list,
  [511] = 5,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(14), 1,
      sym_single_expression,
    STATE(24), 1,
      sym_comment,
    ACTIONS(17), 2,
      sym_float_literal,
      sym_string_literal,
    ACTIONS(15), 4,
      sym_field_identifier,
      sym_true,
      sym_false,
      sym_int_literal,
  [531] = 5,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(104), 1,
      sym_field_identifier,
    STATE(34), 1,
      sym_param_declaration,
    STATE(25), 2,
      sym_comment,
      aux_sym_param_list_repeat1,
    ACTIONS(102), 4,
      anon_sym_DOT_LF,
      aux_sym_type_identifier_token1,
      anon_sym_LPAREN,
      anon_sym_RPAREN,
  [551] = 5,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(26), 1,
      sym_comment,
    STATE(58), 1,
      sym_single_expression,
    ACTIONS(109), 2,
      sym_float_literal,
      sym_string_literal,
    ACTIONS(107), 4,
      sym_field_identifier,
      sym_true,
      sym_false,
      sym_int_literal,
  [571] = 6,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(98), 1,
      sym_field_identifier,
    STATE(25), 1,
      aux_sym_param_list_repeat1,
    STATE(27), 1,
      sym_comment,
    STATE(34), 1,
      sym_param_declaration,
    ACTIONS(111), 3,
      anon_sym_DOT_LF,
      aux_sym_type_identifier_token1,
      anon_sym_LPAREN,
  [592] = 7,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(113), 1,
      sym_field_identifier,
    STATE(10), 1,
      sym_param_list_call,
    STATE(28), 1,
      sym_comment,
    STATE(40), 1,
      aux_sym_param_list_call_repeat1,
    STATE(57), 1,
      sym_param_definition,
    ACTIONS(41), 2,
      anon_sym_DOT_LF,
      anon_sym_PIPE,
  [615] = 4,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(29), 1,
      sym_comment,
    ACTIONS(117), 2,
      sym_float_literal,
      sym_string_literal,
    ACTIONS(115), 4,
      sym_field_identifier,
      sym_true,
      sym_false,
      sym_int_literal,
  [632] = 7,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(113), 1,
      sym_field_identifier,
    STATE(10), 1,
      sym_param_list_call,
    STATE(30), 1,
      sym_comment,
    STATE(40), 1,
      aux_sym_param_list_call_repeat1,
    STATE(57), 1,
      sym_param_definition,
    ACTIONS(41), 2,
      anon_sym_DOT_LF,
      anon_sym_PIPE,
  [655] = 4,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(31), 1,
      sym_comment,
    ACTIONS(121), 2,
      sym_float_literal,
      sym_string_literal,
    ACTIONS(119), 4,
      sym_field_identifier,
      sym_true,
      sym_false,
      sym_int_literal,
  [672] = 4,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(32), 1,
      sym_comment,
    ACTIONS(125), 2,
      sym_float_literal,
      sym_string_literal,
    ACTIONS(123), 4,
      sym_field_identifier,
      sym_true,
      sym_false,
      sym_int_literal,
  [689] = 3,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(33), 1,
      sym_comment,
    ACTIONS(127), 5,
      anon_sym_DOT_LF,
      aux_sym_type_identifier_token1,
      sym_field_identifier,
      anon_sym_LPAREN,
      anon_sym_RPAREN,
  [703] = 3,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(34), 1,
      sym_comment,
    ACTIONS(129), 5,
      anon_sym_DOT_LF,
      aux_sym_type_identifier_token1,
      sym_field_identifier,
      anon_sym_LPAREN,
      anon_sym_RPAREN,
  [717] = 7,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(98), 1,
      sym_field_identifier,
    ACTIONS(131), 1,
      anon_sym_DOT_LF,
    STATE(27), 1,
      aux_sym_param_list_repeat1,
    STATE(34), 1,
      sym_param_declaration,
    STATE(35), 1,
      sym_comment,
    STATE(70), 1,
      sym_param_list,
  [739] = 7,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(98), 1,
      sym_field_identifier,
    ACTIONS(133), 1,
      anon_sym_DOT_LF,
    STATE(27), 1,
      aux_sym_param_list_repeat1,
    STATE(34), 1,
      sym_param_declaration,
    STATE(36), 1,
      sym_comment,
    STATE(67), 1,
      sym_param_list,
  [761] = 7,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(135), 1,
      aux_sym_type_identifier_token1,
    ACTIONS(137), 1,
      sym_field_identifier,
    ACTIONS(139), 1,
      anon_sym_LPAREN,
    STATE(37), 1,
      sym_comment,
    STATE(41), 1,
      sym_inline_function_declaration,
    STATE(68), 1,
      sym_type_identifier,
  [783] = 3,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(38), 1,
      sym_comment,
    ACTIONS(121), 5,
      anon_sym_DOT_LF,
      aux_sym_type_identifier_token1,
      sym_field_identifier,
      anon_sym_LPAREN,
      anon_sym_RPAREN,
  [797] = 3,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(39), 1,
      sym_comment,
    ACTIONS(125), 5,
      anon_sym_DOT_LF,
      aux_sym_type_identifier_token1,
      sym_field_identifier,
      anon_sym_LPAREN,
      anon_sym_RPAREN,
  [811] = 6,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(113), 1,
      sym_field_identifier,
    STATE(40), 1,
      sym_comment,
    STATE(42), 1,
      aux_sym_param_list_call_repeat1,
    STATE(57), 1,
      sym_param_definition,
    ACTIONS(52), 2,
      anon_sym_DOT_LF,
      anon_sym_PIPE,
  [831] = 3,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(41), 1,
      sym_comment,
    ACTIONS(117), 5,
      anon_sym_DOT_LF,
      aux_sym_type_identifier_token1,
      sym_field_identifier,
      anon_sym_LPAREN,
      anon_sym_RPAREN,
  [845] = 5,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(141), 1,
      sym_field_identifier,
    STATE(57), 1,
      sym_param_definition,
    ACTIONS(45), 2,
      anon_sym_DOT_LF,
      anon_sym_PIPE,
    STATE(42), 2,
      sym_comment,
      aux_sym_param_list_call_repeat1,
  [863] = 6,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(96), 1,
      aux_sym_type_identifier_token1,
    ACTIONS(100), 1,
      anon_sym_LPAREN,
    STATE(29), 1,
      sym_inline_function_declaration,
    STATE(31), 1,
      sym_type_identifier,
    STATE(43), 1,
      sym_comment,
  [882] = 6,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(96), 1,
      aux_sym_type_identifier_token1,
    ACTIONS(100), 1,
      anon_sym_LPAREN,
    STATE(17), 1,
      sym_type_identifier,
    STATE(29), 1,
      sym_inline_function_declaration,
    STATE(44), 1,
      sym_comment,
  [901] = 6,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(135), 1,
      aux_sym_type_identifier_token1,
    ACTIONS(139), 1,
      anon_sym_LPAREN,
    STATE(39), 1,
      sym_type_identifier,
    STATE(41), 1,
      sym_inline_function_declaration,
    STATE(45), 1,
      sym_comment,
  [920] = 6,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(135), 1,
      aux_sym_type_identifier_token1,
    ACTIONS(139), 1,
      anon_sym_LPAREN,
    STATE(35), 1,
      sym_type_identifier,
    STATE(41), 1,
      sym_inline_function_declaration,
    STATE(46), 1,
      sym_comment,
  [939] = 6,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(135), 1,
      aux_sym_type_identifier_token1,
    ACTIONS(139), 1,
      anon_sym_LPAREN,
    STATE(36), 1,
      sym_type_identifier,
    STATE(41), 1,
      sym_inline_function_declaration,
    STATE(47), 1,
      sym_comment,
  [958] = 6,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(135), 1,
      aux_sym_type_identifier_token1,
    ACTIONS(139), 1,
      anon_sym_LPAREN,
    STATE(33), 1,
      sym_type_identifier,
    STATE(41), 1,
      sym_inline_function_declaration,
    STATE(48), 1,
      sym_comment,
  [977] = 6,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(135), 1,
      aux_sym_type_identifier_token1,
    ACTIONS(139), 1,
      anon_sym_LPAREN,
    STATE(38), 1,
      sym_type_identifier,
    STATE(41), 1,
      sym_inline_function_declaration,
    STATE(49), 1,
      sym_comment,
  [996] = 6,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(96), 1,
      aux_sym_type_identifier_token1,
    ACTIONS(100), 1,
      anon_sym_LPAREN,
    STATE(29), 1,
      sym_inline_function_declaration,
    STATE(32), 1,
      sym_type_identifier,
    STATE(50), 1,
      sym_comment,
  [1015] = 6,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(98), 1,
      sym_field_identifier,
    ACTIONS(144), 1,
      anon_sym_RPAREN,
    STATE(34), 1,
      sym_param_declaration,
    STATE(51), 1,
      sym_comment,
    STATE(54), 1,
      aux_sym_param_list_repeat1,
  [1034] = 6,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(96), 1,
      aux_sym_type_identifier_token1,
    ACTIONS(100), 1,
      anon_sym_LPAREN,
    STATE(19), 1,
      sym_type_identifier,
    STATE(29), 1,
      sym_inline_function_declaration,
    STATE(52), 1,
      sym_comment,
  [1053] = 6,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(98), 1,
      sym_field_identifier,
    ACTIONS(146), 1,
      anon_sym_RPAREN,
    STATE(34), 1,
      sym_param_declaration,
    STATE(53), 1,
      sym_comment,
    STATE(55), 1,
      aux_sym_param_list_repeat1,
  [1072] = 6,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(98), 1,
      sym_field_identifier,
    ACTIONS(148), 1,
      anon_sym_RPAREN,
    STATE(25), 1,
      aux_sym_param_list_repeat1,
    STATE(34), 1,
      sym_param_declaration,
    STATE(54), 1,
      sym_comment,
  [1091] = 6,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(98), 1,
      sym_field_identifier,
    ACTIONS(150), 1,
      anon_sym_RPAREN,
    STATE(25), 1,
      aux_sym_param_list_repeat1,
    STATE(34), 1,
      sym_param_declaration,
    STATE(55), 1,
      sym_comment,
  [1110] = 3,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(56), 1,
      sym_comment,
    ACTIONS(56), 3,
      anon_sym_DOT_LF,
      sym_field_identifier,
      anon_sym_PIPE,
  [1122] = 3,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(57), 1,
      sym_comment,
    ACTIONS(78), 3,
      anon_sym_DOT_LF,
      sym_field_identifier,
      anon_sym_PIPE,
  [1134] = 3,
    ACTIONS(3), 1,
      anon_sym_STAR,
    STATE(58), 1,
      sym_comment,
    ACTIONS(82), 3,
      anon_sym_DOT_LF,
      sym_field_identifier,
      anon_sym_PIPE,
  [1146] = 4,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(152), 1,
      sym_field_identifier,
    STATE(11), 1,
      sym_call_expression,
    STATE(59), 1,
      sym_comment,
  [1159] = 4,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(154), 1,
      anon_sym_DOT_LF,
    ACTIONS(156), 1,
      anon_sym_PIPE,
    STATE(60), 1,
      sym_comment,
  [1172] = 4,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(156), 1,
      anon_sym_PIPE,
    ACTIONS(158), 1,
      anon_sym_DOT_LF,
    STATE(61), 1,
      sym_comment,
  [1185] = 4,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(156), 1,
      anon_sym_PIPE,
    ACTIONS(160), 1,
      anon_sym_DOT_LF,
    STATE(62), 1,
      sym_comment,
  [1198] = 4,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(156), 1,
      anon_sym_PIPE,
    ACTIONS(162), 1,
      anon_sym_DOT_LF,
    STATE(63), 1,
      sym_comment,
  [1211] = 4,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(164), 1,
      sym_field_identifier,
    STATE(11), 1,
      sym_call_expression,
    STATE(64), 1,
      sym_comment,
  [1224] = 3,
    ACTIONS(166), 1,
      anon_sym_STAR,
    ACTIONS(168), 1,
      aux_sym_comment_token1,
    STATE(65), 1,
      sym_comment,
  [1234] = 3,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(170), 1,
      ts_builtin_sym_end,
    STATE(66), 1,
      sym_comment,
  [1244] = 3,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(172), 1,
      anon_sym_DOT_LF,
    STATE(67), 1,
      sym_comment,
  [1254] = 3,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(174), 1,
      sym_field_identifier,
    STATE(68), 1,
      sym_comment,
  [1264] = 3,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(176), 1,
      anon_sym_DOT_LF,
    STATE(69), 1,
      sym_comment,
  [1274] = 3,
    ACTIONS(3), 1,
      anon_sym_STAR,
    ACTIONS(178), 1,
      anon_sym_DOT_LF,
    STATE(70), 1,
      sym_comment,
  [1284] = 1,
    ACTIONS(180), 1,
      ts_builtin_sym_end,
};

static const uint32_t ts_small_parse_table_map[] = {
  [SMALL_STATE(4)] = 0,
  [SMALL_STATE(5)] = 31,
  [SMALL_STATE(6)] = 62,
  [SMALL_STATE(7)] = 90,
  [SMALL_STATE(8)] = 118,
  [SMALL_STATE(9)] = 141,
  [SMALL_STATE(10)] = 164,
  [SMALL_STATE(11)] = 187,
  [SMALL_STATE(12)] = 210,
  [SMALL_STATE(13)] = 234,
  [SMALL_STATE(14)] = 256,
  [SMALL_STATE(15)] = 278,
  [SMALL_STATE(16)] = 305,
  [SMALL_STATE(17)] = 326,
  [SMALL_STATE(18)] = 353,
  [SMALL_STATE(19)] = 374,
  [SMALL_STATE(20)] = 401,
  [SMALL_STATE(21)] = 422,
  [SMALL_STATE(22)] = 449,
  [SMALL_STATE(23)] = 480,
  [SMALL_STATE(24)] = 511,
  [SMALL_STATE(25)] = 531,
  [SMALL_STATE(26)] = 551,
  [SMALL_STATE(27)] = 571,
  [SMALL_STATE(28)] = 592,
  [SMALL_STATE(29)] = 615,
  [SMALL_STATE(30)] = 632,
  [SMALL_STATE(31)] = 655,
  [SMALL_STATE(32)] = 672,
  [SMALL_STATE(33)] = 689,
  [SMALL_STATE(34)] = 703,
  [SMALL_STATE(35)] = 717,
  [SMALL_STATE(36)] = 739,
  [SMALL_STATE(37)] = 761,
  [SMALL_STATE(38)] = 783,
  [SMALL_STATE(39)] = 797,
  [SMALL_STATE(40)] = 811,
  [SMALL_STATE(41)] = 831,
  [SMALL_STATE(42)] = 845,
  [SMALL_STATE(43)] = 863,
  [SMALL_STATE(44)] = 882,
  [SMALL_STATE(45)] = 901,
  [SMALL_STATE(46)] = 920,
  [SMALL_STATE(47)] = 939,
  [SMALL_STATE(48)] = 958,
  [SMALL_STATE(49)] = 977,
  [SMALL_STATE(50)] = 996,
  [SMALL_STATE(51)] = 1015,
  [SMALL_STATE(52)] = 1034,
  [SMALL_STATE(53)] = 1053,
  [SMALL_STATE(54)] = 1072,
  [SMALL_STATE(55)] = 1091,
  [SMALL_STATE(56)] = 1110,
  [SMALL_STATE(57)] = 1122,
  [SMALL_STATE(58)] = 1134,
  [SMALL_STATE(59)] = 1146,
  [SMALL_STATE(60)] = 1159,
  [SMALL_STATE(61)] = 1172,
  [SMALL_STATE(62)] = 1185,
  [SMALL_STATE(63)] = 1198,
  [SMALL_STATE(64)] = 1211,
  [SMALL_STATE(65)] = 1224,
  [SMALL_STATE(66)] = 1234,
  [SMALL_STATE(67)] = 1244,
  [SMALL_STATE(68)] = 1254,
  [SMALL_STATE(69)] = 1264,
  [SMALL_STATE(70)] = 1274,
  [SMALL_STATE(71)] = 1284,
};

static const TSParseActionEntry ts_parse_actions[] = {
  [0] = {.entry = {.count = 0, .reusable = false}},
  [1] = {.entry = {.count = 1, .reusable = false}}, RECOVER(),
  [3] = {.entry = {.count = 1, .reusable = true}}, SHIFT(65),
  [5] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_source_file, 0, 0, 0),
  [7] = {.entry = {.count = 1, .reusable = false}}, SHIFT(46),
  [9] = {.entry = {.count = 1, .reusable = false}}, SHIFT(47),
  [11] = {.entry = {.count = 1, .reusable = false}}, SHIFT(37),
  [13] = {.entry = {.count = 1, .reusable = false}}, SHIFT(5),
  [15] = {.entry = {.count = 1, .reusable = false}}, SHIFT(8),
  [17] = {.entry = {.count = 1, .reusable = true}}, SHIFT(8),
  [19] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_source_file, 1, 0, 0),
  [21] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0),
  [23] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(46),
  [26] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(47),
  [29] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(37),
  [32] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(5),
  [35] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(8),
  [38] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(8),
  [41] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_call_expression, 1, 0, 1),
  [43] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_call_expression, 1, 0, 1),
  [45] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_param_list_call_repeat1, 2, 0, 0),
  [47] = {.entry = {.count = 1, .reusable = false}}, REDUCE(aux_sym_param_list_call_repeat1, 2, 0, 0),
  [49] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_param_list_call_repeat1, 2, 0, 0), SHIFT_REPEAT(24),
  [52] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_param_list_call, 1, 0, 0),
  [54] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_param_list_call, 1, 0, 0),
  [56] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_single_expression, 1, 0, 0),
  [58] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_single_expression, 1, 0, 0),
  [60] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_expression, 1, 0, 0),
  [62] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_expression, 1, 0, 0),
  [64] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_call_expression, 2, 0, 3),
  [66] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_call_expression, 2, 0, 3),
  [68] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_pipe_expression, 3, 0, 6),
  [70] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_pipe_expression, 3, 0, 6),
  [72] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym__statement, 1, 0, 0),
  [74] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym__statement, 1, 0, 0),
  [76] = {.entry = {.count = 1, .reusable = true}}, SHIFT(59),
  [78] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_param_list_call_repeat1, 1, 0, 0),
  [80] = {.entry = {.count = 1, .reusable = false}}, REDUCE(aux_sym_param_list_call_repeat1, 1, 0, 0),
  [82] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_param_definition, 2, 0, 5),
  [84] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_param_definition, 2, 0, 5),
  [86] = {.entry = {.count = 1, .reusable = false}}, SHIFT(28),
  [88] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_source_file_repeat1, 1, 0, 0),
  [90] = {.entry = {.count = 1, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 1, 0, 0),
  [92] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym__declaration, 2, 0, 0),
  [94] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym__declaration, 2, 0, 0),
  [96] = {.entry = {.count = 1, .reusable = true}}, SHIFT(29),
  [98] = {.entry = {.count = 1, .reusable = true}}, SHIFT(48),
  [100] = {.entry = {.count = 1, .reusable = true}}, SHIFT(53),
  [102] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_param_list_repeat1, 2, 0, 0),
  [104] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_param_list_repeat1, 2, 0, 0), SHIFT_REPEAT(48),
  [107] = {.entry = {.count = 1, .reusable = false}}, SHIFT(56),
  [109] = {.entry = {.count = 1, .reusable = true}}, SHIFT(56),
  [111] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_param_list, 1, 0, 0),
  [113] = {.entry = {.count = 1, .reusable = true}}, SHIFT(26),
  [115] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_type_identifier, 1, 0, 0),
  [117] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_type_identifier, 1, 0, 0),
  [119] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_inline_function_declaration, 3, 0, 0),
  [121] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_inline_function_declaration, 3, 0, 0),
  [123] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_inline_function_declaration, 4, 0, 0),
  [125] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_inline_function_declaration, 4, 0, 0),
  [127] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_param_declaration, 2, 0, 7),
  [129] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_param_list_repeat1, 1, 0, 0),
  [131] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_type_declaration, 2, 0, 2),
  [133] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_contract_declaration, 2, 0, 2),
  [135] = {.entry = {.count = 1, .reusable = true}}, SHIFT(41),
  [137] = {.entry = {.count = 1, .reusable = true}}, SHIFT(23),
  [139] = {.entry = {.count = 1, .reusable = true}}, SHIFT(51),
  [141] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_param_list_call_repeat1, 2, 0, 0), SHIFT_REPEAT(26),
  [144] = {.entry = {.count = 1, .reusable = true}}, SHIFT(49),
  [146] = {.entry = {.count = 1, .reusable = true}}, SHIFT(43),
  [148] = {.entry = {.count = 1, .reusable = true}}, SHIFT(45),
  [150] = {.entry = {.count = 1, .reusable = true}}, SHIFT(50),
  [152] = {.entry = {.count = 1, .reusable = true}}, SHIFT(4),
  [154] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_function_declaration, 4, 0, 8),
  [156] = {.entry = {.count = 1, .reusable = true}}, SHIFT(64),
  [158] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_function_declaration, 6, 0, 11),
  [160] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_function_declaration, 5, 0, 9),
  [162] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_function_declaration, 5, 0, 10),
  [164] = {.entry = {.count = 1, .reusable = true}}, SHIFT(30),
  [166] = {.entry = {.count = 1, .reusable = false}}, SHIFT(65),
  [168] = {.entry = {.count = 1, .reusable = false}}, SHIFT(71),
  [170] = {.entry = {.count = 1, .reusable = true}},  ACCEPT_INPUT(),
  [172] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_contract_declaration, 3, 0, 4),
  [174] = {.entry = {.count = 1, .reusable = true}}, SHIFT(22),
  [176] = {.entry = {.count = 1, .reusable = true}}, SHIFT(20),
  [178] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_type_declaration, 3, 0, 4),
  [180] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_comment, 2, 0, 0),
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

TS_PUBLIC const TSLanguage *tree_sitter_simpl(void) {
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
