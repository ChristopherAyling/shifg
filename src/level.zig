const std = @import("std");
const assert = std.debug.assert;
const Image = @import("image.zig").Image;
const con = @import("constants.zig");
const dialogue = @import("dialogue.zig");
const audio = @import("audio.zig");
const ThingPool = @import("things.zig").ThingPool;

fn fileExistsAbsolute(path: []const u8) bool {
    std.fs.accessAbsolute(path, .{}) catch return false;
    return true;
}

pub const Level = struct {
    name: []const u8, // can lookup a static map
    path: []const u8,
    bg: Image,
    fg: Image,
    music: audio.MusicTrack,
    // TODO effects

    pub fn from_folder(path: []const u8, name: []const u8) Level {
        var buf: [256]u8 = undefined;

        const bg_path = std.fmt.bufPrintZ(&buf, "{s}/bg.png", .{path}) catch unreachable;
        const bg = Image.from_file(bg_path);

        const fg_path = std.fmt.bufPrintZ(&buf, "{s}/fg.png", .{path}) catch unreachable;
        const fg = Image.from_file(fg_path);

        return .{
            .name = name,
            .path = path,
            .bg = bg,
            .fg = fg,
            .music = undefined,
        };
    }

    pub fn load_things(self: Level, things: *ThingPool) void {
        var buf: [256]u8 = undefined;
        const things_path = std.fmt.bufPrintZ(&buf, "{s}/things.bin", .{self.path}) catch unreachable;
        things.from_file(things_path);
    }

    pub fn save_things(self: Level, things: *ThingPool) void {
        var buf: [256]u8 = undefined;
        const things_path = std.fmt.bufPrintZ(&buf, "{s}/things.bin", .{self.path}) catch unreachable;
        things.to_file(things_path);
    }
};
