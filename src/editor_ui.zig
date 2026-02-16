const std = @import("std");
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const draw = @import("draw.zig");
const Image = @import("image.zig").Image;
const sprites = @import("sprites.zig");
const con = @import("constants.zig");

const Storage = sprites.SpriteStorage;
const SpriteKey = sprites.SpriteKey;

pub fn draw_sprite_menu(screen: *ScreenBuffer, x0: i32, y0: i32, storage: *Storage, idx: usize, sprite_keys: []const SpriteKey, title: []const u8) void {
    // _ = idx;
    const PADDING: i32 = 4;
    const N_SPRITES: i32 = @intCast(sprite_keys.len);
    const TITLE_WIDTH: i32 = PADDING + @as(i32, @intCast(title.len * con.FONT_W + 1)) + PADDING;
    const SPRITE_WIDTH: i32 = PADDING + con.PLAYER_W + PADDING;
    const REC_WIDTH: i32 = @max(TITLE_WIDTH, SPRITE_WIDTH);
    draw.draw_rec(
        screen,
        x0,
        y0,
        x0 + REC_WIDTH,
        y0 + (con.PLAYER_H + PADDING) * N_SPRITES + PADDING + con.FONT_H + PADDING,
        0x00F0F0,
        0x787276,
    );

    draw.draw_text(screen, title, x0 + PADDING, y0 + PADDING, 0xFFFFFF);

    for (sprite_keys, 0..) |sprite_key, i| {
        const ii: i32 = @intCast(i);
        draw.draw_image(
            screen,
            storage.get(sprite_key),
            x0 + PADDING,
            y0 + (con.PLAYER_H + PADDING) * ii + PADDING + con.FONT_H + PADDING,
        );
    }

    const iidx: i32 = @intCast(idx);
    draw.draw_image(
        screen,
        storage.get(.cursor),
        x0 + PADDING,
        y0 + (con.PLAYER_H + PADDING) * iidx + PADDING + con.FONT_H + PADDING,
    );
}

pub fn draw_text_menu(screen: *ScreenBuffer, x0: i32, y0: i32, idx: usize, labels: []const []const u8) void {
    const PADDING = 4;
    const N_LABELS: i32 = @intCast(labels.len);
    // const MENU_WIDTH = std.mem.max(usize, &.{for (labels) |s| s.len});

    const MENU_WIDTH = blk: {
        var max: usize = 0;
        for (labels) |s| {
            if (s.len > max) max = s.len;
        }
        break :blk max;
    };
    const iMENU_WIDTH: i32 = @intCast(MENU_WIDTH);

    // const x0 = 0;
    // const y0 = 0;

    draw.draw_rec(
        screen,
        x0,
        y0,
        x0 + ((con.FONT_W + 1) * iMENU_WIDTH) + (2 * PADDING),
        y0 + (con.FONT_H + PADDING) * N_LABELS + PADDING,
        0x00F0F0,
        0x787276,
    );

    for (labels, 0..) |label, i| {
        const ii: i32 = @intCast(i);
        draw.draw_text(
            screen,
            label,
            x0 + PADDING,
            y0 + (con.FONT_H + PADDING) * ii + PADDING,
            0xFFF0F0,
        );
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
