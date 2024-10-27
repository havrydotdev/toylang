const std = @import("std");
const Token = @import("./Token.zig");

const Self = @This();

source: [:0]const u8,
current: u32,
allocator: std.mem.Allocator,

pub fn tokenize(self: *Self) !std.ArrayListAligned(Token, null) {
    var tokens = std.ArrayList(Token).init(self.allocator);
    while (true) {
        const tok = self.next();
        if (tok.tag == Token.Tag.Eol) break;
        try tokens.append(tok);
    }

    return tokens;
}

fn next(self: *Self) Token {
    var result = Token{ .tag = Token.Tag.Eof, .loc = .{ .start = self.current, .end = undefined } };

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

                else => |char| {
                    self.current += 1;
                    result.tag = .{ .Invalid = .{ .val = &[_]u8{char} } };
                    break;
                },
            },

            .NUMBER => switch (c) {
                '0'...'9' => {},
                else => {
                    const text = self.source[result.loc.start..self.current];
                    if (std.fmt.parseInt(i64, text, 10)) |num| {
                        result.tag = .{ .Number = .{ .val = num } };
                    } else |_| {
                        result.tag = .{ .Invalid = .{ .val = text } };
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
