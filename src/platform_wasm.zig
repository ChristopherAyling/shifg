const std = @import("std");
const game = @import("game.zig");
const api = @import("game_api.zig");
const con = @import("constants.zig");
const sprites = @import("sprites.zig");
const Inputs = @import("control.zig").Inputs;
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const draw = @import("draw.zig");

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

export fn game_init() void {
    std.log.debug("init start", .{});
    wasm_state.screen = ScreenBuffer.init(allocator, con.NATIVE_W, con.NATIVE_H) catch unreachable;
    wasm_state.level = ScreenBuffer.init(allocator, con.LEVEL_W, con.LEVEL_H) catch unreachable;
    std.log.debug("init end", .{});

    // wasm_state.storage.load();
    wasm_state.platform = .{
        .playSound = undefined,
        .setMusic = undefined,
        .stopMusic = undefined,
        .load_level = undefined,
    };

    wasm_state.render_context = .{
        .level = &wasm_state.level,
        .screen = &wasm_state.screen,
        .storage = undefined,
    };

    wasm_state.game_state = .{};

    wasm_state.game_memory = .{
        .is_initialized = true,
        .state = &wasm_state.game_state,
    };

    draw.fill_checkerboard(&wasm_state.screen, 10, 0xFF0000, 0xAAAAAA);
}

export fn game_frame() void {
    std.log.debug("frame {any} start", .{wasm_state.frame_i});
    // game.game_step(memory: *GameMemory, inputs: *const Inputs, platform_api: *const PlatformAPI)
    game.render_step(&wasm_state.game_memory, &wasm_state.render_context);
    std.log.debug("frame {any} end", .{wasm_state.frame_i});
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

// dbg

export fn yo() void {
    std.log.debug("yo", .{});
    std.log.info("yo", .{});
    std.log.warn("yo", .{});
    std.log.err("yo", .{});
}
