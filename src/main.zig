const std = @import("std");
const assert = std.debug.assert;
const Window = @import("window.zig").Window;
const draw = @import("draw.zig");
const ui = @import("ui.zig");
const Image = @import("image.zig").Image;
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const dialogue = @import("dialogue.zig");
const control = @import("control.zig");
const sprites = @import("sprites.zig");
const StoryCheckpoint = @import("story.zig").StoryCheckpoint;
const con = @import("constants.zig");
const Level = @import("level.zig").Level;

pub const Inputs = control.Inputs;
pub const updateInputs = control.updateInputs;
// pub const Command = control.Command;

const GameMode = enum {
    MainMenu,
    Inventory,
    Overworld,
};

const GameContext = struct {
    // keep data types simple and serialisable.
    story_checkpoint: StoryCheckpoint,
};

const GameDialogueState = struct {
    dialogue_index: usize,
    dialogue: *const dialogue.DialogueSequence,

    pub fn init(seq: *const dialogue.DialogueSequence) GameDialogueState {
        return .{
            .dialogue_index = 0,
            .dialogue = seq,
        };
    }

    pub fn getLine(self: GameDialogueState) dialogue.DialogueLine {
        return self.dialogue.lines[self.dialogue_index];
    }

    pub fn advance(self: *GameDialogueState) void {
        self.dialogue_index += 1;
        std.log.debug("dialogue index = {any}", .{self.dialogue_index});
    }

    pub fn is_complete(self: GameDialogueState) bool {
        return self.dialogue_index >= self.dialogue.lines.len;
    }
};

const LEVELS = std.StaticStringMap([]const u8).initComptime(.{
    .{ "one", "/Users/chris/gaming/gam1/assets/levels/tutorial" },
});

const GameState = struct {
    // mode
    mode: GameMode,

    ctx: GameContext,

    // player data
    player_x: i32,
    player_y: i32,
    camera_x: i32,
    camera_y: i32,

    dialogue: ?GameDialogueState,
    level: ?Level,

    pub fn ensure_level_loaded(self: *GameState, name: []const u8) void {
        if (self.level) |current_level| {
            if (!std.mem.eql(u8, current_level.name, name)) {
                self.level = Level.from_folder(LEVELS.get(name).?, name);
            }
        } else {
            self.level = Level.from_folder(LEVELS.get(name).?, name);
        }
    }

    pub fn camera_follow_player(self: *GameState) void {
        self.camera_x = self.player_x - @divFloor(con.NATIVE_W, 2) + @divFloor(sprites.PLAYER_SPRITE.w, 2);
        self.camera_y = self.player_y - @divFloor(con.NATIVE_H, 2) + @divFloor(sprites.PLAYER_SPRITE.h, 2);
    }

    pub fn init() GameState {
        return .{
            .mode = .MainMenu,
            .ctx = .{ .story_checkpoint = .game_start },
            .player_x = 0,
            .player_y = 0,
            .camera_x = 0,
            .camera_y = 0,
            .dialogue = null,
            .level = null,
        };
    }
};

const RenderState = struct {
    screen: ScreenBuffer,
    screen_upscaled: ScreenBuffer,
    level: ScreenBuffer,
    player_sprite: Image,
    splash_sprite: Image,
    // level1_sprite: Image,
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

    if (game_state.mode == .Overworld) {
        // TODO lookup story beat -> level name and load the correct level.
        game_state.ensure_level_loaded("one");
    }

    game_state.camera_follow_player();
}

pub fn game_step_overworld(game_state: *GameState, inputs: Inputs) void {
    switch (game_state.ctx.story_checkpoint) {
        .game_start => {
            if (game_state.dialogue == null) {
                std.log.debug("reinit dia", .{});
                game_state.dialogue = GameDialogueState.init(&dialogue.PROLOGUE);
            }
        },
        .prologue_complete => {},
        .tutorial_complete => {},
    }

    // dialogue overrules everything
    if (game_state.dialogue) |*current_dialogue| {
        if (inputs.a.pressed) {
            current_dialogue.advance();
            // how to trigger story events from dialogue being completeded.
            // not all dialogue completions will update story events e.g. reading a sign.
            if (current_dialogue.is_complete()) {
                if (current_dialogue.dialogue.jump_to_story_checkpoint) |next_check_point| {
                    game_state.ctx.story_checkpoint = next_check_point;
                }
                game_state.dialogue = null;
            }
        }
        return;
    }

    // opening a menu is second highest priority
    if (inputs.start.pressed) {
        game_state.mode = .Inventory;
        return;
    }
    if (inputs.directions.contains(.up)) game_state.player_y -= 1 * PLAYER_VELOCITY;
    if (inputs.directions.contains(.down)) game_state.player_y += 1 * PLAYER_VELOCITY;
    if (inputs.directions.contains(.left)) game_state.player_x -= 1 * PLAYER_VELOCITY;
    if (inputs.directions.contains(.right)) game_state.player_x += 1 * PLAYER_VELOCITY;
}

pub fn game_step_inventory(game_state: *GameState, inputs: Inputs) void {
    if (inputs.b.pressed) {
        game_state.mode = .Overworld;
    }
}

pub fn game_step_main_menu(game_state: *GameState, inputs: Inputs) void {
    if (inputs.a.pressed) {
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
    ui.drawSplashText(&render_state.screen, render_state.splash_sprite);
}

pub fn render_step_inventory(game_state: GameState, render_state: *RenderState) void {
    _ = game_state;
    ui.drawTextBox(&render_state.screen, "inventory");
}

pub fn render_step_overworld(game_state: GameState, render_state: *RenderState) void {
    // render world
    {
        // load tiles for needed map
        switch (game_state.ctx.story_checkpoint) {
            .game_start => {
                // draw.fill(&render_state.level, 0xFF0000);
                draw.fill_checkerboard(&render_state.level, 8, 0xFF0000, 0x0);
            },
            .prologue_complete => {
                draw.fill_checkerboard(&render_state.level, 8, 0x00FF00, 0x0);
                // draw.draw_image(&render_state.level, render_state.level1_sprite, 0, 0);
            },
            .tutorial_complete => {
                draw.fill_checkerboard(&render_state.level, 8, 0x0000FF, 0x0);
            },
        }

        draw.draw_image(&render_state.level, game_state.level.?.sprite, 0, 0);

        // load entities
        draw.draw_image(&render_state.level, render_state.player_sprite, game_state.player_x, game_state.player_y);

        draw.view(&render_state.level, &render_state.screen, game_state.camera_x, game_state.camera_y);
    }

    // render ui
    {
        // overlay dialogue
        if (game_state.dialogue) |current_dialogue| {
            ui.drawTextBox(&render_state.screen, current_dialogue.getLine().text);
        }
    }
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

    const level: ScreenBuffer = try ScreenBuffer.init(allocator, con.LEVEL_W, con.LEVEL_H);
    var screen: ScreenBuffer = try ScreenBuffer.init(allocator, con.NATIVE_W, con.NATIVE_H);
    var screen_upscaled: ScreenBuffer = try ScreenBuffer.init(allocator, con.UPSCALED_W, con.UPSCALED_H);

    var window = try Window.init(allocator, con.UPSCALED_W, con.UPSCALED_H);
    defer window.deinit();

    const player_sprite = Image.from_file("/Users/chris/gaming/gam1/assets/person2.png");
    const splash_sprite = Image.from_file("/Users/chris/gaming/gam1/assets/splash.png");
    // const level1_sprite = Image.from_file("/Users/chris/gaming/gam1/assets/level1.png");

    window.before_loop();

    var game_state: GameState = GameState.init();
    var render_state: RenderState = .{
        .screen = screen,
        .screen_upscaled = screen_upscaled,
        .level = level,
        .player_sprite = player_sprite,
        .splash_sprite = splash_sprite,
    };

    var inputs = Inputs{};
    while (window.loop()) {
        // const frame_start_t = std.time.nanoTimestamp();

        updateInputs(&inputs, window);
        game_step(&game_state, inputs); // TODO pass a dt
        render_step(game_state, &render_state);

        screen.upscale(&screen_upscaled, con.SCALE);
        blit(render_state.screen_upscaled, &window);

        // const frame_end_t = std.time.nanoTimestamp();
        // const frame_elapsed_ns = frame_end_t - frame_start_t;
        // window.sleep(@intCast(frame_elapsed_ns));
    }
}
