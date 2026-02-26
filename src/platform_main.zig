const std = @import("std");
const assert = std.debug.assert;
const con = @import("constants.zig");
const api = @import("game_api.zig");
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const Window = @import("window.zig").Window;
const sprites = @import("sprites.zig");
const Inputs = @import("control.zig").Inputs;
const audio = @import("audio.zig");

// pub fn main() !void {
//     std.log.debug("hello from platform main", .{});
// }

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

// dummy

pub fn dummyGameStep(memory: *api.GameMemory, _: Inputs, platform: api.PlatformAPI) void {
    if (!memory.is_initialized) {
        std.log.info("game initialized", .{});
        memory.is_initialized = true;
    }
    _ = platform;
}

pub fn dummyRenderStep(_: *api.GameMemory, ctx: *api.RenderContext) void {
    // ctx.screen.clear();
    ctx.screen.setPixel(20, 20, 0xFFAA9A);
}

// the real deal

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    var screen: ScreenBuffer = try ScreenBuffer.init(allocator, con.NATIVE_W, con.NATIVE_H);
    var screen_upscaled: ScreenBuffer = try ScreenBuffer.init(allocator, con.UPSCALED_W, con.UPSCALED_H);

    var window = try Window.init(allocator, con.UPSCALED_W, con.UPSCALED_H, "game");
    defer window.deinit();

    var storage = sprites.SpriteStorage.init();
    storage.load();

    window.before_loop();

    // const game_state: *GameState = try allocator.create(GameState);
    // game_state.* = GameState.init();
    // game_state.audio_system.init();
    // defer allocator.destroy(game_state);
    // var render_state: RenderState = .{
    //     .screen = screen,
    //     .screen_upscaled = screen_upscaled,
    //     .level = level,
    //     .storage = storage,
    // };

    // make platform
    // var audio_system: audio.AudioSystem = .{};
    audio_system.init();
    const platform: api.PlatformAPI = .{
        .playSound = platform_fns.playSound,
        .setMusic = platform_fns.setMusic,
        .stopMusic = platform_fns.stopMusic,
    };

    var render_context: api.RenderContext = .{
        .screen = &screen,
    };

    // TODO intial dll load

    const game_step: api.GameStepFn = dummyGameStep;
    const render_step: api.RenderStepFn = dummyRenderStep;

    // initialise game memory
    var game_state: api.GameState = .{};
    var game_memory: api.GameMemory = .{
        .is_initialized = true,
        .state = &game_state,
    };

    var inputs = Inputs{};
    while (window.loop()) {
        // TODO maybe reload
        updateInputs(&inputs, window);

        game_step(&game_memory, inputs, platform); // TODO pass a dt
        render_step(&game_memory, &render_context);

        screen.upscale(&screen_upscaled, con.SCALE);
        blit(screen_upscaled, &window);
    }
}
