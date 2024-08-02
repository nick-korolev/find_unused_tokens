const std = @import("std");

pub fn serialize_string(map: std.StringHashMap([]const u8), allocator: std.mem.Allocator) ![]u8 {
    var json_object = std.json.ObjectMap.init(allocator);
    defer json_object.deinit();

    var keys = try allocator.alloc([]const u8, map.count());
    defer allocator.free(keys);

    var i: usize = 0;
    var it = map.iterator();
    while (it.next()) |entry| {
        keys[i] = entry.key_ptr.*;
        i += 1;
    }

    std.mem.sort([]const u8, keys, {}, struct {
        fn lessThan(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.lessThan(u8, a, b);
        }
    }.lessThan);

    for (keys) |key| {
        if (map.get(key)) |value| {
            try json_object.put(key, std.json.Value{ .string = value });
        }
    }

    const json_value = std.json.Value{ .object = json_object };
    return std.json.stringifyAlloc(allocator, json_value, .{ .whitespace = .indent_2 });
}
