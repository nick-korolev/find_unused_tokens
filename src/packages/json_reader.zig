const std = @import("std");

pub fn read_json(allocator: std.mem.Allocator, file_path: []const u8) !std.StringHashMap([]const u8) {
    const cwd = std.fs.cwd();
    const file = try cwd.readFileAlloc(allocator, file_path, std.math.maxInt(usize));
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, file, .{});
    defer parsed.deinit();

    var record = std.StringHashMap([]const u8).init(allocator);

    if (parsed.value != .object) {
        std.debug.print("Error: JSON root is not an object\n", .{});
        return record;
    }

    var it = parsed.value.object.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.* == .string) {
            try record.put(entry.key_ptr.*, entry.value_ptr.string);
        } else {
            std.debug.print("Warning: Skipping non-string value for key '{s}'\n", .{entry.key_ptr.*});
        }
    }

    return record;
}
