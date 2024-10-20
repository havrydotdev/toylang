const std = @import("std");
const Expr = @import("./ast.zig").Expr;
const tokenizer = @import("./tokenizer.zig");
const Allocator = std.mem.Allocator;
const Token = tokenizer.Token;
const OpType = tokenizer.OpType;

pub const Parser = struct {
    allocator: Allocator,
    tokens: []const Token,
    current: u32,

    const ParserError = error{
        ParseFailed,
        OutOfMemory,
    };

    pub fn init(allocator: Allocator, tokens: []const Token) Parser {
        return .{ .allocator = allocator, .tokens = tokens, .current = 0 };
    }

    pub fn deinit(self: *Parser) void {
        self.tokens.deinit(self.allocator);
    }

    pub fn parseLine(self: *Parser) ParserError!*Expr {
        return self.parseExpr(@intFromEnum(OpType.START_PARSING));
    }

    fn parseExpr(self: *Parser, min_precedence: u8) ParserError!*Expr {
        const token = self.next();

        var result: *Expr = switch (token.tag) {
            .Number => |num| num: {
                const expr: *Expr = try self.allocator.create(Expr);
                expr.* = .{ .Number = num.val };
                break :num expr;
            },

            else => {
                std.debug.print("Not a number?? {any}", .{token.tag});
                return ParserError.ParseFailed;
            },
        };

        while (self.current < self.tokens.len) {
            const new_tok = self.peek();
            switch (new_tok.tag) {
                .Number => |num| {
                    std.debug.print("Unexpected number in the middle of expression: {any}\n", .{num});
                    return ParserError.ParseFailed;
                },
                .Op => |op| {
                    const precedence = opPrecedence(op);
                    if (precedence < min_precedence) {
                        return result;
                    }

                    _ = self.next();

                    const active_precedence = precedence + 1;
                    const rhs: *Expr = try self.parseExpr(active_precedence);

                    const old_result = result;
                    result = try self.allocator.create(Expr);
                    result.* = .{ .BinaryOp = .{ .op = op, .lhs = old_result, .rhs = rhs } };
                },

                else => {
                    std.debug.print("Unexpected shiiiieeet?? {any}", .{new_tok.tag});
                    return ParserError.ParseFailed;
                },
            }
        }

        return result;
    }

    pub fn opPrecedence(op: OpType) u8 {
        return @intFromEnum(op);
    }

    fn peek(self: *Parser) Token {
        return self.tokens[self.current];
    }

    fn eatToken(self: *Parser, tag: Token.Tag) !Token {
        return if (self.tokens[self.current] == tag) self.next() else null;
    }

    fn next(self: *Parser) Token {
        const token = self.tokens[self.current];
        self.current += 1;
        return token;
    }
};
