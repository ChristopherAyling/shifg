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

pub fn load_sprites(storage: *SpriteStorage) void {
    _ = storage;
}

pub fn load_level(name: []const u8) Level {
    _ = name;
    return undefined;
}

pub fn load_level_things(name: []const u8, things: *ThingPool) void {
    _ = name;
    _ = things;
}
