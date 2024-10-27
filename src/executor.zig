const std = @import("std");
const Expr = @import("./ast.zig").Expr;

pub const RuntimeValue = union(enum) {
    Number: f64,
    Boolean: bool,
    String: []const u8,

    pub fn toString(self: RuntimeValue, allocator: std.mem.Allocator) std.fmt.AllocPrintError![]u8 {
        return switch (self) {
            .Number => |num| std.fmt.allocPrint(allocator, "{d}", .{num}),
            .Boolean => |boolean| std.fmt.allocPrint(allocator, "{any}", .{boolean}),
            .String => |str| std.fmt.allocPrint(allocator, "\"{s}\"", .{str}),
        };
    }
};

pub const RuntimeError = error{
    UnknownOp,
    InvalidType,
} || std.fmt.AllocPrintError;

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

    pub fn execute(self: *Executor) RuntimeError!RuntimeValue {
        return self.executeExpr(self.node);
    }

    fn executeExpr(self: *Executor, node: *const Expr) RuntimeError!RuntimeValue {
        switch (node.*) {
            .Number => |num| return .{ .Number = @as(f64, @floatFromInt(num)) },
            .BinaryOp => |op| {
                return switch (op.op) {
                    .PLUS => .{ .Number = try self.expectNumber(op.lhs) + try self.expectNumber(op.rhs) },
                    .MINUS => .{ .Number = try self.expectNumber(op.lhs) - try self.expectNumber(op.rhs) },
                    .STAR => .{ .Number = try self.expectNumber(op.lhs) * try self.expectNumber(op.rhs) },
                    .SLASH => .{ .Number = try self.expectNumber(op.lhs) / try self.expectNumber(op.rhs) },
                    .EQUAL => .{ .Boolean = try self.expectNumber(op.lhs) == try self.expectNumber(op.rhs) },
                    .NOT_EQUAL => .{ .Boolean = try self.expectNumber(op.lhs) != try self.expectNumber(op.rhs) },

                    .START_PARSING => unreachable,

                    else => RuntimeError.UnknownOp,
                };
            },

            .Ternary => |ternary| {
                return switch (try self.executeExpr(ternary.cond)) {
                    .Boolean => |boolean| self.executeExpr(if (boolean) ternary.tru else ternary.fals),

                    else => |val| {
                        std.debug.print("Expected bool, got: {s}\n", .{try val.toString(self.allocator)});
                        return RuntimeError.InvalidType;
                    },
                };
            },
        }
    }

    fn expectNumber(self: *Executor, node: *const Expr) RuntimeError!f64 {
        return switch (try self.executeExpr(node)) {
            .Number => |num| num,

            else => |val| {
                std.debug.print("Expected number, got: {s}\n", .{try val.toString(self.allocator)});
                return RuntimeError.InvalidType;
            },
        };
    }
};
