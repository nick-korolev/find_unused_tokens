const std = @import("std");
const file_reader = @import("./packages/file_reader.zig");
const directory_reader = @import("./packages/directory_reader.zig");

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

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const files = try directory_reader.read_directory(arena_allocator, "./data");

    for (files.items) |file| {
        _ = try file_reader.read_file(allocator, file);
    }
}
