const tokenizer = @import("./tokenizer.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;
const Token = tokenizer.Token;
const OpType = tokenizer.OpType;

pub const Expr = union(enum) {
    Number: i64,
    BinaryOp: struct { op: OpType, lhs: *const Expr, rhs: *const Expr },

    pub fn deinit(self: *const Expr, allocator: Allocator) void {
        // Deinit children
        switch (self.*) {
            .Number => {},
            .BinaryOp => |binop| {
                binop.lhs.deinit(allocator);
                binop.rhs.deinit(allocator);
            },
        }

        // Deinit self
        allocator.destroy(self);
    }

    pub fn toString(self: Expr, allocator: std.mem.Allocator) std.fmt.AllocPrintError![]u8 {
        return switch (self) {
            .Number => |num| return std.fmt.allocPrint(allocator, "{}", .{num}),
            .BinaryOp => |op| return std.fmt.allocPrint(allocator, "({s} {s} {s})", .{ try op.lhs.toString(allocator), op.op.toString(), try op.rhs.toString(allocator) }),
        };
    }
};
