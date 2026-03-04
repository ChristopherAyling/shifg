const std = @import("std");
const assert = std.debug.assert;
const api = @import("editor_api.zig");
const draw = @import("draw.zig");
const ui = @import("ui.zig");
const Image = @import("image.zig").Image;
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const dialogues = @import("dialogue.zig");
const control = @import("control.zig");
const sprites = @import("sprites.zig");
const StoryCheckpoint = @import("story.zig").StoryCheckpoint;
const con = @import("constants.zig");
const effects = @import("effects.zig");
const Level = @import("level.zig").Level;
const ThingPool = @import("things.zig").ThingPool;
const Kind = @import("things.zig").Kind;
const menus = @import("menus.zig");
const Inputs = control.Inputs;
const render_shared = @import("render_shared.zig");

const PlacementEntry = struct { label: []const u8, icon: sprites.SpriteKey };
const PLACEMENT_MENU_DATA = [_][]const PlacementEntry{
    // npcs
    &.{
        .{ .label = "Argaven", .icon = .argaven },
        .{ .label = "Estraven", .icon = .estraven },
    },
    // items
    &.{
        .{ .label = "potion", .icon = .potion },
        .{ .label = "flag", .icon = .redflag },
    },
    // player
    &.{
        .{ .label = "player", .icon = .genly },
    },
};

fn make_placement_menu() menus.NamedItemListCollection {
    var npcs = menus.NamedItemList.init("npc");
    for (PLACEMENT_MENU_DATA[0]) |entry| {
        npcs.add(entry.label, entry.icon);
    }

    var items = menus.NamedItemList.init("items");
    for (PLACEMENT_MENU_DATA[1]) |entry| {
        items.add(entry.label, entry.icon);
    }

    var player = menus.NamedItemList.init("player");
    for (PLACEMENT_MENU_DATA[2]) |entry| {
        player.add(entry.label, entry.icon);
    }

    var placement_menu = menus.NamedItemListCollection.init();
    placement_menu.add(npcs);
    placement_menu.add(items);
    placement_menu.add(player);

    return placement_menu;
}
const PLACEMENT_MENU = make_placement_menu();

fn place(things: *ThingPool, x: i32, y: i32, category: usize, index: usize) void {
    const entry = PLACEMENT_MENU_DATA[category][index];
    switch (category) {
        0 => {
            _ = things.add_npc(entry.icon, x, y);
        },
        1 => {
            _ = things.add_item(entry.icon, x, y);
        },
        2 => {
            _ = things.add_player(entry.icon, x, y);
        },
        else => unreachable,
    }
}

const LEVEL_SELECT_DATA = [_][]const u8{
    "one",
    "arch",
};

fn make_level_select_menu() menus.NamedItemList {
    var levels = menus.NamedItemList.init("levels");
    for (LEVEL_SELECT_DATA) |name| {
        levels.add(name, .missing);
    }
    return levels;
}

const LEVEL_SELECT_MENU = make_level_select_menu();

const CURSOR_VELOCITY = 1;

pub fn editor_step(memory: *api.EditorMemory, inputs: *const Inputs, platform_api: *const api.PlatformAPI) callconv(.c) void {
    const editor_state = memory.state;

    // handle menu inputs
    if (editor_state.menu.current()) |current| {
        if (inputs.b.pressed) { // todo disable this if is a dialogue. you can't b out of a dialogue! i think
            editor_state.menu.pop();
            return;
        } else {
            switch (current.*) {
                .dialogue => |*dialogue_menu| {
                    if (inputs.a.pressed) {
                        dialogue_menu.advance();
                    }
                    if (dialogue_menu.is_complete()) {
                        editor_state.menu.pop();
                    }
                    return;
                },
                .editor_place => |*editor_place_menu| {
                    if (inputs.a.pressed) {
                        place(&editor_state.things, editor_state.cursor_x, editor_state.cursor_y, editor_place_menu.category, editor_place_menu.index);
                        editor_state.menu.pop();
                        return;
                    }
                    if (inputs.left.pressed) {
                        editor_place_menu.prev_category();
                        return;
                    }
                    if (inputs.right.pressed) {
                        editor_place_menu.next_category();
                        return;
                    }
                    if (inputs.up.pressed) {
                        editor_place_menu.dec();
                        return;
                    }
                    if (inputs.down.pressed) {
                        editor_place_menu.inc();
                        return;
                    }
                    return;
                },
                .editor_level_select => |*editor_level_select_menu| {
                    if (inputs.a.pressed) {
                        const name = LEVEL_SELECT_DATA[editor_level_select_menu.index];
                        editor_state.level = platform_api.load_level(name);
                        platform_api.load_level_things(name, &editor_state.things);
                        editor_state.cursor_x = con.LEVEL_W_HALF;
                        editor_state.cursor_y = con.LEVEL_H_HALF;
                        editor_state.menu.pop();
                        return;
                    }
                    if (inputs.up.pressed) {
                        editor_level_select_menu.dec();
                        return;
                    }
                    if (inputs.down.pressed) {
                        editor_level_select_menu.inc();
                        return;
                    }
                },
                else => {},
            }
        }
        return;
    }

    if (editor_state.level == null) {
        // add level select screen
        editor_state.menu.push(.{ .editor_level_select = menus.EditorLevelSelectMenuState.init(LEVEL_SELECT_MENU) });
    }

    if (inputs.a.pressed) {
        // open placement menu
        editor_state.menu.push(.{ .editor_place = menus.EditorPlaceMenuState.init(PLACEMENT_MENU) });
        return;
    }

    // TODO open settings menu (save etc)

    // cursor movement
    if (inputs.directions.contains(.up)) editor_state.cursor_y -= 1 * CURSOR_VELOCITY;
    if (inputs.directions.contains(.down)) editor_state.cursor_y += 1 * CURSOR_VELOCITY;
    if (inputs.directions.contains(.left)) editor_state.cursor_x -= 1 * CURSOR_VELOCITY;
    if (inputs.directions.contains(.right)) editor_state.cursor_x += 1 * CURSOR_VELOCITY;

    // camera follow cursor
    editor_state.camera_x = editor_state.cursor_x;
    editor_state.camera_y = editor_state.cursor_y;
}

pub fn render_step(memory: *api.EditorMemory, ctx: *api.RenderContext) callconv(.c) void {
    const editor_state = memory.state;
    draw.fill_checkerboard(ctx.level, 8, 0xFF, 0x00FF00);
    if (editor_state.level) |level| {
        // TODO render bg
        draw.draw_image(ctx.level, level.bg, 0, 0);
        // render things
        render_shared.render_things(ctx.level, ctx.storage, &editor_state.things);
        // TODO render fg
        draw.draw_image(ctx.level, level.fg, 0, 0);
        // render selector
        draw.draw_image(ctx.level, ctx.storage.get(.cursor), editor_state.cursor_x, editor_state.cursor_y);
        // take camera view
        draw.view(ctx.level, ctx.screen, editor_state.camera_x, editor_state.camera_y);
    }
    // render ui
    render_shared.render_menu(ctx.screen, ctx.storage, &editor_state.things, &editor_state.menu);
}

comptime {
    @export(&editor_step, .{ .name = "editor_step" });
    @export(&render_step, .{ .name = "render_step" });
}
