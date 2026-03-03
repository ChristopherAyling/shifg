const std = @import("std");
const assert = std.debug.assert;
const Image = @import("image.zig").Image;

pub const Level = struct {
    name: []const u8,
    bg: Image,
    fg: Image,
};
