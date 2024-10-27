const std = @import("std");
const Expr = @import("./ast.zig").Expr;
const Token = @import("./Token.zig");
const Allocator = std.mem.Allocator;
const OpType = Token.OpType;

const start_parsing = @intFromEnum(OpType.START_PARSING);

const Self = @This();

allocator: Allocator,
tokens: []const Token,
current: u32,

pub const ParserError = error{
    ParseFailed,
    OutOfMemory,
};

pub fn init(allocator: Allocator, tokens: []const Token) Self {
    return .{ .allocator = allocator, .tokens = tokens, .current = 0 };
}

pub fn deinit(self: *Self) void {
    self.tokens.deinit(self.allocator);
}

pub fn parseLine(self: *Self) ParserError!*Expr {
    return self.parseExpr(start_parsing);
}

fn parseExpr(self: *Self, min_precedence: u8) ParserError!*Expr {
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
                    std.debug.print("Expected negative number, got {s}\n", .{try token.tag.toString(self.allocator)});
                    return ParserError.ParseFailed;
                }

                const expr: *Expr = try self.allocator.create(Expr);
                expr.* = .{ .Number = -curr.tag.Number.val };

                _ = self.next();

                break :op expr;
            } else {
                std.debug.print("Unexpected identifier: '{s}'\n", .{try token.tag.toString(self.allocator)});
                return ParserError.ParseFailed;
            }
        },

        else => {
            std.debug.print("Not a number?? {s}\n", .{try token.tag.toString(self.allocator)});
            return ParserError.ParseFailed;
        },
    };

    while (self.current < self.tokens.len) {
        const new_tok = self.peek();
        switch (new_tok.tag) {
            .Number => |num| {
                std.debug.print("Unexpected number in the middle of expression: {d}\n", .{num.val});
                return ParserError.ParseFailed;
            },
            .Op => |op| {
                const precedence = opPrecedence(op);
                if (precedence < min_precedence) {
                    return result;
                }

                if (op == OpType.QUESTION_MARK) {
                    _ = self.next();

                    const true_expr: *Expr = try self.parseExpr(start_parsing);

                    if (self.next().tag.Op != OpType.COLON) {
                        std.debug.print("Expected colon\n", .{});

                        return ParserError.ParseFailed;
                    }

                    const false_expr: *Expr = try self.parseExpr(start_parsing);

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
                std.debug.print("Unexpected identifier: {s}\n", .{try new_tok.tag.toString(self.allocator)});
                return ParserError.ParseFailed;
            },
        }
    }

    return result;
}

pub fn opPrecedence(op: OpType) u8 {
    return @intFromEnum(op);
}

fn peek(self: *Self) Token {
    return self.tokens[self.current];
}

fn eatToken(self: *Self, tag: Token.Tag) !Token {
    return if (self.tokens[self.current] == tag) self.next() else null;
}

fn next(self: *Self) Token {
    const token = self.tokens[self.current];
    self.current += 1;
    return token;
}
