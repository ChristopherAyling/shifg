const std = @import("std");
const assert = std.debug.assert;
const Window = @import("window.zig").Window;
const draw = @import("draw.zig");
const ui = @import("ui.zig");
const image = @import("image.zig");
const ScreenBuffer = @import("screen.zig").ScreenBuffer;

const Command = enum {
    up,
    down,
    left,
    right,
    a,
    b,
    start,
};
const Inputs = std.bit_set.IntegerBitSet(@typeInfo(Command).@"enum".fields.len); // 8way dpad + ab + start

const UP = 17;
const DOWN = 18;
const LEFT = 20;
const RIGHT = 19;
const SPACE = 32;
const A = 65;
const B = 66;
const E = 69;

pub fn getInputs(window: Window) Inputs {
    var inputs = Inputs.initEmpty();
    if (window.key(UP)) {
        inputs.set(@intFromEnum(Command.up));
    }
    if (window.key(DOWN)) {
        inputs.set(@intFromEnum(Command.down));
    }
    if (window.key(LEFT)) {
        inputs.set(@intFromEnum(Command.left));
    }
    if (window.key(RIGHT)) {
        inputs.set(@intFromEnum(Command.right));
    }
    if (window.key(SPACE) or window.key(A)) {
        inputs.set(@intFromEnum(Command.a));
    }
    if (window.key(B)) {
        inputs.set(@intFromEnum(Command.b));
    }
    if (window.key(E)) {
        inputs.set(@intFromEnum(Command.start));
    }
    return inputs;
}

const GameMode = enum {
    MainMenu,
    Inventory,
    Overworld,
};

const GameState = struct {
    // mode
    mode: GameMode,

    // player data
    player_x: i32,
    player_y: i32,
};

const RenderState = struct {
    screen: ScreenBuffer,
    screen_upscaled: ScreenBuffer,
    player_sprite: image.Image,
};

const PLAYER_VELOCITY = 1;

// gaming

pub fn game_step(game_state: *GameState, inputs: Inputs) void {
    // player movement
    switch (game_state.mode) {
        GameMode.MainMenu => game_step_main_menu(game_state, inputs),
        GameMode.Overworld => game_step_overworld(game_state, inputs),
        GameMode.Inventory => game_step_inventory(game_state, inputs),
    }
}

pub fn game_step_overworld(game_state: *GameState, inputs: Inputs) void {
    if (inputs.isSet(@intFromEnum(Command.start))) {
        game_state.mode = .Inventory;
        return;
    }
    if (inputs.isSet(@intFromEnum(Command.up))) game_state.player_y -= 1 * PLAYER_VELOCITY;
    if (inputs.isSet(@intFromEnum(Command.down))) game_state.player_y += 1 * PLAYER_VELOCITY;
    if (inputs.isSet(@intFromEnum(Command.left))) game_state.player_x -= 1 * PLAYER_VELOCITY;
    if (inputs.isSet(@intFromEnum(Command.right))) game_state.player_x += 1 * PLAYER_VELOCITY;
}

pub fn game_step_inventory(game_state: *GameState, inputs: Inputs) void {
    if (inputs.isSet(@intFromEnum(Command.b))) {
        game_state.mode = .Overworld;
    }
}

pub fn game_step_main_menu(game_state: *GameState, inputs: Inputs) void {
    if (inputs.isSet(@intFromEnum(Command.a))) {
        game_state.mode = .Overworld;
    }
}

// rendering

pub fn render_step(game_state: GameState, render_state: *RenderState) void {
    // clear screen
    draw.fill(&render_state.screen, 0x0);
    draw.fill(&render_state.screen_upscaled, 0x0);
    // render frame
    switch (game_state.mode) {
        GameMode.MainMenu => render_step_main_menu(game_state, render_state),
        GameMode.Inventory => render_step_inventory(game_state, render_state),
        GameMode.Overworld => render_step_overworld(game_state, render_state),
    }
}

pub fn render_step_main_menu(game_state: GameState, render_state: *RenderState) void {
    _ = game_state;
    ui.drawTextBox(&render_state.screen, "Welcome to Shif. Press Start to play");
}

pub fn render_step_inventory(game_state: GameState, render_state: *RenderState) void {
    _ = game_state;
    ui.drawTextBox(&render_state.screen, "inventory");
}

pub fn render_step_overworld(game_state: GameState, render_state: *RenderState) void {
    draw.fill(&render_state.screen, 0x0);
    draw.draw_image(&render_state.screen, render_state.player_sprite, game_state.player_x, game_state.player_y);
    ui.drawTextBox(&render_state.screen, "hey, you are finally awake");
}

fn blit(screen: ScreenBuffer, window: *Window) void {
    assert(screen.w == window.w);
    assert(screen.h == window.h);
    for (0..screen.data.len) |i| {
        window.f.buf[i] = screen.data[i];
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    const NATIVE_W = 160;
    const NATIVE_H = 144;
    const SCALE = 4;
    const UPSCALED_W = NATIVE_W * SCALE;
    const UPSCALED_H = NATIVE_H * SCALE;

    var screen: ScreenBuffer = try ScreenBuffer.init(allocator, NATIVE_W, NATIVE_H);
    var screen_upscaled: ScreenBuffer = try ScreenBuffer.init(allocator, UPSCALED_W, UPSCALED_H);

    var window = try Window.init(allocator, UPSCALED_W, UPSCALED_H);
    defer window.deinit();

    const filename: [:0]const u8 = "/Users/chris/gaming/gam1/tile2.png";
    const player_sprite = image.load(filename);

    window.before_loop();

    var game_state: GameState = .{
        .mode = .MainMenu,
        .player_x = 50,
        .player_y = 50,
    };
    var render_state: RenderState = .{ .screen = screen, .screen_upscaled = screen_upscaled, .player_sprite = player_sprite };

    while (window.loop()) {
        // const frame_start_t = std.time.nanoTimestamp();

        const command = getInputs(window);
        game_step(&game_state, command); // TODO pass a dt
        render_step(game_state, &render_state);

        screen.upscale(&screen_upscaled, SCALE);
        blit(render_state.screen_upscaled, &window);

        // const frame_end_t = std.time.nanoTimestamp();
        // const frame_elapsed_ns = frame_end_t - frame_start_t;
        // window.sleep(@intCast(frame_elapsed_ns));
    }
}
