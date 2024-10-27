const std = @import("std");

pub const Self = @This();

tag: Tag,
loc: Location,

pub const OpType = enum(u8) {
    COLON,

    START_PARSING,

    QUESTION_MARK,

    EQUAL,
    NOT_EQUAL,

    PLUS,
    MINUS,
    STAR,
    SLASH,

    pub fn toString(self: OpType) []const u8 {
        return switch (self) {
            .START_PARSING => "invalid",

            .PLUS => "+",
            .MINUS => "-",
            .STAR => "*",
            .SLASH => "/",
            .COLON => ":",
            .EQUAL => "==",
            .NOT_EQUAL => "!=",
            .QUESTION_MARK => "?",
        };
    }
};

pub const Tag = union(enum) {
    Number: struct { val: i64 },
    String: struct { val: []const u8 },

    Op: OpType,

    LeftParen,
    RightParen,

    Eof,
    Eol,
    Invalid,
};

pub const Location = struct { start: u32, end: u32 };

pub fn toString(self: Self, allocator: std.mem.Allocator) std.fmt.AllocPrintError![]u8 {
    return switch (self.tag) {
        .Number => |num| std.fmt.allocPrint(allocator, "{}", .{num.val}),
        .Op => |op| std.fmt.allocPrint(allocator, "{s}", .{op.toString()}),
        .Eof => std.fmt.allocPrint(allocator, "eof", .{}),
        .Eol => std.fmt.allocPrint(allocator, "eol", .{}),
        .Invalid => std.fmt.allocPrint(allocator, "invalid", .{}),
    };
}
