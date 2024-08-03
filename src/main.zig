const std = @import("std");
const file_reader = @import("./packages/file_reader.zig");
const directory_reader = @import("./packages/directory_reader.zig");
const json_reader = @import("./packages/json_reader.zig");
const args_reader = @import("./packages/args_reader.zig");
const hash_map_serializer = @import("./packages/hash_map_serializer.zig");
const helpers = @import("./packages/helpers.zig");

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

    const args = try args_reader.read_args(allocator);
    defer allocator.free(args.config_path);

    const config_file = try args_reader.read_config(arena_allocator, args.config_path);

    const files = try directory_reader.read_directory(arena_allocator, config_file.target_dir);

    const main_source_path = config_file.sources[0];

    var source_json = try json_reader.read_json(arena_allocator, main_source_path);

    defer {
        var it = source_json.iterator();
        while (it.next()) |entry| {
            arena_allocator.free(entry.value_ptr.*);
        }
    }

    for (files.items) |file| {
        _ = try file_reader.put_unused_keys(allocator, file, &source_json);
    }

    try helpers.process_sources(arena_allocator, .{ .config = &config_file, .fix = args.fix, .main_source_json = &source_json });
}
