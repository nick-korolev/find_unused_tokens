const std = @import("std");
const args_reader = @import("./args_reader.zig");
const json_reader = @import("./json_reader.zig");
const hash_map_serializer = @import("./hash_map_serializer.zig");

const ProcessSourcesParams = struct {
    config: *const args_reader.Config,
    main_source_json: *const std.StringHashMap([]const u8),
    fix: bool,
};

pub fn process_sources(allocator: std.mem.Allocator, params: ProcessSourcesParams) !void {
    const sources = params.config.*.sources;
    const source_json = params.main_source_json.*;
    const blacklist = params.config.*.blacklist;
    const fix = params.fix;
    var counter: i32 = 0;
    for (sources) |source_path| {
        var original_json = try json_reader.read_json(allocator, source_path);

        defer {
            var it = original_json.iterator();
            while (it.next()) |entry| {
                allocator.free(entry.value_ptr.*);
            }
        }

        var source_json_it = source_json.iterator();

        while (source_json_it.next()) |entry| {
            const key = entry.key_ptr.*;

            var skip = false;
            for (blacklist) |blacklist_item| {
                if (std.mem.indexOf(u8, key, blacklist_item) != null) {
                    skip = true;
                    break;
                }
            }

            if (skip) continue;
            if (fix == true) {
                _ = original_json.remove(key);
            } else {
                std.debug.print("{s}\n", .{key});
            }
            counter += 1;
        }

        if (fix == true) {
            const json_str = try hash_map_serializer.serialize_string(original_json, allocator);
            try std.fs.cwd().writeFile(.{
                .sub_path = source_path,
                .data = json_str,
            });
        }
    }
    std.debug.print("Found {any} unused tokens (in {any} files) \n", .{ counter, sources.len });
}
