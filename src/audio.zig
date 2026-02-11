const std = @import("std");

const c = @cImport({
    @cInclude("miniaudio.h");
});

pub const MusicTrack = enum {
    splash,
    overworld,
};

pub const SfxTrack = enum {
    click,
    close,
};

const music_paths = std.EnumArray(MusicTrack, [:0]const u8).init(.{
    .splash = "assets/audio/music/missing.wav",
    .overworld = "assets/audio/music/overworld.wav",
});

const sfx_paths = std.EnumArray(SfxTrack, [:0]const u8).init(.{
    .click = "assets/audio/sfx/click.wav",
    .close = "assets/audio/sfx/close.wav",
});

pub const AudioSystem = struct {
    engine: c.ma_engine = undefined,
    engine_initialized: bool = false,
    current_track: ?MusicTrack = null,
    music: c.ma_sound = undefined,
    music_initialized: bool = false,

    /// Call this after the AudioSystem has been placed at its final memory location (e.g. on the heap).
    /// Do NOT call this on a stack-local AudioSystem — ma_engine is too large for the stack.
    pub fn init(self: *AudioSystem) void {
        if (c.ma_engine_init(null, &self.engine) != c.MA_SUCCESS) @panic("audio engine init failed");
        self.engine_initialized = true;
    }

    pub fn setMusic(self: *AudioSystem, track: MusicTrack) void {
        if (track == self.current_track) return;

        self.stopMusic();

        self.current_track = track;

        const music_path = music_paths.get(track);
        if (c.ma_sound_init_from_file(&self.engine, music_path.ptr, 0, null, null, &self.music) != c.MA_SUCCESS) {
            @panic("could not init sound from file");
        }
        self.music_initialized = true;
        c.ma_sound_set_looping(&self.music, 1);
        c.ma_sound_set_volume(&self.music, 0.4);
        _ = c.ma_sound_start(&self.music);
    }

    pub fn playSound(self: *AudioSystem, track: SfxTrack) void {
        const sfx_path = sfx_paths.get(track);
        _ = c.ma_engine_play_sound(&self.engine, sfx_path.ptr, null);
    }

    pub fn stopMusic(self: *AudioSystem) void {
        if (self.music_initialized) {
            _ = c.ma_sound_stop(&self.music);
            c.ma_sound_uninit(&self.music);
            self.music_initialized = false;
            self.current_track = null;
        }
    }
};
