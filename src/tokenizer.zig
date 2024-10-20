const std = @import("std");

pub const OpType = enum(u8) {
    START_PARSING,

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
        };
    }
};

pub const Token = struct {
    tag: Tag,
    loc: Location,

    pub const Tag = union(enum) {
        Number: struct { val: i16 },
        Op: OpType,

        Eof,
        Eol,
        Invalid,
    };

    pub const Location = struct { start: u32, end: u32 };

    pub fn toString(self: Token, allocator: std.mem.Allocator) std.fmt.AllocPrintError![]u8 {
        return switch (self.tag) {
            .Number => |num| std.fmt.allocPrint(allocator, "{}", .{num.val}),
            .Op => |op| std.fmt.allocPrint(allocator, "{s}", .{op.toString()}),
            .Eof => std.fmt.allocPrint(allocator, "eof", .{}),
            .Eol => std.fmt.allocPrint(allocator, "eol", .{}),
            .Invalid => std.fmt.allocPrint(allocator, "invalid", .{}),
        };
    }
};

pub const TokenList = std.MultiArrayList(Token);

pub const Tokenizer = struct {
    source: [:0]const u8,
    current: u32,

    pub fn next(self: *Tokenizer) Token {
        var result = Token{ .tag = Token.Tag.Invalid, .loc = .{ .start = self.current, .end = undefined } };

        var state: State = .START;

        while (true) : (self.current += 1) {
            const c = self.source[self.current];

            switch (state) {
                .START => switch (c) {
                    0 => {
                        result.tag = .Eof;
                        break;
                    },

                    ' ', '\r', '\t' => result.loc.start += 1,

                    '\n' => {
                        self.current += 1;
                        result.tag = .Eol;
                        break;
                    },
                    '+' => {
                        self.current += 1;
                        result.tag = .{ .Op = .PLUS };
                        break;
                    },
                    '-' => {
                        self.current += 1;
                        result.tag = .{ .Op = .MINUS };
                        break;
                    },
                    '*' => {
                        self.current += 1;
                        result.tag = .{ .Op = .STAR };
                        break;
                    },
                    '/' => {
                        self.current += 1;
                        result.tag = .{ .Op = .SLASH };
                        break;
                    },

                    '0'...'9' => state = .NUMBER,
                    '<' => state = .LESS_THAN,
                    '>' => state = .GREATER_THAN,

                    else => break,
                },

                .NUMBER => switch (c) {
                    '0'...'9' => {},
                    else => {
                        const text = self.source[result.loc.start..self.current];
                        if (std.fmt.parseInt(i16, text, 10)) |num| {
                            result.tag = .{ .Number = .{ .val = num } };
                        } else |_| {
                            result.tag = .Invalid;
                        }

                        break;
                    },
                },

                else => break,
            }
        }

        result.loc.end = self.current;
        return result;
    }

    const State = enum(u8) { START, NUMBER, STRING, IDENTIFIER, LESS_THAN, GREATER_THAN, COMMENT };
};
