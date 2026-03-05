const std = @import("std");
const Image = @import("image.zig").Image;
const Level = @import("level.zig").Level;
const sprites = @import("sprites.zig");
const SpriteKey = sprites.SpriteKey;
const SpriteStorage = sprites.SpriteStorage;
const ThingPool = @import("things.zig").ThingPool;
const audio = @import("audio.zig");

// images

const stbi = @cImport({
    @cDefine("STB_IMAGE_IMPLEMENTATION", "1");
    @cDefine("STBI_NO_GIF", "1");
    @cDefine("STBI_NO_HDR", "1");
    @cDefine("STBI_NO_TGA", "1");
    @cDefine("STBI_NO_PSD", "1");
    @cDefine("STBI_NO_PIC", "1");
    @cDefine("STBI_NO_PNM", "1");
    @cInclude("stb_image.h");
});

const ImageError = error{LoadError};

fn image_from_file(filename: [:0]const u8) ImageError!Image {
    var x: c_int = undefined;
    var y: c_int = undefined;
    var channels_in_file: c_int = undefined;

    const raw = stbi.stbi_load(filename.ptr, &x, &y, &channels_in_file, 4) orelse {
        std.log.err("Failed to load image: {s}\n", .{filename});
        return ImageError.LoadError;
    };

    const pixels = @as(usize, @intCast(x)) * @as(usize, @intCast(y));
    const data: [*]u32 = @ptrCast(@alignCast(raw));

    for (0..pixels) |i| {
        const pixel = data[i];
        // stb: memory is R,G,B,A -> as u32 little-endian: 0xAABBGGRR
        // we need: 0x00RRGGBB
        const r = pixel & 0xFF;
        const g = (pixel >> 8) & 0xFF;
        const b = (pixel >> 16) & 0xFF;
        data[i] = (r << 16) | (g << 8) | b;
    }

    return .{ .data = data[0..pixels], .w = @intCast(x), .h = @intCast(y) };
}

pub fn load_sprites(self: *SpriteStorage) void {
    const missing_sprite = image_from_file("assets/missing.png") catch unreachable;
    for (std.enums.values(SpriteKey)) |sprite_key| {
        var buf: [256]u8 = undefined;
        const path = std.fmt.bufPrintZ(&buf, "assets/{s}.png", .{@tagName(sprite_key)}) catch unreachable;
        self.images[@intFromEnum(sprite_key)] = image_from_file(path) catch missing_sprite;
    }
}

// level

fn level_from_folder(path: []const u8, name: []const u8) Level {
    var buf: [256]u8 = undefined;

    const bg_path = std.fmt.bufPrintZ(&buf, "{s}/bg.png", .{path}) catch unreachable;
    const bg = image_from_file(bg_path) catch unreachable;

    const fg_path = std.fmt.bufPrintZ(&buf, "{s}/fg.png", .{path}) catch unreachable;
    const fg = image_from_file(fg_path) catch unreachable;

    return .{
        .name = name,
        .bg = bg,
        .fg = fg,
        // .music = undefined,
    };
}

const LEVELS = std.StaticStringMap([]const u8).initComptime(.{
    .{ "one", "/Users/chris/gaming/gam1/assets/levels/tutorial" },
    .{ "arch", "/Users/chris/gaming/gam1/assets/levels/parade" },
});

pub fn load_level(name: []const u8) Level {
    return level_from_folder(LEVELS.get(name).?, name);
}

pub fn load_level_things(name: []const u8, things: *ThingPool) void {
    var buf: [256]u8 = undefined;
    const things_path = std.fmt.bufPrintZ(&buf, "{s}/things.bin", .{LEVELS.get(name).?}) catch unreachable;
    things.from_file(things_path);
}

pub fn save_level_things(name: []const u8, things: *ThingPool) void {
    var buf: [256]u8 = undefined;
    const things_path = std.fmt.bufPrintZ(&buf, "{s}/things.bin", .{LEVELS.get(name).?}) catch unreachable;
    things.to_file(things_path);
}

// audio

const miniaudio = @cImport({
    @cInclude("miniaudio.h");
});

const music_paths = blk: {
    var result = std.EnumArray(audio.MusicTrack, [:0]const u8).initUndefined();
    for (std.enums.values(audio.MusicTrack)) |track| {
        result.set(track, "assets/audio/music/" ++ @tagName(track) ++ ".wav");
    }
    break :blk result;
};

const sfx_paths = blk: {
    var result = std.EnumArray(audio.SfxTrack, [:0]const u8).initUndefined();
    for (std.enums.values(audio.SfxTrack)) |sfx| {
        result.set(sfx, "assets/audio/sfx" ++ @tagName(sfx) ++ ".wav");
    }
    break :blk result;
};

pub const AudioSystem = struct {
    engine: miniaudio.ma_engine = undefined,
    engine_initialized: bool = false,
    current_track: ?audio.MusicTrack = null,
    music: miniaudio.ma_sound = undefined,
    music_initialized: bool = false,

    pub fn init(self: *AudioSystem) void {
        if (miniaudio.ma_engine_init(null, &self.engine) != miniaudio.MA_SUCCESS) @panic("audio engine init failed");
        self.engine_initialized = true;
    }

    pub fn deinit(self: *AudioSystem) void {
        self.stopMusic();
        if (self.engine_initialized) {
            miniaudio.ma_engine_uninit(&self.engine);
            self.engine_initialized = false;
        }
    }

    pub fn setMusic(self: *AudioSystem, track: audio.MusicTrack) void {
        if (track == self.current_track) return;

        self.stopMusic();

        self.current_track = track;

        const music_path = music_paths.get(track);
        if (miniaudio.ma_sound_init_from_file(&self.engine, music_path.ptr, 0, null, null, &self.music) != miniaudio.MA_SUCCESS) {
            @panic("could not init sound from file");
        }
        self.music_initialized = true;
        miniaudio.ma_sound_set_looping(&self.music, 1);
        miniaudio.ma_sound_set_volume(&self.music, 0.4);
        _ = miniaudio.ma_sound_start(&self.music);
    }

    pub fn playSound(self: *AudioSystem, track: audio.SfxTrack) void {
        const sfx_path = sfx_paths.get(track);
        _ = miniaudio.ma_engine_play_sound(&self.engine, sfx_path.ptr, null);
    }

    pub fn stopMusic(self: *AudioSystem) void {
        if (self.music_initialized) {
            _ = miniaudio.ma_sound_stop(&self.music);
            miniaudio.ma_sound_uninit(&self.music);
            self.music_initialized = false;
            self.current_track = null;
        }
    }
};
