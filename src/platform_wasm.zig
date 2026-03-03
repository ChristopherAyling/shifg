const std = @import("std");
const game = @import("game.zig");
const api = @import("game_api.zig");
const con = @import("constants.zig");
const sprites = @import("sprites.zig");
const Inputs = @import("control.zig").Inputs;
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const draw = @import("draw.zig");
const io_embedded = @import("io_embedded.zig");
const audio = @import("audio.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const WasmState = struct {
    frame_i: usize = 0,
    // rendering
    screen: ScreenBuffer,
    level: ScreenBuffer,
    storage: sprites.SpriteStorage,
    // platform
    platform: api.PlatformAPI,
    render_context: api.RenderContext,
    game_state: api.GameState,
    game_memory: api.GameMemory,
};

var wasm_state: WasmState = undefined;
var inputs: Inputs = .{};

fn noop_playSound(sfx: audio.SfxTrack) void {
    _ = sfx;
}

fn noop_setMusic(track: audio.MusicTrack) void {
    _ = track;
}

fn noop_stopMusic() void {}

// JS calls this with a bitmask of currently-held keys each frame
export fn set_input_state(bits: u32) void {
    // bit 0: up (W)
    // bit 1: down (S)
    // bit 2: left (A)
    // bit 3: right (D)
    // bit 4: a (H)
    // bit 5: b (J)
    // bit 6: x (K)
    // bit 7: y (L)
    // bit 8: start (E)

    inputs.up.update(bits & 1 != 0);
    inputs.down.update(bits & 2 != 0);
    inputs.left.update(bits & 4 != 0);
    inputs.right.update(bits & 8 != 0);
    inputs.a.update(bits & 16 != 0);
    inputs.b.update(bits & 32 != 0);
    inputs.x.update(bits & 64 != 0);
    inputs.y.update(bits & 128 != 0);
    inputs.start.update(bits & 256 != 0);

    // Update directions EnumSet
    inputs.directions = .{};
    if (inputs.up.is_active()) inputs.directions.insert(.up);
    if (inputs.down.is_active()) inputs.directions.insert(.down);
    if (inputs.left.is_active()) inputs.directions.insert(.left);
    if (inputs.right.is_active()) inputs.directions.insert(.right);
}

export fn game_init() void {
    std.log.debug("init start", .{});
    wasm_state.screen = ScreenBuffer.init(allocator, con.NATIVE_W, con.NATIVE_H) catch unreachable;
    wasm_state.level = ScreenBuffer.init(allocator, con.LEVEL_W, con.LEVEL_H) catch unreachable;
    io_embedded.load_sprites(&wasm_state.storage);

    wasm_state.platform = .{
        .playSound = noop_playSound,
        .setMusic = noop_setMusic,
        .stopMusic = noop_stopMusic,
        .load_level = io_embedded.load_level,
        .load_level_things = io_embedded.load_level_things,
    };

    wasm_state.render_context = .{
        .level = &wasm_state.level,
        .screen = &wasm_state.screen,
        .storage = &wasm_state.storage,
    };

    wasm_state.game_state = .{};

    wasm_state.game_memory = .{
        .is_initialized = true,
        .state = &wasm_state.game_state,
    };

    draw.fill_checkerboard(&wasm_state.screen, 10, 0xFF0000, 0xAAAAAA);

    std.log.debug("init end", .{});
}

export fn game_frame() void {
    game.game_step(&wasm_state.game_memory, &inputs, &wasm_state.platform);
    game.render_step(&wasm_state.game_memory, &wasm_state.render_context);
    wasm_state.frame_i += 1;
}

// for setting up rendering

export fn get_screen_w() usize {
    return con.NATIVE_W;
}

export fn get_screen_h() usize {
    return con.NATIVE_H;
}

export fn get_framebuffer_ptr() [*]u8 {
    return @ptrCast(wasm_state.screen.data.ptr);
}

export fn get_framebuffer_len() usize {
    return wasm_state.screen.data.len;
}

// wasi-libc requires a main function
pub fn main() void {}

// dbg

export fn yo() void {
    std.log.debug("yo", .{});
    std.log.info("yo", .{});
    std.log.warn("yo", .{});
    std.log.err("yo", .{});
}
