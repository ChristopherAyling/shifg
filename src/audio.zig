const std = @import("std");

const c = @cImport({
    @cDefine("MINIAUDIO_IMPLEMENTATION", "1");
    @cDefine("MA_IMPLEMENTATION", "1");
    @cDefine("MA_NO_RUNTIME_LINKING", "1");

    @cInclude("miniaudio.h");
});

pub const MusicTrack = enum {
    splash,
    overworld,
};

const music_paths = std.EnumArray(MusicTrack, [:0]const u8).init(.{
    .splash = "assets/audio/music/splash.ogg",
    .overworld = "assets/audio/music/splash.ogg",
});

pub const AudioSystem = struct {
    engine: c.ma_engine,
    current_track: ?MusicTrack = null,
    music: ?c.ma_sound = null,

    pub fn init() AudioSystem {
        var engine: c.ma_engine = undefined;
        if (c.ma_engine_init(null, &engine) != c.MA_SUCCESS) @panic("audio engine init failed");

        return .{
            .engine = engine,
        };
    }

    pub fn setMusic(self: *AudioSystem, track: MusicTrack) void {
        if (track == self.current_track) return;

        self.stopMusic();

        self.current_track = track;

        const music_path = music_paths.get(track);
        var new_music: c.ma_sound = undefined;
        if (c.ma_sound_init_from_file(&self.engine, music_path.ptr, 0, null, null, &new_music)) @panic("audio file init failed");
        c.ma_sound_set_looping(&new_music, 1);
        c.ma_sound_set_volume(&new_music, 0.4);
        _ = c.ma_sound_start(&new_music);
        self.music = new_music;
    }

    pub fn stopMusic(self: *AudioSystem) void {
        if (self.music) |*m| {
            _ = c.ma_sound_stop(m);
            c.ma_sound_uninit(m);
            self.music = null;
            self.current_track = null;
        }
    }
};
