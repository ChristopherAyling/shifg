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
