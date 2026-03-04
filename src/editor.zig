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

pub fn editor_step(memory: *api.EditorMemory, inputs: *const Inputs, platform_api: *const api.PlatformAPI) callconv(.c) void {
    _ = platform_api;
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
                },
                .editor_place => |*editor_place_menu| {
                    if (inputs.a.pressed) {
                        // TODO get x and y from selector
                        place(&editor_state.things, 0, 0, editor_place_menu.category, editor_place_menu.index);
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
                else => {},
            }
        }
        return;
    }

    if (inputs.a.pressed) {
        // open placement menu
        editor_state.menu.push(.{ .editor_place = menus.EditorPlaceMenuState.init(PLACEMENT_MENU) });
        return;
    }

    // TODO open settings menu (save etc)

    // TODO cursor movement
}

pub fn render_step(memory: *api.EditorMemory, ctx: *api.RenderContext) callconv(.c) void {
    const editor_state = memory.state;
    draw.fill_checkerboard(ctx.screen, 10, 0xFF, 0x00FF00);
    render_shared.render_things(ctx.screen, ctx.storage, &editor_state.things);
    render_shared.render_menu(ctx.screen, ctx.storage, &editor_state.things, &editor_state.menu);
}

comptime {
    @export(&editor_step, .{ .name = "editor_step" });
    @export(&render_step, .{ .name = "render_step" });
}
