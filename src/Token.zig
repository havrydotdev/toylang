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
    Invalid: struct { val: []const u8 },

    Op: OpType,

    LeftParen,
    RightParen,

    Eof,
    Eol,

    pub fn toString(self: Tag, allocator: std.mem.Allocator) std.fmt.AllocPrintError![]u8 {
        return switch (self) {
            .Number => |num| std.fmt.allocPrint(allocator, "{d}", .{num.val}),
            .String => |str| std.fmt.allocPrint(allocator, "{s}", .{str.val}),
            .Invalid => |inv| std.fmt.allocPrint(allocator, "{s}", .{inv.val}),
            .Op => |op| std.fmt.allocPrint(allocator, "{s}", .{op.toString()}),
            .RightParen => std.fmt.allocPrint(allocator, ")", .{}),
            .LeftParen => std.fmt.allocPrint(allocator, "(", .{}),
            .Eof => std.fmt.allocPrint(allocator, "eof", .{}),
            .Eol => std.fmt.allocPrint(allocator, "\n", .{}),
        };
    }
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
