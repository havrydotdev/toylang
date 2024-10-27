const std = @import("std");
const Expr = @import("./ast.zig").Expr;
const lexer = @import("./lexer.zig");
const Token = @import("./Token.zig");
const Allocator = std.mem.Allocator;
const OpType = Token.OpType;

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

            .Op => |op| op: {
                if (op == .MINUS) {
                    const curr = self.peek();
                    if (curr.tag != .Number) {
                        std.debug.print("Expected negative number, got {any}", .{token.tag});
                        return ParserError.ParseFailed;
                    }

                    const expr: *Expr = try self.allocator.create(Expr);
                    expr.* = .{ .Number = -curr.tag.Number.val };

                    _ = self.next();

                    break :op expr;
                } else {
                    std.debug.print("Unexpected identifier {any}", .{token.tag});
                    return ParserError.ParseFailed;
                }
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

                    if (op == OpType.QUESTION_MARK) {
                        _ = self.next();

                        const true_expr: *Expr = try self.parseExpr(@intFromEnum(OpType.START_PARSING));

                        if (self.next().tag.Op != OpType.COLON) {
                            std.debug.print("Expected colon\n", .{});
                            return ParserError.ParseFailed;
                        }

                        const false_expr: *Expr = try self.parseExpr(@intFromEnum(OpType.START_PARSING));

                        const old_result = result;
                        result = try self.allocator.create(Expr);
                        result.* = .{ .Ternary = .{
                            .cond = old_result,
                            .tru = true_expr,
                            .fals = false_expr,
                        } };
                    } else {
                        _ = self.next();

                        const active_precedence = precedence + 1;
                        const rhs: *Expr = try self.parseExpr(active_precedence);

                        const old_result = result;
                        result = try self.allocator.create(Expr);
                        result.* = .{ .BinaryOp = .{ .op = op, .lhs = old_result, .rhs = rhs } };
                    }
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
