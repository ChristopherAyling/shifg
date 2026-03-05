// // Embedded assets for WASM builds
// // This file is at the project root so it can access assets/ directory

// // Sprite files
// pub const sprite_missing = @embedFile("assets/missing.png");
// pub const sprite_camera = @embedFile("assets/camera.png");
// pub const sprite_splash = @embedFile("assets/splash.png");
// pub const sprite_genly = @embedFile("assets/genly.png");
// pub const sprite_estraven = @embedFile("assets/estraven.png");
// pub const sprite_argaven = @embedFile("assets/argaven.png");
// pub const sprite_cursor = @embedFile("assets/cursor.png");
// pub const sprite_selector = @embedFile("assets/selector.png");
// pub const sprite_selector_active = @embedFile("assets/selector-active.png");
// pub const sprite_redflag = @embedFile("assets/redflag.png");
// pub const sprite_potion = @embedFile("assets/potion.png");
// pub const sprite_sword = @embedFile("assets/sword.png");
// pub const sprite_wand = @embedFile("assets/wand.png");

// // Level files - tutorial
// pub const level_tutorial_bg = @embedFile("assets/levels/tutorial/bg.png");
// pub const level_tutorial_fg = @embedFile("assets/levels/tutorial/fg.png");

// // Level files - parade
// pub const level_parade_bg = @embedFile("assets/levels/parade/bg.png");
// pub const level_parade_fg = @embedFile("assets/levels/parade/fg.png");
// pub const level_parade_things = @embedFile("assets/levels/parade/things.bin");

const std = @import("std");
const SpriteKey = @import("sprites.zig").SpriteKey;

pub const sprite_data = init: {
    var map = std.EnumArray(SpriteKey, []const u8).initUndefined();

    for (std.enums.values(SpriteKey)) |key| {
        map.set(key, @embedFile("assets/" ++ @tagName(key) ++ ".png"));
    }

    break :init map;
};
