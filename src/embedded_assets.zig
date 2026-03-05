const std = @import("std");
const SpriteKey = @import("sprites.zig").SpriteKey;

pub const sprite_data = init: {
    var map = std.EnumArray(SpriteKey, []const u8).initUndefined();

    for (std.enums.values(SpriteKey)) |key| {
        map.set(key, @embedFile("assets/" ++ @tagName(key) ++ ".png"));
    }

    break :init map;
};
