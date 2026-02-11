const std = @import("std");
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const draw = @import("draw.zig");
const Image = @import("image.zig").Image;
const sprites = @import("sprites.zig");
const con = @import("constants.zig");

const Storage = sprites.SpriteStorage;
const SpriteKey = sprites.SpriteKey;

pub fn draw_sprite_selector(screen: *ScreenBuffer, storage: *Storage, idx: usize, sprite_keys: []const SpriteKey) void {
    // _ = idx;
    const PADDING = 4;
    const N_SPRITES: i32 = @intCast(sprite_keys.len);
    draw.draw_rec(
        screen,
        0,
        0,
        con.PLAYER_W + (2 * PADDING),
        (con.PLAYER_H + PADDING) * N_SPRITES + PADDING,
        0x00F0F0,
        0x787276,
    );
    for (sprite_keys, 0..) |sprite_key, i| {
        const ii: i32 = @intCast(i);
        draw.draw_image(screen, storage.get(sprite_key), PADDING, (con.PLAYER_H + PADDING) * ii + PADDING);
    }

    const iidx: i32 = @intCast(idx);
    draw.draw_image(screen, storage.get(.cursor), PADDING, (con.PLAYER_H + PADDING) * iidx + PADDING);
}
