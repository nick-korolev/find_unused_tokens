const std = @import("std");
const file_reader = @import("./packages/file_reader.zig");
const directory_reader = @import("./packages/directory_reader.zig");
const json_reader = @import("./packages/json_reader.zig");

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

    var source_json = try json_reader.read_json(arena_allocator, "/Users/nick_korolev/Documents/work/StennAppWeb/apps/fcg/src/core/internationalization/en.json");
    defer {
        var it = source_json.iterator();
        while (it.next()) |entry| {
            arena_allocator.free(entry.value_ptr.*);
        }
    }

    const files = try directory_reader.read_directory(arena_allocator, "/Users/nick_korolev/Documents/work/StennAppWeb/apps/fcg/src");

    for (files.items) |file| {
        _ = try file_reader.read_file(allocator, file, &source_json);
    }

    var source_json_it = source_json.iterator();

    std.debug.print("Found {any} unused tokens", .{source_json.count()});

    while (source_json_it.next()) |entry| {
        std.debug.print("{s}: {s}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }
}
