const std = @import("std");
const storage = @import("storage.zig");
const Window = @import("window.zig").Window;
const image = @import("image.zig");

pub fn fill(window: *Window, color: u32) void {
    for (0..window.w * window.h) |i| {
        window.f.buf[i] = color;
    }
}

pub fn draw_image(window: *Window, img: image.Image, x0: i32, y0: i32) void {
    const img_w: i32 = @intCast(img.w);
    const img_h: i32 = @intCast(img.h);
    const win_w: i32 = @intCast(window.w);
    const win_h: i32 = @intCast(window.h);

    const start_x = @max(x0, 0);
    const start_y = @max(y0, 0);
    const end_x = @min(x0 + img_w, win_w);
    const end_y = @min(y0 + img_h, win_h);

    var y = start_y;
    while (y < end_y) : (y += 1) {
        var x = start_x;
        while (x < end_x) : (x += 1) {
            const img_x: usize = @intCast(x - x0);
            const img_y: usize = @intCast(y - y0);
            const width: usize = @intCast(img.w);
            const offset = (img_y * width + img_x) * 3;

            // TODO: Actually draw the image pixels here
            const r: u32 = @intCast(img.data[@as(usize, offset)]);
            const g: u32 = img.data[offset + 1];
            const b: u32 = img.data[offset + 2];
            const color: u32 = (r << 16) | (g << 8) | b;
            draw_pixel(window, x, y, color, 0);
        }
    }
}

pub fn draw_pixel(window: *Window, x: i32, y: i32, color: u32, id: u32) void {
    if ((x < window.w) and (x > 0) and (y < window.h) and (y > 0)) {
        window.set_pixel(@intCast(x), @intCast(y), color);
        window.set_id(@intCast(x), @intCast(y), id);
    }
}

pub fn draw_line(window: *Window, x0: i32, y0: i32, x1: i32, y1: i32, color: u32, id: u32) void {
    var x = x0;
    var y = y0;
    const dx: i32 = @intCast(@abs(x1 - x0));
    const sx: i32 = if (x0 < x1) 1 else -1;
    var dy: i32 = @intCast(@abs(y1 - y0));
    dy *= -1;

    const sy: i32 = if (y0 < y1) 1 else -1;

    var err = dx + dy;

    while (true) {
        if ((x < window.w) and (x > 0) and (y < window.h) and (y > 0)) {
            window.set_pixel(@intCast(x), @intCast(y), color);
            window.set_id(@intCast(x), @intCast(y), id);
        }
        if ((x == x1) and (y == y1)) break;
        const err2 = 2 * err;

        if (err2 >= dy) {
            err += dy;
            x += sx;
        }
        if (err2 <= dx) {
            err += dx;
            y += sy;
        }
    }
}

pub fn clamp(n: f32, min: f32, max: f32) f32 {
    if (n < min) return min;
    if (n > max) return max;
    return n;
}

const font5x3 = [_]u16{ 0x0000, 0x2092, 0x002d, 0x5f7d, 0x279e, 0x52a5, 0x7ad6, 0x0012, 0x4494, 0x1491, 0x017a, 0x05d0, 0x1400, 0x01c0, 0x0400, 0x12a4, 0x2b6a, 0x749a, 0x752a, 0x38a3, 0x4f4a, 0x38cf, 0x3bce, 0x12a7, 0x3aae, 0x49ae, 0x0410, 0x1410, 0x4454, 0x0e38, 0x1511, 0x10e3, 0x73ee, 0x5f7a, 0x3beb, 0x624e, 0x3b6b, 0x73cf, 0x13cf, 0x6b4e, 0x5bed, 0x7497, 0x2b27, 0x5add, 0x7249, 0x5b7d, 0x5b6b, 0x3b6e, 0x12eb, 0x4f6b, 0x5aeb, 0x388e, 0x2497, 0x6b6d, 0x256d, 0x5f6d, 0x5aad, 0x24ad, 0x72a7, 0x6496, 0x4889, 0x3493, 0x002a, 0xf000, 0x0011, 0x6b98, 0x3b79, 0x7270, 0x7b74, 0x6750, 0x95d6, 0xb9ee, 0x5b59, 0x6410, 0xb482, 0x56e8, 0x6492, 0x5be8, 0x5b58, 0x3b70, 0x976a, 0xcd6a, 0x1370, 0x38f0, 0x64ba, 0x3b68, 0x2568, 0x5f68, 0x54a8, 0xb9ad, 0x73b8, 0x64d6, 0x2492, 0x3593, 0x03e0 };

pub fn draw_text(window: *Window, text: []const u8, x0: i32, y0: i32, color: u32) void {
    var xc = x0;
    for (0..text.len) |i| {
        const chr = text[i];
        if (chr > 32) {
            const bmp: u16 = font5x3[chr - 32];
            for (0..5) |dy| {
                for (0..3) |dx| {
                    const shift_value: u4 = @as(u4, @intCast(dy)) * 3 + @as(u4, @intCast(dx));
                    const not_blank = bmp >> shift_value & 1;
                    if (not_blank != 0) {
                        const px: i32 = xc + @as(i32, @intCast(dx));
                        const py: i32 = y0 + @as(i32, @intCast(dy));
                        draw_pixel(window, px, py, color, 0);
                    }
                }
            }
        }
        xc = xc + 4;
    }
}
