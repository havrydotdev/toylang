const std = @import("std");
const Lexer = @import("./Lexer.zig");
const Token = @import("./Token.zig");
const Executor = @import("./executor.zig").Executor;
const Parser = @import("./Parser.zig");
const ParserError = Parser.ParserError;

pub fn main() !void {
    const allocator = std.heap.c_allocator;
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);

    try stdout.print("Welcome to yet another toy language!\n", .{});

    if (argv.len == 1) {
        while (true) {
            try stdout.print("> ", .{});

            // Buffer
            var buf: [50:0]u8 = undefined;

            // Read the user input
            // the number of bytes written (if memory serves)
            const number_of_bytes = try stdin.read(&buf);

            var l = Lexer{ .current = 0, .source = &buf, .allocator = allocator };

            // Check the input length
            // considering the buffer size
            if (number_of_bytes == buf.len) {
                try stdout.print("Oops! The command is quite long, mind shortening?\n", .{});
                continue;
            }

            const tokens = try l.tokenize();

            var parser = Parser.init(allocator, tokens.items);
            const expr = parser.parseLine() catch continue;

            var executor = Executor.init(allocator, expr, stdout.any(), stdin.any());
            const value = executor.execute() catch continue;
            try stdout.print("{s}\n", .{try value.toString(allocator)});
        }
    }
}
