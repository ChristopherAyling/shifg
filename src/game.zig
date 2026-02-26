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
const menus = @import("menus.zig");

const Inputs = control.Inputs;
const updateInputs = control.updateInputs;

const GameMode = enum {
    MainMenu,
    Overworld,
};

const GameStyle = enum {
    Realtime,
    TurnBased,
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
    menu: menus.MenuState,

    ctx: GameContext,

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
        const camera = self.things.get(player.camera_ref);
        const selector = self.things.get(player.selector_ref);

        // selector follows too
        selector.x = player.x;
        selector.y = player.y;

        camera.x = player.x; // + @divFloor(con.PLAYER_W, 2);
        camera.y = player.y; // + @divFloor(con.PLAYER_H, 2);

        // this is probably wrong, should probably take LEVEL_W etc into account like with the mins.
        camera.x = @max(camera.x, con.NATIVE_W_HALF);
        camera.y = @max(camera.y, con.NATIVE_H_HALF);

        camera.x = @min(camera.x, con.LEVEL_W - con.NATIVE_W);
        camera.y = @min(camera.y, con.LEVEL_H - con.NATIVE_H);
    }

    pub fn camera_follow_selector(self: *GameState) void {
        const player = self.things.get_player();
        const camera = self.things.get(player.camera_ref);
        const selector = self.things.get(player.selector_ref);

        camera.x = selector.x; // + @divFloor(con.PLAYER_W, 2);
        camera.y = selector.y; // + @divFloor(con.PLAYER_H, 2);

        // this is probably wrong, should probably take LEVEL_W etc into account like with the mins.
        camera.x = @max(camera.x, con.NATIVE_W_HALF);
        camera.y = @max(camera.y, con.NATIVE_H_HALF);

        camera.x = @min(camera.x, con.LEVEL_W - con.NATIVE_W);
        camera.y = @min(camera.y, con.LEVEL_H - con.NATIVE_H);
    }

    pub fn init() GameState {
        return .{
            .mode = .MainMenu,
            .audio_system = .{},
            .ctx = .{ .story_checkpoint = .game_start },
            .dialogue = null,
            .level = null,
            .menu = .{},
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
const selector_VELOCITY = 1;

// gaming

pub fn game_step(game_state: *GameState, inputs: Inputs) void {
    // player movement
    switch (game_state.mode) {
        GameMode.MainMenu => game_step_main_menu(game_state, inputs),
        GameMode.Overworld => game_step_overworld(game_state, inputs),
        // GameMode.Inventory => game_step_inventory(game_state, inputs),
    }

    if (game_state.mode == .Overworld) {
        // TODO lookup story beat -> level name and load the correct level.
        game_state.ensure_level_loaded("arch");
        const player = game_state.things.get_player();
        switch (player.interaction_mode) {
            .NORMAL => {
                game_state.camera_follow_player();
            },
            .SELECT => {
                game_state.camera_follow_selector();
            },
        }
    }
}

pub fn game_step_overworld(game_state: *GameState, inputs: Inputs) void {
    const player = game_state.things.get_player();
    var selector = game_state.things.get(player.selector_ref);
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

    // input in menu is next highest priority
    if (game_state.menu.current()) |current| {
        if (inputs.b.pressed) {
            game_state.menu.pop();
            return;
        } else {
            switch (current.*) {
                .context => |*context_menu| {
                    if (inputs.y.pressed) {
                        game_state.menu.pop();
                        return;
                    }
                    if (inputs.a.pressed) {
                        game_state.menu.pop();
                        switch (context_menu.index) {
                            0 => {
                                switch (context_menu.priority) {
                                    .pick_up => {
                                        assert(!context_menu.context_target_ref.is_nil());
                                        game_state.things.get(context_menu.context_target_ref).visible = false;
                                    },
                                    .talk => {},
                                    .attack => {},
                                    .move_to => {
                                        // todo actually walk rather than teleport
                                        player.x = selector.x;
                                        player.y = selector.y;
                                    },
                                }
                            },
                            1 => {
                                game_state.menu.push(.{ .examine = .{
                                    .examination_target_ref = context_menu.context_target_ref,
                                } });
                            },
                            else => {},
                        }
                        return;
                    }
                    if (inputs.up.pressed) context_menu.dec();
                    if (inputs.down.pressed) context_menu.inc();
                },
                .action => |*action_menu| {
                    // TODO handle a
                    var radial_index: usize = 0;
                    if (inputs.directions.contains(.up)) radial_index = 0;
                    if (inputs.directions.contains(.right)) radial_index = 2;
                    if (inputs.directions.contains(.down)) radial_index = 4;
                    if (inputs.directions.contains(.left)) radial_index = 6;
                    if (inputs.directions.contains(.up) and inputs.directions.contains(.right)) radial_index = 1;
                    if (inputs.directions.contains(.right) and inputs.directions.contains(.down)) radial_index = 3;
                    if (inputs.directions.contains(.down) and inputs.directions.contains(.left)) radial_index = 5;
                    if (inputs.directions.contains(.left) and inputs.directions.contains(.up)) radial_index = 7;
                    if (inputs.directions.contains(.left) and inputs.directions.contains(.down) and inputs.directions.contains(.right)) radial_index = 3; // special case of holding asd in a row
                    action_menu.set(radial_index);
                },
                .examine => {
                    // nothing happens here yet.
                },
                .inventory => {
                    // todo inventory system.
                },
            }
            return; // don't do anything else while menu is open
        }
    }

    // opening a menu is next next highest priority
    if (inputs.start.pressed) {
        // game_state.mode = .Inventory;
        game_state.menu.push(.{ .inventory = .{ .index = 0 } });
        return;
    }

    switch (player.interaction_mode) {
        .NORMAL => {
            if (inputs.a.pressed) {
                {
                    var it = game_state.things.iter_ref();
                    while (it.next_match(.selectable_near(player.x, player.y))) |ref| {
                        const thing = game_state.things.get(ref);
                        game_state.menu.push(.{ .context = .{
                            .context_target_ref = ref,
                            .index = 0,
                            .priority = switch (thing.kind) {
                                .NPC => .talk,
                                .ITEM => .pick_up,
                                else => .move_to,
                            },
                        } });
                    }
                }
            }
            if (inputs.x.pressed) {
                player.interaction_mode = .SELECT;
                return;
            }
            // player movement
            selector.visible = false;
            if (inputs.directions.contains(.up)) player.y -= 1 * PLAYER_VELOCITY;
            if (inputs.directions.contains(.down)) player.y += 1 * PLAYER_VELOCITY;
            if (inputs.directions.contains(.left)) player.x -= 1 * PLAYER_VELOCITY;
            if (inputs.directions.contains(.right)) player.x += 1 * PLAYER_VELOCITY;
        },
        .SELECT => {
            if (inputs.b.pressed or inputs.x.pressed) {
                player.interaction_mode = .NORMAL;
                return;
            }
            selector.visible = true;

            // choose selection
            {
                var it = game_state.things.iter_ref();
                selector.spritekey = .selector;
                selector.selection_target_ref = ThingPool.get_nil_ref();
                while (it.next_match(.selectable_near(selector.x, selector.y))) |ref| {
                    selector.spritekey = .selector_active;
                    selector.selection_target_ref = ref;
                }
            }

            // make sure context menu is set
            if (inputs.y.pressed) {
                const selection = game_state.things.get(selector.selection_target_ref);
                game_state.menu.push(.{
                    .context = .{
                        .context_target_ref = selector.selection_target_ref,
                        .index = 0,
                        .priority = switch (selection.kind) {
                            .NPC => .talk,
                            .ITEM => .pick_up,
                            .UNSET => .move_to, // TODO check if valid move to target
                            else => .move_to,
                        },
                    },
                });
                return;
            }

            if (inputs.a.pressed) { // radial action menu to apply on selector location
                // player.interaction_mode = .ACTION_MENU;
                game_state.menu.push(.{ .action = .{ .index = 0 } });
            }

            // handle selector movement
            if (inputs.directions.contains(.up)) selector.y -= 1 * selector_VELOCITY;
            if (inputs.directions.contains(.down)) selector.y += 1 * selector_VELOCITY;
            if (inputs.directions.contains(.left)) selector.x -= 1 * selector_VELOCITY;
            if (inputs.directions.contains(.right)) selector.x += 1 * selector_VELOCITY;
        },
    }
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
    const player = game_state.things.get_player();
    const selector = game_state.things.get(player.selector_ref);
    const camera = game_state.things.get(player.camera_ref);
    draw.fill_checkerboard(&render_state.level, 8, 0xFF0000, 0x0);
    {
        draw.draw_image(&render_state.level, game_state.level.?.bg, 0, 0);

        if (selector.visible) {
            draw.draw_line(&render_state.level, player.x + con.PLAYER_W_HALF, player.y + con.PLAYER_H_HALF, selector.x + con.PLAYER_W_HALF, selector.y + con.PLAYER_H_HALF, 0xAAAAAA);
        }

        // things
        {
            var it = game_state.things.iter();
            while (it.next_active()) |thing| {
                if (thing.visible) draw.draw_image(&render_state.level, render_state.storage.get(thing.spritekey), thing.x, thing.y);
            }
        }

        // debug entity web
        // {
        //     var itx = game_state.things.iter();
        //     while (itx.next_active()) |thingi| {
        //         var itj = game_state.things.iter();
        //         while (itj.next_active()) |thingj| {
        //             draw.draw_line(&render_state.level, thingi.x, thingi.y, thingj.x, thingj.y, 0xFF0000);
        //         }
        //     }
        // }

        draw.draw_image(&render_state.level, game_state.level.?.fg, 0, 0);

        // add effects
        effects.snow(&render_state.level, 0);

        // render level into screen
        draw.view(&render_state.level, &render_state.screen, camera.x, camera.y);
    }

    // render ui
    {
        // render menus
        for (0..game_state.menu.depth) |depth| {
            const menu = game_state.menu.stack[depth];
            switch (menu) {
                .inventory => {
                    ui.drawTextBox(&render_state.screen, "game", "inventory");
                },
                .context => |context_menu| {
                    var items: ui.ContextMenuItems = .{};
                    items.add(@tagName(context_menu.priority));
                    items.add("examine");
                    ui.draw_context_menu(&render_state.screen, con.NATIVE_W_HALF + con.PLAYER_W, con.NATIVE_H_HALF + con.PLAYER_H, context_menu.index, items);
                },
                .action => |action_menu| {
                    var action_items = ui.RadialMenuItems{};
                    action_items.add("Melee", .action_menu_melee);
                    action_items.add("Ranged", .action_menu_ranged);
                    action_items.add("Magic", .action_menu_magic);
                    action_items.add("Throw", .action_menu_throw);
                    action_items.add("Hide", .action_menu_hide);
                    action_items.add("Dash", .action_menu_dash);
                    action_items.add("Jump", .action_menu_jump);
                    action_items.add("Shove", .action_menu_shove);
                    ui.draw_radial_menu(&render_state.screen, &render_state.storage, con.NATIVE_W_HALF, con.NATIVE_H_HALF, action_menu.index, "actions", action_items);
                },
                .examine => |examine_menu| {
                    const examination_target = game_state.things.get(examine_menu.examination_target_ref);
                    if (examination_target.kind == .UNSET) {
                        ui.drawTextBox(&render_state.screen, "examination", "there appears to be nothing here");
                    } else {
                        var buf: [128]u8 = undefined;
                        const text = std.fmt.bufPrint(&buf, "you examine {s}.", .{examination_target.name}) catch unreachable;
                        ui.drawTextBox(&render_state.screen, "examination", text);
                    }
                },
            }
        }

        // overlay dialogue
        if (game_state.dialogue) |current_dialogue| {
            const line = current_dialogue.getLine();
            ui.drawTextBox(&render_state.screen, line.speaker_name, line.text);
        }
    }
}

// pub fn main() !void {
//     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//     const allocator = gpa.allocator();
//     defer {
//         _ = gpa.deinit();
//     }

//     const level: ScreenBuffer = try ScreenBuffer.init(allocator, con.LEVEL_W, con.LEVEL_H);
//     var screen: ScreenBuffer = try ScreenBuffer.init(allocator, con.NATIVE_W, con.NATIVE_H);
//     var screen_upscaled: ScreenBuffer = try ScreenBuffer.init(allocator, con.UPSCALED_W, con.UPSCALED_H);

//     var window = try Window.init(allocator, con.UPSCALED_W, con.UPSCALED_H, "shif");
//     defer window.deinit();

//     var storage = sprites.SpriteStorage.init();
//     storage.load();

//     window.before_loop();

//     const game_state: *GameState = try allocator.create(GameState);
//     game_state.* = GameState.init();
//     game_state.audio_system.init();
//     defer allocator.destroy(game_state);
//     var render_state: RenderState = .{
//         .screen = screen,
//         .screen_upscaled = screen_upscaled,
//         .level = level,
//         .storage = storage,
//     };

//     var inputs = Inputs{};
//     while (window.loop()) {
//         updateInputs(&inputs, window);
//         game_step(game_state, inputs); // TODO pass a dt
//         render_step(game_state, &render_state);

//         screen.upscale(&screen_upscaled, con.SCALE);
//         blit(render_state.screen_upscaled, &window);
//     }
// }
