const std = @import("std");
const assert = std.debug.assert;
const con = @import("constants.zig");
const api = @import("game_api.zig");
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const Window = @import("window.zig").Window;
const sprites = @import("sprites.zig");
const Inputs = @import("control.zig").Inputs;
const audio = @import("audio.zig");
const io_native = @import("io_native.zig");

const GameLib = struct {
    lib: std.DynLib,
    game_step: api.GameStepFn,
    render_step: api.RenderStepFn,
    temp_path: [128:0]u8,
    temp_path_len: usize,

    const source_path = "/Users/chris/gaming/gam1/zig-out/lib/libgame.dylib";

    fn load() !GameLib {
        // Copy dylib to temp path to avoid macOS dlopen caching
        var temp_path: [128:0]u8 = undefined;
        const timestamp = std.time.timestamp();
        const temp_path_len = (std.fmt.bufPrint(&temp_path, "/tmp/libgame_{}.dylib", .{timestamp}) catch unreachable).len;
        temp_path[temp_path_len] = 0;

        std.fs.copyFileAbsolute(source_path, temp_path[0..temp_path_len], .{}) catch |err| {
            std.debug.print("failed to copy dylib: {}\n", .{err});
            return err;
        };

        var lib = try std.DynLib.open(temp_path[0..temp_path_len :0]);
        const game_step = lib.lookup(api.GameStepFn, "game_step") orelse {
            std.debug.print("failed to find game_step\n", .{});
            return error.SymbolNotFound;
        };
        const render_step = lib.lookup(api.RenderStepFn, "render_step") orelse {
            std.debug.print("failed to find render_step\n", .{});
            return error.SymbolNotFound;
        };
        return .{
            .lib = lib,
            .game_step = game_step,
            .render_step = render_step,
            .temp_path = temp_path,
            .temp_path_len = temp_path_len,
        };
    }

    fn unload(self: *GameLib) void {
        self.lib.close();
        // Delete temp file
        std.fs.deleteFileAbsolute(self.temp_path[0..self.temp_path_len]) catch {};
    }

    fn reload(self: *GameLib) void {
        self.unload();
        self.* = load() catch |err| {
            std.debug.print("hot reload failed: {}\n", .{err});
            return;
        };
        std.debug.print("hot reloaded\n", .{});
    }
};

// inputs
pub fn updateInputs(inputs: *Inputs, window: Window) void {
    const W_KEY = 87;
    const S_KEY = 83;
    const A_KEY = 65;
    const D_KEY = 68;
    const E_KEY = 69;

    const H_KEY = 72;
    const J_KEY = 74;
    const K_KEY = 75;
    const L_KEY = 76;

    // controls
    const UP = W_KEY;
    const DOWN = S_KEY;
    const LEFT = A_KEY;
    const RIGHT = D_KEY;
    const A = H_KEY;
    const B = J_KEY;
    const X = K_KEY;
    const Y = L_KEY;
    const START = E_KEY;

    // handle directions
    inputs.directions = .{};
    if (window.key(UP)) inputs.directions.insert(.up);
    if (window.key(DOWN)) inputs.directions.insert(.down);
    if (window.key(LEFT)) inputs.directions.insert(.left);
    if (window.key(RIGHT)) inputs.directions.insert(.right);

    // handle button presses
    inputs.a.update(window.key(A));
    inputs.b.update(window.key(B));
    inputs.x.update(window.key(X));
    inputs.y.update(window.key(Y));
    inputs.start.update(window.key(START));
    inputs.up.update(window.key(UP));
    inputs.down.update(window.key(DOWN));
    inputs.left.update(window.key(LEFT));
    inputs.right.update(window.key(RIGHT));
}

// visual
fn blit(screen: ScreenBuffer, window: *Window) void {
    assert(screen.w == window.w);
    assert(screen.h == window.h);
    for (0..screen.data.len) |i| {
        window.f.buf[i] = screen.data[i];
    }
}

// audio

var audio_system: audio.AudioSystem = .{};
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

    var window = try Window.init(allocator, con.UPSCALED_W, con.UPSCALED_H, "game");
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
    };
    var render_context: api.RenderContext = .{
        .screen = &screen,
        .level = &level,
        .storage = &storage,
    };

    var game_lib = try GameLib.load();
    defer game_lib.unload();

    // initialise game memory
    var game_state: api.GameState = .{};
    var game_memory: api.GameMemory = .{
        .is_initialized = true,
        .state = &game_state,
    };

    var inputs = Inputs{};
    while (window.loop()) {
        if (window.key(82)) { // R key
            game_lib.reload();
        }
        updateInputs(&inputs, window);

        game_lib.game_step(&game_memory, &inputs, &platform);
        game_lib.render_step(&game_memory, &render_context);

        screen.upscale(&screen_upscaled, con.SCALE);
        blit(screen_upscaled, &window);
    }
}
