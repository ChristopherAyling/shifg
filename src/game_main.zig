const std = @import("std");
const assert = std.debug.assert;
const Window = @import("window.zig").Window;
const draw = @import("draw.zig");
const ui = @import("ui.zig");
const Image = @import("image.zig").Image;
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const DialogueState = @import("dialogue.zig").DialogueState;
const DialogueSequence = @import("dialogue.zig").DialogueSequence;
const dialogues = @import("dialogue.zig");
const control = @import("control.zig");
const sprites = @import("sprites.zig");
const StoryCheckpoint = @import("story.zig").StoryCheckpoint;
const con = @import("constants.zig");
const effects = @import("effects.zig");
const Level = @import("level.zig").Level;
const audio = @import("audio.zig");
const ThingPool = @import("things.zig").ThingPool;

const Inputs = control.Inputs;
const updateInputs = control.updateInputs;
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

const LEVELS = std.StaticStringMap([]const u8).initComptime(.{
    .{ "one", "/Users/chris/gaming/gam1/assets/levels/tutorial" },
    .{ "arch", "/Users/chris/gaming/gam1/assets/levels/parade" },
});

const GameState = struct {
    // mode
    mode: GameMode,

    ctx: GameContext,

    // player data
    // player_x: i32,
    // player_y: i32,
    camera_x: i32,
    camera_y: i32,

    audio_system: audio.AudioSystem,

    // entities
    things: ThingPool = .{},

    // stuff
    dialogue: ?DialogueState,
    level: ?Level,

    pub fn setDialogue(self: *GameState, dlog: *const DialogueSequence) void {
        std.log.debug("setting dialogue", .{});
        self.dialogue = DialogueState.init(dlog);
    }

    pub fn clearDialogue(self: *GameState) void {
        std.log.debug("clearing dialogue", .{});
        self.dialogue = null;
    }

    pub fn load_level(self: *GameState, name: []const u8) void {
        const new_level = Level.from_folder(LEVELS.get(name).?, name);
        new_level.load_things(&self.things);
        self.level = new_level;
    }

    pub fn ensure_level_loaded(self: *GameState, name: []const u8) void {
        if (self.level) |current_level| {
            if (!std.mem.eql(u8, current_level.name, name)) {
                self.load_level(name);
            }
        } else {
            // self.level = Level.from_folder(LEVELS.get(name).?, name);
            self.load_level(name);
        }
    }

    pub fn camera_follow_player(self: *GameState) void {
        const player = self.things.get_player();
        self.camera_x = player.x - @divFloor(con.NATIVE_W, 2) + @divFloor(con.PLAYER_W, 2);
        self.camera_y = player.y - @divFloor(con.NATIVE_H, 2) + @divFloor(con.PLAYER_H, 2);

        self.camera_x = @max(self.camera_x, con.NATIVE_W_HALF);
        self.camera_y = @max(self.camera_y, con.NATIVE_H_HALF);

        self.camera_x = @min(self.camera_x, con.LEVEL_W - con.NATIVE_W);
        self.camera_y = @min(self.camera_y, con.LEVEL_H - con.NATIVE_H);
    }

    pub fn init() GameState {
        return .{
            .mode = .MainMenu,
            .audio_system = .{},
            .ctx = .{ .story_checkpoint = .game_start },
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
    storage: sprites.SpriteStorage,
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
        game_state.ensure_level_loaded("arch");
        game_state.camera_follow_player();
    }
}

pub fn game_step_overworld(game_state: *GameState, inputs: Inputs) void {
    const player = game_state.things.get_player();
    game_state.audio_system.setMusic(.overworld);

    switch (game_state.ctx.story_checkpoint) {
        .game_start => {
            if (game_state.dialogue == null) {
                std.log.debug("reinit dia", .{});
                game_state.setDialogue(&dialogues.PROLOGUE);
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
                game_state.clearDialogue();
            }
        }
        return;
    }

    // opening a menu is second highest priority
    if (inputs.start.pressed) {
        game_state.mode = .Inventory;
        return;
    }

    // world interaction
    if (inputs.a.pressed) {
        var it = game_state.things.iter();
        while (it.next_active_near(player.x, player.y, 8)) |thing| {
            _ = thing;
            // TODO: implement dialogue system
        }
    }

    // movement
    if (inputs.directions.contains(.up)) player.y -= 1 * PLAYER_VELOCITY;
    if (inputs.directions.contains(.down)) player.y += 1 * PLAYER_VELOCITY;
    if (inputs.directions.contains(.left)) player.x -= 1 * PLAYER_VELOCITY;
    if (inputs.directions.contains(.right)) player.x += 1 * PLAYER_VELOCITY;
}

pub fn game_step_inventory(game_state: *GameState, inputs: Inputs) void {
    if (inputs.b.pressed) {
        game_state.mode = .Overworld;
    }
}

pub fn game_step_main_menu(game_state: *GameState, inputs: Inputs) void {
    if (inputs.a.pressed) {
        game_state.mode = .Overworld;
        game_state.audio_system.playSound(.click);
    }
}

// rendering

pub fn render_step(game_state: *GameState, render_state: *RenderState) void {
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

pub fn render_step_main_menu(game_state: *const GameState, render_state: *RenderState) void {
    _ = game_state;
    ui.drawSplashText(&render_state.screen, render_state.storage.get(.splash));
}

pub fn render_step_inventory(game_state: *const GameState, render_state: *RenderState) void {
    _ = game_state;
    ui.drawTextBox(&render_state.screen, "", "inventory");
}

pub fn render_step_overworld(game_state: *GameState, render_state: *RenderState) void {
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

        draw.draw_image(&render_state.level, game_state.level.?.bg, 0, 0);

        // load entities
        {
            // every thing
            var it = game_state.things.iter();
            while (it.next_active()) |thing| {
                draw.draw_image(&render_state.level, render_state.storage.get(thing.spritekey), thing.x, thing.y);
            }
        }

        draw.draw_image(&render_state.level, game_state.level.?.fg, 0, 0);

        // add effects
        effects.snow(&render_state.level, 0);

        draw.view(&render_state.level, &render_state.screen, game_state.camera_x, game_state.camera_y);
    }

    // render ui
    {
        // overlay dialogue
        if (game_state.dialogue) |current_dialogue| {
            const line = current_dialogue.getLine();
            ui.drawTextBox(&render_state.screen, line.speaker_name, line.text);
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

    var window = try Window.init(allocator, con.UPSCALED_W, con.UPSCALED_H, "shif");
    defer window.deinit();

    var storage = sprites.SpriteStorage.init();
    storage.load();

    window.before_loop();

    const game_state: *GameState = try allocator.create(GameState);
    game_state.* = GameState.init();
    game_state.audio_system.init();
    defer allocator.destroy(game_state);
    var render_state: RenderState = .{
        .screen = screen,
        .screen_upscaled = screen_upscaled,
        .level = level,
        .storage = storage,
    };

    var inputs = Inputs{};
    while (window.loop()) {
        updateInputs(&inputs, window);
        game_step(game_state, inputs); // TODO pass a dt
        render_step(game_state, &render_state);

        screen.upscale(&screen_upscaled, con.SCALE);
        blit(render_state.screen_upscaled, &window);
    }
}
