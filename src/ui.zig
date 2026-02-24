const std = @import("std");
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const draw = @import("draw.zig");
const Image = @import("image.zig").Image;
const con = @import("constants.zig");
const sprites = @import("sprites.zig");

pub const RadialMenuItem = struct {
    label: []const u8,
    sprite: sprites.SpriteKey,
};

pub const RadialMenuItems = struct {
    items: [8]?RadialMenuItem = .{null} ** 8,
    count: usize = 0,

    pub fn add(self: *RadialMenuItems, label: []const u8, sprite: sprites.SpriteKey) void {
        if (self.count < 8) {
            self.items[self.count] = .{ .label = label, .sprite = sprite };
            self.count += 1;
        }
    }
};

pub const ContextMenuItem = struct {
    label: []const u8,
    // sprite: sprites.SpriteKey = .missing,
};

pub const ContextMenuItems = struct {
    items: [4]?ContextMenuItem = .{null} ** 4,
    count: usize = 0,

    pub fn add(self: *ContextMenuItems, label: []const u8) void {
        if (self.count < 4) {
            self.items[self.count] = .{ .label = label };
            self.count += 1;
        } else {
            @panic("too many items attempted to be added to ContextMenuItems");
        }
    }
};

const PADDING: i32 = 4;

const TEXTBOX_X = 5;
const TEXTBOX_Y = 99;

const TEXT_COLOR = 0x22EEEE;
const TEXTBOX_COLOR = 0x22AA88;
const TEXTBOX_WIDTH = 150;
const TEXTBOX_HEIGHT = 40;

pub fn drawSplashText(screen: *ScreenBuffer, splash_sprite: Image) void {
    // draw.draw_rec(screen, TEXTBOX_X, TEXTBOX_Y, TEXTBOX_X + TEXTBOX_WIDTH, TEXTBOX_Y + TEXTBOX_HEIGHT, TEXTBOX_COLOR, 0x555555);
    draw.fill(screen, 0xFFFFFF);
    draw.draw_image(screen, splash_sprite, 0, 0);

    const title = "welcome to shif";
    const subtitle = "press start..";
    draw.draw_text(screen, title, con.NATIVE_W_HALF - (@divFloor(title.len, 2) * (con.FONT_W + 2)), con.NATIVE_H_HALF - 20, 0x00);
    draw.draw_text(screen, subtitle, con.NATIVE_W_HALF - (@divFloor(subtitle.len, 2) * (con.FONT_W + 2)), con.NATIVE_H_HALF + 30, 0x666666);
}

pub fn drawTextBox(screen: *ScreenBuffer, speaker: []const u8, text: []const u8) void {
    draw.draw_rec(screen, TEXTBOX_X, TEXTBOX_Y, TEXTBOX_X + TEXTBOX_WIDTH, TEXTBOX_Y + TEXTBOX_HEIGHT, TEXTBOX_COLOR, 0x555555);
    draw.draw_text(screen, speaker, TEXTBOX_X + 3, TEXTBOX_Y + 3, 0xFFFFFF);
    draw.draw_text(screen, text, TEXTBOX_X + 5, TEXTBOX_Y + 12, TEXT_COLOR);
}

pub fn draw_radial_menu(screen: *ScreenBuffer, sprite_storage: *sprites.SpriteStorage, x0: i32, y0: i32, current: usize, title: []const u8, items: RadialMenuItems) void {
    const inner_radius = 20;
    const outer_radius = 40;
    const math = std.math;
    const n = items.count;

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
        if (items.items[i]) |item| {
            const angle = north_offset + slice_angle * @as(f32, @floatFromInt(i));
            const sprite_x = x0 + @as(i32, @intFromFloat(math.cos(angle) * @as(f32, sprite_radius)));
            const sprite_y = y0 + @as(i32, @intFromFloat(math.sin(angle) * @as(f32, sprite_radius)));
            const sprite = sprite_storage.get(item.sprite);
            // center the sprite
            const sx = sprite_x - @divFloor(sprite.w, 2);
            const sy = sprite_y - @divFloor(sprite.h, 2);
            draw.draw_image(screen, sprite, sx, sy);
        }
    }

    // draw title above with background
    const title_x = x0 - @as(i32, @intCast(title.len * 2));
    const title_y = y0 - outer_radius - 10;
    const title_w: i32 = @intCast(title.len * 4);
    draw.draw_rec(screen, title_x - 2, title_y - 2, title_x + title_w + 1, title_y + 6, 0x444444, 0x444444);
    draw.draw_text(screen, title, title_x, title_y, 0xFFFFFF);

    // draw selected item label below with background
    if (items.items[clamped_current]) |selected_item| {
        const label_x = x0 - @as(i32, @intCast(selected_item.label.len * 2));
        const label_y = y0 + outer_radius + 5;
        const label_w: i32 = @intCast(selected_item.label.len * 4);
        draw.draw_rec(screen, label_x - 2, label_y - 2, label_x + label_w + 1, label_y + 6, 0x444444, 0x444444);
        draw.draw_text(screen, selected_item.label, label_x, label_y, 0xFFFFFF);
    }
}

pub fn draw_context_menu(screen: *ScreenBuffer, x0: i32, y0: i32, idx: usize, items: ContextMenuItems) void {
    const N_LABELS: i32 = @intCast(items.count);

    const MENU_WIDTH = blk: {
        var max: usize = 0;
        for (items.items) |maybe_item| {
            if (maybe_item) |item| {
                if (item.label.len > max) max = item.label.len;
            }
        }
        break :blk max;
    };
    const iMENU_WIDTH: i32 = @intCast(MENU_WIDTH);

    draw.draw_rec(
        screen,
        x0,
        y0,
        x0 + ((con.FONT_W + 1) * iMENU_WIDTH) + (2 * PADDING),
        y0 + (con.FONT_H + PADDING) * N_LABELS + PADDING,
        0x00F0F0,
        0x787276,
    );

    for (0..items.count) |i| {
        if (items.items[i]) |item| {
            const ii: i32 = @intCast(i);
            // TODO put sprite in menu maybe?
            draw.draw_text(
                screen,
                item.label,
                x0 + PADDING,
                y0 + (con.FONT_H + PADDING) * ii + PADDING,
                0xFFF0F0,
            );
        }
    }

    const iidx: i32 = @intCast(idx);
    draw.draw_line(
        screen,
        x0 + PADDING,
        y0 + (con.FONT_H + PADDING) * iidx + PADDING + con.FONT_H,
        x0 + iMENU_WIDTH * (con.FONT_W + 1) + PADDING - 1,
        y0 + (con.FONT_H + PADDING) * iidx + PADDING + con.FONT_H,
        0xFFF000,
    );
}
