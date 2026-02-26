const std = @import("std");
const tokenizer = @import("syntax/tokenizer.zig");


test "test kwords" {
    try std.testing.expect(tokenizer.keywords.get("and") == .kword_and);
}
