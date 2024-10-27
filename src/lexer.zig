const std = @import("std");
const Token = @import("./Token.zig");

pub const TokenList = std.MultiArrayList(Token);

pub const Lexer = struct {
    source: [:0]const u8,
    current: u32,

    pub fn next(self: *Lexer) Token {
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
                    '=' => {
                        self.current += 2;
                        result.tag = .{ .Op = .EQUAL };
                        break;
                    },
                    '!' => {
                        self.current += 2;
                        result.tag = .{ .Op = .NOT_EQUAL };
                        break;
                    },
                    '?' => {
                        self.current += 1;
                        result.tag = .{ .Op = .QUESTION_MARK };
                        break;
                    },
                    ':' => {
                        self.current += 1;
                        result.tag = .{ .Op = .COLON };
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
                        if (std.fmt.parseInt(i64, text, 10)) |num| {
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
