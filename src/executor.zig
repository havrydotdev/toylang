const std = @import("std");
const Expr = @import("./ast.zig").Expr;

pub const Executor = struct {
    allocator: std.mem.Allocator,
    node: *Expr,
    stdout: std.io.AnyWriter,
    stdin: std.io.AnyReader,

    pub fn init(allocator: std.mem.Allocator, node: *Expr, stdout: std.io.AnyWriter, stdin: std.io.AnyReader) Executor {
        return .{
            .allocator = allocator,
            .node = node,
            .stdout = stdout,
            .stdin = stdin,
        };
    }

    pub fn deinit(self: *Executor) void {
        self.node.deinit(self.allocator);
    }

    pub fn execute(self: *Executor) f64 {
        return executeExpr(self.node);
    }

    fn executeExpr(node: *const Expr) f64 {
        switch (node.*) {
            .Number => |num| return @as(f64, @floatFromInt(num)),
            .BinaryOp => |op| {
                return switch (op.op) {
                    .START_PARSING => {
                        std.debug.print("start parsing??", .{});
                        return 0;
                    },

                    .PLUS => executeExpr(op.lhs) + executeExpr(op.rhs),
                    .MINUS => executeExpr(op.lhs) - executeExpr(op.rhs),
                    .STAR => executeExpr(op.lhs) * executeExpr(op.rhs),
                    .SLASH => executeExpr(op.lhs) / executeExpr(op.rhs),
                };
            },
        }
    }
};
