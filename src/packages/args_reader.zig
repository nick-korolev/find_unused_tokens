const std = @import("std");
const json = std.json;

const Result = struct {
    config_path: []const u8,
    fix: bool,
};

const ReadError = error{
    ParamsRequired,
};

pub fn read_args(allocator: std.mem.Allocator) !Result {
    const args = try std.process.argsAlloc(allocator);

    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        return ReadError.ParamsRequired;
    }

    const config_path = try allocator.dupe(u8, args[1]);
    errdefer allocator.free(config_path);

    var fix = false;

    const fix_str: []const u8 = "--fix";

    for (args) |arg| {
        if (std.mem.eql(u8, arg, fix_str)) {
            fix = true;
            continue;
        }
    }

    return Result{ .config_path = config_path, .fix = fix };
}

const Config = struct {
    sources: [][]const u8,
    target_dir: []const u8,
    blacklist: [][]const u8,

    pub fn deinit(self: *Config, allocator: std.mem.Allocator) void {
        allocator.free(self.source_path);
        allocator.free(self.target_dir);
        for (self.blacklist) |item| {
            allocator.free(item);
        }
        for (self.other_sources) |item| {
            allocator.free(item);
        }
        allocator.free(self.blacklist);
        allocator.free(self.other_sources);
    }
};

const ConfigError = error{
    SourcePathRequired,
    TargetDirRequired,
};

pub fn read_config(allocator: std.mem.Allocator, config_path: []const u8) !Config {
    const json_str = try std.fs.cwd().readFileAlloc(allocator, config_path, std.math.maxInt(usize));
    defer allocator.free(json_str);

    var parsed = try json.parseFromSlice(json.Value, allocator, json_str, .{});
    defer parsed.deinit();

    const root = parsed.value.object;

    var config: Config = undefined;

    config.target_dir = try allocator.dupe(u8, root.get("target_dir").?.string);

    if (config.target_dir.len == 0) {
        return ConfigError.TargetDirRequired;
    }

    const blacklist_json = root.get("blacklist").?.array;
    config.blacklist = try allocator.alloc([]const u8, blacklist_json.items.len);
    for (blacklist_json.items, 0..) |item, i| {
        config.blacklist[i] = try allocator.dupe(u8, item.string);
    }

    const sources_json = root.get("sources").?.array;
    config.sources = try allocator.alloc([]const u8, sources_json.items.len);
    for (sources_json.items, 0..) |item, i| {
        config.sources[i] = try allocator.dupe(u8, item.string);
    }

    return config;
}
