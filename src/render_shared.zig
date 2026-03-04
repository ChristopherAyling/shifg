const menus = @import("menus.zig");
const std = @import("std");
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const ui = @import("ui.zig");
const con = @import("constants.zig");
const sprites = @import("sprites.zig");
const ThingPool = @import("things.zig").ThingPool;
const draw = @import("draw.zig");
const eui = @import("editor_ui.zig");

pub fn render_things(level: *ScreenBuffer, storage: *sprites.SpriteStorage, things: *ThingPool) void {

    // things
    {
        var it = things.iter();
        while (it.next_active()) |thing| {
            if (thing.visible) draw.draw_image(level, storage.get(thing.spritekey), thing.x, thing.y);
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
}

pub fn draw_named_item_list(screen: *ScreenBuffer, storage: *sprites.SpriteStorage, x0: i32, y0: i32, named_item_list: menus.NamedItemList, index: usize) void {
    const title = named_item_list.name.get();
    const item_list = named_item_list.item_list;

    if (item_list.count == 0) {
        ui.drawTextBox(screen, "editor", "category is empty");
        return;
    }

    const padding: i32 = 3;
    const longest_label: i32 = @intCast(item_list.longest_label());
    const title_height = padding + con.FONT_H + 2;
    const title_width: i32 = padding + @as(i32, @intCast(title.len * (con.FONT_W + 1))) + padding;
    const content_width: i32 = padding + con.PLAYER_W + @as(i32, @intCast(longest_label * (con.FONT_W + 1))) + padding;
    const row_height: i32 = @max(con.FONT_H, con.PLAYER_H) + 1;
    const content_height: i32 = @as(i32, @intCast(item_list.count)) * row_height;
    const rec_width: i32 = @max(title_width, content_width);
    const rec_height: i32 = title_height + content_height + padding;

    draw.draw_rec(
        screen,
        x0,
        y0,
        x0 + rec_width,
        y0 + rec_height,
        0x00F0F0,
        0x787276,
    );

    // title
    draw.draw_text(screen, title, x0 + padding, y0 + padding, 0xFFFFFF);

    // contents
    for (0..item_list.count) |i| {
        const ii: i32 = @intCast(i);
        const item = item_list.items[i];
        if (item.icon) |icon| {
            draw.draw_image(
                screen,
                storage.get(icon),
                x0 + padding,
                y0 + title_height + row_height * ii,
            );
        }
        if (item.label) |label| {
            draw.draw_text(
                screen,
                label.get(),
                x0 + padding + con.PLAYER_W + 2,
                y0 + 1 + title_height + row_height * ii,
                0xFFF0F0,
            );
        }
    }

    // selection
    const iidx: i32 = @intCast(index);
    const chosen_item = item_list.get(index);
    if (chosen_item.label) |label| {
        const w: i32 = @intCast(label.len);
        draw.draw_line(
            screen,
            x0 + padding + con.PLAYER_W + 2,
            y0 + 1 + title_height + row_height * iidx + con.FONT_H,
            x0 + padding + con.PLAYER_W + 2 + (w * (con.FONT_W + 1)),
            y0 + 1 + title_height + row_height * iidx + con.FONT_H,
            0xFFF000,
        );
    }
    if (chosen_item.icon) |_| {
        draw.draw_image(
            screen,
            storage.get(.cursor),
            x0 + padding,
            y0 + title_height + row_height * (iidx),
        );
    }
}

pub fn draw_named_item_list_collection(screen: *ScreenBuffer, storage: *sprites.SpriteStorage, x0: i32, y0: i32, m: menus.NamedItemListCollection, category: usize, index: usize) void {
    draw_named_item_list(screen, storage, x0, y0, m.get(category), index);
}

pub fn render_menu(screen: *ScreenBuffer, storage: *sprites.SpriteStorage, things: *ThingPool, menu_state: *menus.MenuState) void {
    for (0..menu_state.depth) |depth| {
        const menu = menu_state.stack[depth];
        switch (menu) {
            .dialogue => |dialogue_menu| {
                const line = dialogue_menu.get_line();
                ui.drawTextBox(screen, line.speaker_name, line.text);
            },
            .inventory => {
                ui.drawTextBox(screen, "game", "inventory");
            },
            .context => |context_menu| {
                var items: ui.ContextMenuItems = .{};
                items.add(@tagName(context_menu.priority));
                items.add("examine");
                ui.draw_context_menu(screen, con.NATIVE_W_HALF + con.PLAYER_W, con.NATIVE_H_HALF + con.PLAYER_H, context_menu.index, items);
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
                ui.draw_radial_menu(screen, storage, con.NATIVE_W_HALF, con.NATIVE_H_HALF, action_menu.index, "actions", action_items);
            },
            .examine => |examine_menu| {
                const examination_target = things.get(examine_menu.examination_target_ref);
                if (examination_target.kind == .UNSET) {
                    ui.drawTextBox(screen, "examination", "there appears to be nothing here");
                } else {
                    var buf: [128]u8 = undefined;
                    const text = std.fmt.bufPrint(&buf, "you examine {s}.", .{examination_target.name}) catch unreachable;
                    ui.drawTextBox(screen, "examination", text);
                }
            },
            // editor only
            .editor_level_select => |editor_level_select| {
                draw_named_item_list(screen, storage, 5, 5, editor_level_select.levels, editor_level_select.index);
            },
            .editor_place => |editor_place_menu| {
                draw_named_item_list_collection(screen, storage, 5, 5, editor_place_menu.categories, editor_place_menu.category, editor_place_menu.index);
            },
        }
    }
}
