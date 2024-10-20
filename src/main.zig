const std = @import("std");
const Tokenizer = @import("./tokenizer.zig").Tokenizer;
const Token = @import("./tokenizer.zig").Token;
const Parser = @import("./parser.zig").Parser;
const Executor = @import("./executor.zig").Executor;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) @panic("Memory leak!");
    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);
    if (argv.len == 1) {
        while (true) {
            try stdout.print("tpascal > ", .{});

            // Buffer
            var buf: [50:0]u8 = undefined;

            // Read the user input
            // the number of bytes written (if memory serves)
            const number_of_bytes = try stdin.read(&buf);

            var l = Tokenizer{ .current = 0, .source = &buf };

            // Check the input length
            // considering the buffer size
            if (number_of_bytes == buf.len) {
                try stdout.print("Oops! The command is quite long, mind shortening?\n", .{});
                continue;
            }

            var tokens = std.ArrayList(Token).init(allocator);
            while (true) {
                const token = l.next();
                if (token.tag == Token.Tag.Eol) break;
                try tokens.append(token);
            }

            var parser = Parser.init(allocator, tokens.items);
            const expr = try parser.parseLine();
            // try stdout.print("lhs: {s}, rhs: {s}\n", .{ try expr.BinaryOp.lhs.toString(allocator), try expr.BinaryOp.rhs.toString(allocator) });

            var executor = Executor.init(allocator, expr, stdout.any(), stdin.any());
            try stdout.print("Executor result: {d}\n", .{executor.execute()});
        }
    }
}
