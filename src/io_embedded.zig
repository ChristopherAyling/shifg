// this module is like io_native but everything must be embedded into the file using @embedFile or something
// will be used by wasm etc where no io with a filesystem is possible.

const std = @import("std");
const Image = @import("image.zig").Image;
const Level = @import("level.zig").Level;
const sprites = @import("sprites.zig");
const SpriteKey = sprites.SpriteKey;
const SpriteStorage = sprites.SpriteStorage;
const ThingPool = @import("things.zig").ThingPool;

const stbi = @cImport({
    @cDefine("STB_IMAGE_IMPLEMENTATION", "1");
    @cDefine("STBI_NO_GIF", "1");
    @cDefine("STBI_NO_HDR", "1");
    @cDefine("STBI_NO_TGA", "1");
    @cDefine("STBI_NO_PSD", "1");
    @cDefine("STBI_NO_PIC", "1");
    @cDefine("STBI_NO_PNM", "1");
    @cDefine("STBI_NO_STDIO", "1");
    @cInclude("stb_image.h");
});

// Embedded assets - provided by build.zig as a module
const assets = @import("embedded_assets");

fn image_from_memory(data: []const u8) Image {
    var x: c_int = undefined;
    var y: c_int = undefined;
    var channels_in_file: c_int = undefined;

    const raw = stbi.stbi_load_from_memory(data.ptr, @intCast(data.len), &x, &y, &channels_in_file, 4) orelse {
        @panic("Failed to load embedded image");
    };

    const pixels = @as(usize, @intCast(x)) * @as(usize, @intCast(y));
    const pixel_data: [*]u32 = @ptrCast(@alignCast(raw));

    for (0..pixels) |i| {
        const pixel = pixel_data[i];
        // stb: memory is R,G,B,A -> as u32 little-endian: 0xAABBGGRR
        // we need: 0x00RRGGBB
        const r = pixel & 0xFF;
        const g = (pixel >> 8) & 0xFF;
        const b = (pixel >> 16) & 0xFF;
        pixel_data[i] = (r << 16) | (g << 8) | b;
    }

    return .{ .data = pixel_data[0..pixels], .w = @intCast(x), .h = @intCast(y) };
}

pub fn load_sprites(storage: *SpriteStorage) void {
    // misc
    storage.images[@intFromEnum(SpriteKey.missing)] = image_from_memory(assets.sprite_missing);
    storage.images[@intFromEnum(SpriteKey.camera)] = image_from_memory(assets.sprite_camera);
    storage.images[@intFromEnum(SpriteKey.splash)] = image_from_memory(assets.sprite_splash);

    // players
    storage.images[@intFromEnum(SpriteKey.genly)] = image_from_memory(assets.sprite_genly);

    // npcs
    storage.images[@intFromEnum(SpriteKey.estraven)] = image_from_memory(assets.sprite_estraven);
    storage.images[@intFromEnum(SpriteKey.argaven)] = image_from_memory(assets.sprite_argaven);

    // editor
    storage.images[@intFromEnum(SpriteKey.cursor)] = image_from_memory(assets.sprite_cursor);
    storage.images[@intFromEnum(SpriteKey.selector)] = image_from_memory(assets.sprite_selector);
    storage.images[@intFromEnum(SpriteKey.selector_active)] = image_from_memory(assets.sprite_selector_active);

    // items
    storage.images[@intFromEnum(SpriteKey.redflag)] = image_from_memory(assets.sprite_redflag);
    storage.images[@intFromEnum(SpriteKey.potion)] = image_from_memory(assets.sprite_potion);

    // action menu
    storage.images[@intFromEnum(SpriteKey.action_menu_melee)] = image_from_memory(assets.sprite_sword);
    storage.images[@intFromEnum(SpriteKey.action_menu_ranged)] = image_from_memory(assets.sprite_wand);
    storage.images[@intFromEnum(SpriteKey.action_menu_magic)] = image_from_memory(assets.sprite_missing);
    storage.images[@intFromEnum(SpriteKey.action_menu_throw)] = image_from_memory(assets.sprite_missing);
    storage.images[@intFromEnum(SpriteKey.action_menu_hide)] = image_from_memory(assets.sprite_missing);
    storage.images[@intFromEnum(SpriteKey.action_menu_dash)] = image_from_memory(assets.sprite_missing);
    storage.images[@intFromEnum(SpriteKey.action_menu_jump)] = image_from_memory(assets.sprite_missing);
    storage.images[@intFromEnum(SpriteKey.action_menu_shove)] = image_from_memory(assets.sprite_missing);
}

pub fn load_level(name: []const u8) Level {
    if (std.mem.eql(u8, name, "one")) {
        return .{
            .name = name,
            .bg = image_from_memory(assets.level_tutorial_bg),
            .fg = image_from_memory(assets.level_tutorial_fg),
        };
    } else if (std.mem.eql(u8, name, "arch")) {
        return .{
            .name = name,
            .bg = image_from_memory(assets.level_parade_bg),
            .fg = image_from_memory(assets.level_parade_fg),
        };
    } else {
        @panic("Unknown level name");
    }
}

pub fn load_level_things(name: []const u8, things: *ThingPool) void {
    if (std.mem.eql(u8, name, "arch")) {
        const bytes = std.mem.asBytes(things);
        @memcpy(bytes, assets.level_parade_things);
    }
    // tutorial has no things.bin, so we leave the pool empty
}
