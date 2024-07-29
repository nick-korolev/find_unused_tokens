const std = @import("std");
const file_reader = @import("./packages/file_reader.zig");

pub fn main() !void {
    const start_time = std.time.milliTimestamp();
    defer {
        const end_time = std.time.milliTimestamp();

        const duration = end_time - start_time;
        std.debug.print("Done: {} ms\n", .{duration});
    }
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();

        switch (leaked) {
            .leak => |l| std.debug.print("leaked {any}\n", .{l}),
            .ok => {},
        }
    }

    const allocator = gpa.allocator();

    _ = try file_reader.read_file(allocator, "./data/test.tsx");
}
