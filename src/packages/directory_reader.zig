const std = @import("std");

pub fn read_directory(allocator: std.mem.Allocator, path: []const u8) !std.ArrayList([]const u8) {
    var dir = try std.fs.cwd().openDir(path, .{ .iterate = true });
    defer dir.close();

    var iter = dir.iterate();

    var array = std.ArrayList([]const u8).init(allocator);
    errdefer {
        for (array.items) |item| {
            allocator.free(item);
        }
        array.deinit();
    }

    while (try iter.next()) |entry| {
        switch (entry.kind) {
            .file => {
                const file_path = try std.fs.path.join(allocator, &[_][]const u8{ path, entry.name });
                if (hasValidExtension(file_path)) {
                    try array.append(file_path);
                }
            },
            .directory => {
                const subdir_path = try std.fs.path.join(allocator, &[_][]const u8{ path, entry.name });
                const subdir_array = try read_directory(allocator, subdir_path);
                try array.appendSlice(subdir_array.items);
                allocator.free(subdir_path);
                subdir_array.deinit();
            },
            else => {},
        }
    }
    return array;
}

fn hasValidExtension(file_name: []const u8) bool {
    const valid_extensions = [_][]const u8{ ".tsx", ".ts", ".js", ".jsx" };
    for (valid_extensions) |ext| {
        if (std.mem.endsWith(u8, file_name, ext)) {
            return true;
        }
    }
    return false;
}
