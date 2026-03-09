const std = @import("std");
const assert = std.debug.assert;
const api = @import("game_api.zig");
const draw = @import("draw.zig");
const ui = @import("ui.zig");
const Image = @import("image.zig").Image;
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const dlogs = @import("dialogue.zig").dialog_lookup;
const control = @import("control.zig");
const sprites = @import("sprites.zig");
const StoryCheckpoint = @import("story.zig").StoryCheckpoint;
const con = @import("constants.zig");
const effects = @import("effects.zig");
const Level = @import("level.zig").Level;
const ThingPool = @import("things.zig").ThingPool;
const Thing = @import("things.zig").Thing;
const menus = @import("menus.zig");
const render_shared = @import("render_shared.zig");
const npc_dlogs = @import("npcs.zig").npc_dialog_lookup;

const Inputs = control.Inputs;

pub fn load_level(self: *api.GameState, name: []const u8, platform_api: *const api.PlatformAPI) void {
    const new_level = platform_api.load_level(name);
    platform_api.load_level_things(name, &self.things);
    self.level = new_level;
    if (std.mem.eql(u8, name, "arch")) {
        self.menu.push(.{ .dialogue = .{ .index = 0, .sequence = dlogs.get(.Prologue) } });
    }
}

pub fn ensure_level_loaded(game_state: *api.GameState, name: []const u8, platform_api: *const api.PlatformAPI) void {
    if (game_state.level) |current_level| {
        if (!std.mem.eql(u8, current_level.name, name)) {
            load_level(game_state, name, platform_api);
        }
    } else {
        load_level(game_state, name, platform_api);
    }
}

pub fn clamp_camera(camera: *Thing) void {
    // don't go off top or left
    camera.x = @max(camera.x, con.NATIVE_W_HALF);
    camera.y = @max(camera.y, con.NATIVE_H_HALF);

    // don't go off the bottom or right
    camera.x = @min(camera.x, con.LEVEL_W - con.NATIVE_W_HALF);
    camera.y = @min(camera.y, con.LEVEL_H - con.NATIVE_H_HALF);
}

pub fn camera_follow_player(self: *api.GameState) void {
    const player = self.things.get_player();
    const camera = self.things.get(player.camera_ref);
    const selector = self.things.get(player.selector_ref);

    // selector follows too TODO move this to player movement spot, camera shouldn't care
    selector.x = player.x;
    selector.y = player.y;

    camera.x = player.x;
    camera.y = player.y;

    clamp_camera(camera);
}

pub fn camera_follow_selector(self: *api.GameState) void {
    const player = self.things.get_player();
    const camera = self.things.get(player.camera_ref);
    const selector = self.things.get(player.selector_ref);

    camera.x = selector.x; // + @divFloor(con.PLAYER_W, 2);
    camera.y = selector.y; // + @divFloor(con.PLAYER_H, 2);

    clamp_camera(camera);
}

const RenderState = struct {
    screen: ScreenBuffer,
    level: ScreenBuffer,
    storage: sprites.SpriteStorage,
};

const PLAYER_VELOCITY = 1;
const selector_VELOCITY = 1;

// gaming

pub fn game_step(memory: *api.GameMemory, inputs: *const Inputs, platform_api: *const api.PlatformAPI) callconv(.c) void {
    var game_state = memory.state;
    switch (game_state.mode) {
        .MainMenu => game_step_main_menu(game_state, inputs.*, platform_api.*),
        .Overworld => game_step_overworld(game_state, inputs.*, platform_api.*),
    }

    if (game_state.mode == .Overworld) {
        // TODO lookup story beat -> level name and load the correct level.
        ensure_level_loaded(game_state, "library_gate", platform_api);
        const player = game_state.things.get_player();
        switch (player.interaction_mode) {
            .NORMAL => {
                camera_follow_player(game_state);
            },
            .SELECT => {
                camera_follow_selector(game_state);
            },
        }
    }
}

fn game_step_overworld(game_state: *api.GameState, inputs: Inputs, platform_api: api.PlatformAPI) void {
    const player = game_state.things.get_player();
    var selector = game_state.things.get(player.selector_ref);
    platform_api.setMusic(.overworld);

    // input in menu is next highest priority
    if (game_state.menu.current()) |current| {
        // if (inputs.b.pressed) { // todo disable this if is a dialogue. you can't b out of a dialogue! i think
        //     game_state.menu.pop();
        //     return;
        if (inputs.b.pressed) {
            switch (current.*) {
                // uncancellable states
                .dialogue,
                .editor_portal_dest_select,
                .editor_level_select,
                => {},
                // all others are cancellable
                else => {
                    game_state.menu.pop();
                },
            }
            return;
        } else {
            switch (current.*) {
                .dialogue => |*dialogue_menu| {
                    if (inputs.a.pressed) {
                        dialogue_menu.advance();
                    }
                    if (dialogue_menu.is_complete()) {
                        game_state.menu.pop();
                    }
                },
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
                                    .talk => {
                                        const npc = game_state.things.get(context_menu.context_target_ref);

                                        game_state.menu.push(.{ .dialogue = .{
                                            .index = 0,
                                            .sequence = dlogs.get(npc_dlogs.get(npc.npc_key)),
                                        } });
                                        return;
                                    },
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
                    if (inputs.start.pressed) {
                        game_state.menu.pop();
                        return;
                    }
                },
                // editor only
                .editor_level_select => unreachable,
                .editor_place => unreachable,
                .editor_options => unreachable,
                .editor_portal_dest_select => unreachable,
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
                        if (thing.kind == .PLAYER) continue;
                        game_state.menu.push(.{ .context = .{
                            .context_target_ref = ref,
                            .index = 0,
                            .priority = switch (thing.kind) {
                                .NPC => .talk,
                                .ITEM => .pick_up,
                                else => .move_to,
                            },
                        } });
                        return;
                    }
                }
            }
            if (inputs.x.pressed) {
                player.interaction_mode = .SELECT;
                return;
            }
            // passive collisions
            {
                // check portals
                // player.euclid_dist(k, y: i32)
                var it = game_state.things.iter();
                // const q: Que
                if (it.next_match(.{
                    .active = true,
                    .kind = .PORTAL,
                    .position = .{ .x = player.x, .y = player.y, .thresh = 8 },
                })) |portal| {
                    player.x = portal.portal_dest.x;
                    player.y = portal.portal_dest.y;
                    platform_api.playSound(.door);
                }
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
                const items: [8]?menus.Item = .{
                    .{ .label = menus.Label.init("hide"), .icon = .missing },
                    .{ .label = menus.Label.init("dash"), .icon = .missing },
                    .{ .label = menus.Label.init("jump"), .icon = .missing },
                    .{ .label = menus.Label.init("throw"), .icon = .missing },
                    .{ .label = menus.Label.init("investgate"), .icon = .missing },
                    null,
                    null,
                    null,
                };
                game_state.menu.push(.{ .action = .{ .index = 0, .items = items } });
            }

            // handle selector movement
            if (inputs.directions.contains(.up)) selector.y -= 1 * selector_VELOCITY;
            if (inputs.directions.contains(.down)) selector.y += 1 * selector_VELOCITY;
            if (inputs.directions.contains(.left)) selector.x -= 1 * selector_VELOCITY;
            if (inputs.directions.contains(.right)) selector.x += 1 * selector_VELOCITY;
        },
    }
}

fn game_step_main_menu(game_state: *api.GameState, inputs: Inputs, platform_api: api.PlatformAPI) void {
    if (inputs.a.pressed) {
        game_state.mode = .Overworld;
        platform_api.playSound(.click);
    }
}

// rendering

pub fn render_step(memory: *api.GameMemory, ctx: *api.RenderContext) callconv(.c) void {
    const game_state = memory.state;
    var render_state: RenderState = .{ .level = ctx.level.*, .screen = ctx.screen.*, .storage = ctx.storage.* };
    draw.fill(&render_state.screen, 0x0);
    switch (game_state.mode) {
        .MainMenu => render_step_main_menu(game_state, &render_state),
        .Overworld => render_step_overworld(game_state, &render_state),
    }
}

fn render_step_main_menu(game_state: *const api.GameState, render_state: *RenderState) void {
    _ = game_state;
    ui.drawSplashText(&render_state.screen, render_state.storage.get(.splash));
}

fn render_step_inventory(game_state: *const api.GameState, render_state: *RenderState) void {
    _ = game_state;
    ui.drawTextBox(&render_state.screen, "", "inventory");
}

fn render_step_overworld(game_state: *api.GameState, render_state: *RenderState) void {
    const player = game_state.things.get_player();
    const selector = game_state.things.get(player.selector_ref);
    const camera = game_state.things.get(player.camera_ref);
    // render world
    {
        draw.draw_image(&render_state.level, game_state.level.?.bg, 0, 0);

        if (selector.visible) {
            draw.draw_line(&render_state.level, player.x + con.PLAYER_W_HALF, player.y + con.PLAYER_H_HALF, selector.x + con.PLAYER_W_HALF, selector.y + con.PLAYER_H_HALF, 0xAAAAAA);
        }

        render_shared.render_things(&render_state.level, &render_state.storage, &game_state.things, false);

        draw.draw_image(&render_state.level, game_state.level.?.fg, 0, 0);

        // add effects
        // effects.snow(&render_state.level, 0);

        // render level into screen
        draw.view(&render_state.level, &render_state.screen, camera.x, camera.y);
    }

    // render ui
    render_shared.render_menu(&render_state.screen, &render_state.storage, &game_state.things, &game_state.menu);
}

comptime {
    @export(&game_step, .{ .name = "game_step" });
    @export(&render_step, .{ .name = "render_step" });
}
