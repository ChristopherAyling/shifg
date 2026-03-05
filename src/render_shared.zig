const menus = @import("menus.zig");
const std = @import("std");
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const ui = @import("ui.zig");
const con = @import("constants.zig");
const sprites = @import("sprites.zig");
const ThingPool = @import("things.zig").ThingPool;
const draw = @import("draw.zig");
const eui = @import("editor_ui.zig");

pub fn render_things(level: *ScreenBuffer, storage: *sprites.SpriteStorage, things: *ThingPool, show_invisible: bool) void {

    // things
    {
        var it = things.iter();
        while (it.next_active()) |thing| {
            if (show_invisible or thing.visible) {
                draw.draw_image(level, storage.get(thing.spritekey), thing.x, thing.y);
                switch (thing.kind) {
                    .PORTAL => {
                        draw.draw_image(level, storage.get(.portal_dest), thing.portal_dest.x, thing.portal_dest.y);
                        if (show_invisible) {
                            draw.draw_line(level, thing.x, thing.y, thing.portal_dest.x, thing.portal_dest.y, 0xFFA500);
                        }
                    },
                    else => {},
                }
            }
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

pub fn draw_radial_menu(screen: *ScreenBuffer, sprite_storage: *sprites.SpriteStorage, x0: i32, y0: i32, title: []const u8, state: menus.ActionMenuState) void {
    const inner_radius = 20;
    const outer_radius = 40;
    const math = std.math;
    const n = state.items.len;
    const current = state.index;

    if (n == 0) return;

    // Offset by half a slice so items sit at N, NE, E, SE, S, SW, W, NW
    // and dividing lines fall between them
    const slice_angle = (2.0 * math.pi) / @as(f32, @floatFromInt(n));
    const half_slice = slice_angle / 2.0;

    // Start from -pi/2 (north) so index 0 = up
    const north_offset = -math.pi / 2.0;

    // draw dividing lines between slices
    for (0..n) |i| {
        const angle = north_offset + slice_angle * @as(f32, @floatFromInt(i)) - half_slice;
        const cos_a = math.cos(angle);
        const sin_a = math.sin(angle);
        const ix = x0 + @as(i32, @intFromFloat(cos_a * @as(f32, inner_radius)));
        const iy = y0 + @as(i32, @intFromFloat(sin_a * @as(f32, inner_radius)));
        const ox = x0 + @as(i32, @intFromFloat(cos_a * @as(f32, outer_radius)));
        const oy = y0 + @as(i32, @intFromFloat(sin_a * @as(f32, outer_radius)));
        draw.draw_line(screen, ix, iy, ox, oy, 0xFFFFFF);
    }

    // draw selected slice as donut wedge
    const clamped_current = if (current < n) current else 0;
    {
        const steps = 8;
        const a0 = north_offset + slice_angle * @as(f32, @floatFromInt(clamped_current)) - half_slice;
        const a1 = a0 + slice_angle;

        var points: [(steps + 1) * 2]draw.Point = undefined;

        for (0..steps + 1) |s| {
            const t = a0 + (a1 - a0) * @as(f32, @floatFromInt(s)) / @as(f32, steps);
            points[s] = .{
                .x = x0 + @as(i32, @intFromFloat(math.cos(t) * @as(f32, outer_radius))),
                .y = y0 + @as(i32, @intFromFloat(math.sin(t) * @as(f32, outer_radius))),
            };
        }

        for (0..steps + 1) |s| {
            const t = a1 - (a1 - a0) * @as(f32, @floatFromInt(s)) / @as(f32, steps);
            points[steps + 1 + s] = .{
                .x = x0 + @as(i32, @intFromFloat(math.cos(t) * @as(f32, inner_radius))),
                .y = y0 + @as(i32, @intFromFloat(math.sin(t) * @as(f32, inner_radius))),
            };
        }

        draw.draw_poly(screen, &points, 0xFFFF00, 0x884400);
    }

    // draw sprites in each slice
    const sprite_radius = @divFloor(inner_radius + outer_radius, 2);
    for (0..n) |i| {
        if (state.items[i]) |item| {
            const angle = north_offset + slice_angle * @as(f32, @floatFromInt(i));
            const sprite_x = x0 + @as(i32, @intFromFloat(math.cos(angle) * @as(f32, sprite_radius)));
            const sprite_y = y0 + @as(i32, @intFromFloat(math.sin(angle) * @as(f32, sprite_radius)));
            if (item.icon) |sprite_key| {
                const sprite = sprite_storage.get(sprite_key);
                // center the sprite
                const sx = sprite_x - @divFloor(sprite.w, 2);
                const sy = sprite_y - @divFloor(sprite.h, 2);
                draw.draw_image(screen, sprite, sx, sy);
            }
        }
    }

    // draw title above with background
    const title_x = x0 - @as(i32, @intCast(title.len * 2));
    const title_y = y0 - outer_radius - 10;
    const title_w: i32 = @intCast(title.len * 4);
    draw.draw_rec(screen, title_x - 2, title_y - 2, title_x + title_w + 1, title_y + 6, 0x444444, 0x444444);
    draw.draw_text(screen, title, title_x, title_y, 0xFFFFFF);

    // draw selected item label below with background
    if (state.items[clamped_current]) |selected_item| {
        if (selected_item.label) |label| {
            const label_x = x0 - @as(i32, @intCast(label.len * 2));
            const label_y = y0 + outer_radius + 5;
            const label_w: i32 = @intCast(label.len * 4);
            draw.draw_rec(screen, label_x - 2, label_y - 2, label_x + label_w + 1, label_y + 6, 0x444444, 0x444444);
            draw.draw_text(screen, label.get(), label_x, label_y, 0xFFFFFF);
        }
    }
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
                draw_radial_menu(screen, storage, con.NATIVE_W_HALF, con.NATIVE_H_HALF, "actions", action_menu);
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
            .editor_options => |editor_options| {
                draw_named_item_list(screen, storage, 5, 5, editor_options.options, editor_options.index);
            },
            .editor_portal_dest_select => |editor_portal_dest_select| {
                draw.draw_image(screen, storage.get(.portal_dest), editor_portal_dest_select.x, editor_portal_dest_select.y);
            },
        }
    }
}
