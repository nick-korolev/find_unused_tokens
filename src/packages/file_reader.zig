const std = @import("std");
const fs = std.fs;
const print = std.debug.print;

pub fn read_file(allocator: std.mem.Allocator, dest: []const u8) !void {
    const file = try fs.cwd().openFile(dest, .{});
    defer file.close();

    const file_size = try file.getEndPos();

    const buffer = try std.heap.page_allocator.alloc(u8, file_size);
    defer std.heap.page_allocator.free(buffer);

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    _ = try file.readAll(buffer);

    var id_map = std.StringHashMap(void).init(arena_allocator);
    defer id_map.deinit();

    try findIds(buffer, &id_map, arena_allocator, "id=\"", 3, '"');
    try findIds(buffer, &id_map, arena_allocator, "id='", 3, '\'');
    try findIds(buffer, &id_map, arena_allocator, "id:", 3, '\'');
    try findIds(buffer, &id_map, arena_allocator, "id:", 3, '"');

    var it_keys = id_map.keyIterator();
    while (it_keys.next()) |key| {
        std.debug.print("{s}\n", .{key.*});
    }
}

fn findIds(content: []const u8, id_map: *std.StringHashMap(void), allocator: std.mem.Allocator, id_start_pattern: []const u8, id_start_offset: usize, id_end_pattern: u8) !void {
    var start: usize = 0;
    while (std.mem.indexOfPos(u8, content, start, id_start_pattern)) |id_start| {
        var id_content_start = id_start + id_start_offset;

        // Пропускаем пробелы и переносы строк
        while (id_content_start < content.len and (content[id_content_start] == ' ' or content[id_content_start] == '\n' or content[id_content_start] == '\r')) {
            id_content_start += 1;
        }

        if (id_content_start < content.len and content[id_content_start] == id_end_pattern) {
            var id_end = id_content_start + 1;
            while (id_end < content.len and content[id_end] != id_end_pattern) {
                id_end += 1;
            }
            if (id_end < content.len and content[id_end] == id_end_pattern) {
                const id = try allocator.dupe(u8, content[id_content_start + 1 .. id_end]);
                if (id.len > 0) {
                    try id_map.put(id, {});
                }
            }
        }
        start = id_start + 1;
    }
}
