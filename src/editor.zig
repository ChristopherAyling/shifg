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
const ThingRef = @import("things.zig").ThingRef;
const Kind = @import("things.zig").Kind;
const menus = @import("menus.zig");
const Inputs = control.Inputs;
const render_shared = @import("render_shared.zig");
const NpcKey = @import("npcs.zig").NpcKey;

// NpcKey.

const PlacementEntry = struct { label: []const u8, icon: sprites.SpriteKey = undefined, npc_key: NpcKey = undefined };
const PLACEMENT_MENU_DATA = [_][]const PlacementEntry{
    // npcs
    &.{
        .{ .label = "Argaven", .npc_key = .Argaven, .icon = .argaven },
        .{ .label = "Estraven", .npc_key = .Estraven, .icon = .estraven },
        .{ .label = "Avowed Priest", .npc_key = .AvowedPriest, .icon = .avowed_priest },
        .{ .label = "Garlyth", .npc_key = .GarlythGraystock, .icon = .garlyth },
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
    // portals
    &.{
        .{ .label = "portal", .icon = .portal_source },
    },
};

fn make_placement_menu() menus.NamedItemListCollection {
    var placement_menu = menus.NamedItemListCollection.init();
    const headers = [_][]const u8{
        "npc",
        "items",
        "player",
        "portals",
    };
    assert(headers.len == PLACEMENT_MENU_DATA.len);
    for (headers, 0..) |header, idx| {
        var l = menus.NamedItemList.init(header);
        for (PLACEMENT_MENU_DATA[idx]) |entry| {
            l.add(entry.label, entry.icon);
        }
        placement_menu.add(l);
    }
    return placement_menu;
}
const PLACEMENT_MENU = make_placement_menu();

fn place(things: *ThingPool, x: i32, y: i32, category: usize, index: usize) ThingRef {
    const entry = PLACEMENT_MENU_DATA[category][index];
    switch (category) {
        0 => {
            return things.add_npc(entry.npc_key, x, y);
        },
        1 => {
            return things.add_item(entry.icon, x, y);
        },
        2 => {
            return things.add_player(entry.icon, x, y);
        },
        3 => {
            return things.add_portal(x, y, .{ .x = 0, .y = 0 });
        },
        else => unreachable,
    }
}

const LEVEL_SELECT_DATA = [_][]const u8{ "one", "arch", "library", "library_gate" };

fn make_level_select_menu() menus.NamedItemList {
    var levels = menus.NamedItemList.init("levels");
    for (LEVEL_SELECT_DATA) |name| {
        levels.add(name, .missing);
    }
    return levels;
}

const LEVEL_SELECT_MENU = make_level_select_menu();

const Option = enum {
    save,
    levels,
    quit,
};
fn make_options_menu() menus.NamedItemList {
    var options = menus.NamedItemList.init("options");
    for (std.meta.tags(Option)) |option| {
        options.add(@tagName(option), .missing);
    }
    return options;
}
const OPTIONS_MENU = make_options_menu();

const CURSOR_VELOCITY = 1;

pub fn editor_step(memory: *api.EditorMemory, inputs: *const Inputs, platform_api: *const api.PlatformAPI) callconv(.c) void {
    const editor_state = memory.state;

    // handle menu inputs
    if (editor_state.menu.current()) |current| {
        if (inputs.b.pressed) {
            switch (current.*) {
                // uncancellable states
                .dialogue,
                .editor_portal_dest_select,
                .editor_level_select,
                => {},
                // all others are cancellable
                else => {
                    editor_state.menu.pop();
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
                        editor_state.menu.pop();
                    }
                    return;
                },
                .editor_place => |*editor_place_menu| {
                    if (inputs.a.pressed) {
                        const ref = place(&editor_state.things, editor_state.cursor_x, editor_state.cursor_y, editor_place_menu.category, editor_place_menu.index);
                        editor_state.menu.pop();
                        // further actions
                        switch (editor_state.things.get(ref).kind) {
                            .PORTAL => {
                                // you just placed a portal, now select where it links to.
                                editor_state.menu.push(.{ .editor_portal_dest_select = .{
                                    .portal_ref = ref,
                                    .x = editor_state.cursor_x,
                                    .y = editor_state.cursor_y,
                                } });
                            },
                            else => {},
                        }
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
                .editor_options => |*editor_options_menu| {
                    if (inputs.start.pressed) {
                        editor_state.menu.pop();
                        return;
                    }
                    if (inputs.a.pressed) {
                        const option: Option = @enumFromInt(editor_options_menu.index);
                        switch (option) {
                            .save => {
                                platform_api.save_level_things(editor_state.level.?.name, &editor_state.things);
                                std.log.debug("saved", .{});
                            },
                            .levels => {
                                editor_state.menu.push(.{ .editor_level_select = menus.EditorLevelSelectMenuState.init(LEVEL_SELECT_MENU) });
                                editor_state.menu.pop();
                            },
                            .quit => {
                                memory.done = true;
                            },
                        }
                        return;
                    }
                    if (inputs.up.pressed) {
                        editor_options_menu.dec();
                        return;
                    }
                    if (inputs.down.pressed) {
                        editor_options_menu.inc();
                        return;
                    }
                },
                .editor_portal_dest_select => |*editor_portal_dest_select_menu| {
                    if (inputs.directions.contains(.up)) editor_portal_dest_select_menu.y -= 1 * CURSOR_VELOCITY;
                    if (inputs.directions.contains(.down)) editor_portal_dest_select_menu.y += 1 * CURSOR_VELOCITY;
                    if (inputs.directions.contains(.left)) editor_portal_dest_select_menu.x -= 1 * CURSOR_VELOCITY;
                    if (inputs.directions.contains(.right)) editor_portal_dest_select_menu.x += 1 * CURSOR_VELOCITY;

                    // camera follow portal selecotor
                    editor_state.camera_x = editor_portal_dest_select_menu.x;
                    editor_state.camera_y = editor_portal_dest_select_menu.y;

                    const portal = editor_state.things.get(editor_portal_dest_select_menu.portal_ref);
                    portal.portal_dest.x = editor_portal_dest_select_menu.x;
                    portal.portal_dest.y = editor_portal_dest_select_menu.y;

                    if (inputs.a.pressed) {
                        editor_state.menu.pop();
                        return;
                    }
                    if (inputs.b.pressed) {
                        portal.active = false;
                        editor_state.menu.pop();
                        return;
                    }
                },
                else => unreachable,
            }
        }
        return;
    }

    if (editor_state.level == null) {
        // add level select screen
        editor_state.menu.push(.{ .editor_level_select = menus.EditorLevelSelectMenuState.init(LEVEL_SELECT_MENU) });
        return;
    }

    if (inputs.a.pressed) {
        // open placement menu
        editor_state.menu.push(.{ .editor_place = menus.EditorPlaceMenuState.init(PLACEMENT_MENU) });
        return;
    }

    if (inputs.start.pressed) {
        // open settings menu
        editor_state.menu.push(.{ .editor_options = menus.EditorOptionsMenuState.init(OPTIONS_MENU) });
    }

    if (inputs.b.pressed) {
        // delete things
        {
            var it = editor_state.things.iter();
            while (it.next_active_near(editor_state.cursor_x, editor_state.cursor_y, 8)) |thing| {
                thing.active = false;
            }
        }
        return;
    }

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
        render_shared.render_things(ctx.level, ctx.storage, &editor_state.things, true);
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
