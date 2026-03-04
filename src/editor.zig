const std = @import("std");
const assert = std.debug.assert;
const api = @import("game_api.zig");
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
const menus = @import("menus.zig");
const Inputs = control.Inputs;
const render_shared = @import("render_shared.zig");

pub fn editor_step(memory: *api.GameMemory, inputs: *const Inputs, platform_api: *const api.PlatformAPI) callconv(.c) void {
    const editor_state = memory.state;

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
    // _ = memory;
    // _ = inputs;
    // _ = platform_api;

    if (inputs.a.pressed) {
        var npcs = menus.NamedItemList.init("npc");
        npcs.add("aaaa", null);
        npcs.add("bbb", null);
        npcs.add("Argaven", .argaven);
        npcs.add("ccccccccc", null);
        npcs.add("ccccccccc", null);
        npcs.add("cc", null);

        var items = menus.NamedItemList.init("items");
        items.add("potato", null);
        items.add("rabbit", null);

        var player = menus.NamedItemList.init("player");
        player.add("genly", null);

        var m = menus.NamedItemListCollection.init();
        m.add(npcs);
        m.add(items);
        m.add(player);

        editor_state.menu.push(.{ .editor_place = menus.EditorPlaceMenuState.init(m) });
        return;
    }

    if (inputs.b.pressed) {
        platform_api.playSound(.click);
        return;
    }
}

pub fn render_step(memory: *api.GameMemory, ctx: *api.RenderContext) callconv(.c) void {
    const editor_state = memory.state;
    draw.fill_checkerboard(ctx.screen, 10, 0xFF, 0x00FF00);
    render_shared.render_menu(ctx.screen, ctx.storage, &editor_state.things, &editor_state.menu);
}

comptime {
    @export(&editor_step, .{ .name = "editor_step" });
    @export(&render_step, .{ .name = "render_step" });
}
