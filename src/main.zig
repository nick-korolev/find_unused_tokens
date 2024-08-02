const std = @import("std");
const file_reader = @import("./packages/file_reader.zig");
const directory_reader = @import("./packages/directory_reader.zig");
const json_reader = @import("./packages/json_reader.zig");
const args_reader = @import("./packages/args_reader.zig");
const hash_map_serializer = @import("./packages/hash_map_serializer.zig");

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

    var source_json = try json_reader.read_json(arena_allocator, config_file.source_path);
    defer {
        var it = source_json.iterator();
        while (it.next()) |entry| {
            arena_allocator.free(entry.value_ptr.*);
        }
    }

    var original_json = try source_json.cloneWithAllocator(arena_allocator);

    defer {
        var it = original_json.iterator();
        while (it.next()) |entry| {
            arena_allocator.free(entry.value_ptr.*);
        }
    }
    const files = try directory_reader.read_directory(arena_allocator, config_file.target_dir);

    for (files.items) |file| {
        _ = try file_reader.read_file(allocator, file, &source_json);
    }

    var source_json_it = source_json.iterator();

    var counter: i32 = 0;

    while (source_json_it.next()) |entry| {
        const key = entry.key_ptr.*;

        var skip = false;
        for (config_file.blacklist) |blacklist_item| {
            if (std.mem.indexOf(u8, key, blacklist_item) != null) {
                skip = true;
                break;
            }
        }

        if (skip) continue;
        counter += 1;
        if (args.fix) {
            _ = original_json.remove(key);
        } else {
            std.debug.print("{s}: {s}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
        }
    }
    std.debug.print("Found {any} unused tokens\n", .{counter});

    if (args.fix) {
        const json_str = try hash_map_serializer.serialize_string(original_json, arena_allocator);
        try std.fs.cwd().writeFile(.{
            .sub_path = config_file.source_path,
            .data = json_str,
        });
    }
}
