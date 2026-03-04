const std = @import("std");
const assert = std.debug.assert;
const con = @import("constants.zig");
const api = @import("editor_api.zig");
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const Window = @import("window.zig").Window;
const sprites = @import("sprites.zig");
const Inputs = @import("control.zig").Inputs;
const audio = @import("audio.zig");
const io_native = @import("io_native.zig");
const updateInputs = @import("fenster_update_inputs.zig").updateInputs;

const EditorLib = struct {
    lib: std.DynLib,
    editor_step: api.EditorStepFn,
    render_step: api.RenderStepFn,
    temp_path: [128:0]u8,
    temp_path_len: usize,

    const source_path = "/Users/chris/gaming/gam1/zig-out/lib/libeditor.dylib";

    fn load() !EditorLib {
        // Copy dylib to temp path to avoid macOS dlopen caching
        var temp_path: [128:0]u8 = undefined;
        const timestamp = std.time.timestamp();
        const temp_path_len = (std.fmt.bufPrint(&temp_path, "/tmp/libeditor_{}.dylib", .{timestamp}) catch unreachable).len;
        temp_path[temp_path_len] = 0;

        std.fs.copyFileAbsolute(source_path, temp_path[0..temp_path_len], .{}) catch |err| {
            std.debug.print("failed to copy dylib: {}\n", .{err});
            return err;
        };

        var lib = try std.DynLib.open(temp_path[0..temp_path_len :0]);
        const editor_step = lib.lookup(api.EditorStepFn, "editor_step") orelse {
            std.debug.print("failed to find editor_step\n", .{});
            return error.SymbolNotFound;
        };
        const render_step = lib.lookup(api.RenderStepFn, "render_step") orelse {
            std.debug.print("failed to find render_step\n", .{});
            return error.SymbolNotFound;
        };
        return .{
            .lib = lib,
            .editor_step = editor_step,
            .render_step = render_step,
            .temp_path = temp_path,
            .temp_path_len = temp_path_len,
        };
    }

    fn unload(self: *EditorLib) void {
        self.lib.close();
        // Delete temp file
        std.fs.deleteFileAbsolute(self.temp_path[0..self.temp_path_len]) catch {};
    }

    fn reload(self: *EditorLib) void {
        self.unload();
        self.* = load() catch |err| {
            std.debug.print("hot reload failed: {}\n", .{err});
            return;
        };
        std.debug.print("hot reloaded\n", .{});
    }
};

// visual
fn blit(screen: ScreenBuffer, window: *Window) void {
    assert(screen.w == window.w);
    assert(screen.h == window.h);
    for (0..screen.data.len) |i| {
        window.f.buf[i] = screen.data[i];
    }
}

// audio

var audio_system: io_native.AudioSystem = .{};
const platform_fns = struct {
    fn playSound(track: audio.SfxTrack) void {
        audio_system.playSound(track);
    }
    fn setMusic(track: audio.MusicTrack) void {
        audio_system.setMusic(track);
    }
    fn stopMusic() void {
        audio_system.stopMusic();
    }
};

// the real deal
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    var screen: ScreenBuffer = try ScreenBuffer.init(allocator, con.NATIVE_W, con.NATIVE_H);
    defer screen.deinit(allocator);
    var screen_upscaled: ScreenBuffer = try ScreenBuffer.init(allocator, con.UPSCALED_W, con.UPSCALED_H);
    defer screen_upscaled.deinit(allocator);
    var level: ScreenBuffer = try ScreenBuffer.init(allocator, con.LEVEL_W, con.LEVEL_H);
    defer level.deinit(allocator);

    var window = try Window.init(allocator, con.UPSCALED_W, con.UPSCALED_H, "editor");
    defer window.deinit(allocator);

    var storage = sprites.SpriteStorage.init();
    io_native.load_sprites(&storage);

    window.before_loop();

    // make platform
    audio_system.init();
    const platform: api.PlatformAPI = .{
        .playSound = platform_fns.playSound,
        .setMusic = platform_fns.setMusic,
        .stopMusic = platform_fns.stopMusic,
        .load_level = io_native.load_level,
        .load_level_things = io_native.load_level_things,
        .save_level_things = io_native.save_level_things,
    };
    var render_context: api.RenderContext = .{
        .screen = &screen,
        .level = &level,
        .storage = &storage,
    };

    var editor_lib = try EditorLib.load();
    defer editor_lib.unload();

    // initialise editor memory
    var editor_state: api.EditorState = .{};
    var editor_memory: api.EditorMemory = .{
        .is_initialized = true,
        .state = &editor_state,
    };

    var inputs = Inputs{};
    const TARGET_FPS = 60;
    const FRAME_TIME_NS: i64 = @divFloor(std.time.ns_per_s, TARGET_FPS);
    var last_frame_time = std.time.nanoTimestamp();

    while (window.loop()) {
        const now = std.time.nanoTimestamp();
        const elapsed = now - last_frame_time;

        if (elapsed >= FRAME_TIME_NS) {
            last_frame_time = now - @mod(elapsed, FRAME_TIME_NS);

            if (window.key(82)) { // R key
                editor_lib.reload();
            }
            updateInputs(&inputs, window);

            editor_lib.editor_step(&editor_memory, &inputs, &platform);
            if (editor_memory.done) break;
            editor_lib.render_step(&editor_memory, &render_context);

            screen.upscale(&screen_upscaled, con.SCALE);
            blit(screen_upscaled, &window);
        } else {
            std.Thread.sleep(1_000_000); // sleep 1ms to avoid busy-waiting
        }
    }
}
