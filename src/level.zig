const std = @import("std");
const assert = std.debug.assert;
const Image = @import("image.zig").Image;
const con = @import("constants.zig");
const dialogue = @import("dialogue.zig");
const ThingPool = @import("things.zig").ThingPool;
const io_native = @import("io_native.zig");

fn fileExistsAbsolute(path: []const u8) bool {
    std.fs.accessAbsolute(path, .{}) catch return false;
    return true;
}

pub const Level = struct {
    name: []const u8, // can lookup a static map
    path: []const u8,
    bg: Image,
    fg: Image,

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
