const std = @import("std");
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const draw = @import("draw.zig");
const Image = @import("image.zig").Image;
const sprites = @import("sprites.zig");
const con = @import("constants.zig");

const Storage = sprites.SpriteStorage;
const SpriteKey = sprites.SpriteKey;

pub fn draw_sprite_selector(screen: *ScreenBuffer, storage: *Storage, idx: i32) void {
    // _ = idx;
    const PADDING = 4;
    const N_SPRITES = 3;
    draw.draw_rec(
        screen,
        0,
        0,
        con.PLAYER_W + (2 * PADDING),
        (con.PLAYER_H + PADDING) * N_SPRITES + PADDING,
        0x00F0F0,
        0x787276,
    );
    draw.draw_image(screen, storage.get(.genly), PADDING, PADDING);
    draw.draw_image(screen, storage.get(.estraven), PADDING, (con.PLAYER_H + PADDING) * 1 + PADDING);
    draw.draw_image(screen, storage.get(.argaven), PADDING, (con.PLAYER_H + PADDING) * 2 + PADDING);

    draw.draw_image(screen, storage.get(.cursor), PADDING, (con.PLAYER_H + PADDING) * idx + PADDING);
    std.log.debug("idx: {any}", .{idx});
}
