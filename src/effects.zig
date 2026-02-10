// visual effects

const std = @import("std");
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const con = @import("constants.zig");

var frame: u32 = 0;

fn hash(seed: u32) u32 {
    var s = seed;
    s ^= s >> 16;
    s *%= 0x45d9f3b;
    s ^= s >> 16;
    s *%= 0x45d9f3b;
    s ^= s >> 16;
    return s;
}

pub fn snow(screen: *ScreenBuffer, t: usize) void {
    _ = t;
    frame +%= 1;

    for (0..300) |i| {
        const seed: u32 = @intCast(i * 7919);
        const x: i32 = @intCast(@mod(seed, @as(u32, @intCast(con.LEVEL_W))));

        // Each flake has its own start/end y range
        const start_y = @mod(seed / 3, @as(u32, @intCast(con.LEVEL_H / 2)));
        const fall_distance = 40 + @mod(seed / 7, 200);

        const fall_speed: u32 = 1 + @mod(seed / 100, 2);
        const y_offset = start_y + ((frame / 5) * fall_speed);
        const y: i32 = @intCast(@mod(y_offset, fall_distance) + start_y);

        if (y < con.LEVEL_H) {
            screen.setPixel(x, y, 0xFFFFFF);
        }
    }
}

/// Rainstorm — fast diagonal streaks with a blue tint
pub fn rain(screen: *ScreenBuffer, t: usize) void {
    _ = t;
    frame +%= 1;

    const w: u32 = @intCast(con.LEVEL_W);
    const h: u32 = @intCast(con.LEVEL_H);

    for (0..500) |i| {
        const seed = hash(@intCast(i));
        const base_x = @mod(seed, w);
        const fall_speed: u32 = 4 + @mod(seed / 13, 4);
        const streak_len: u32 = 3 + @mod(seed / 37, 5);
        const start_y = @mod(seed / 7, h);
        const y_pos = @mod(start_y + frame * fall_speed, h);

        // wind drift: rain falls slightly to the right
        const drift = (frame * 2 + @mod(seed / 11, 3)) % w;

        for (0..streak_len) |s| {
            const sy: i32 = @intCast(@mod(y_pos + h - @as(u32, @intCast(s)), h));
            const sx: i32 = @intCast(@mod(base_x + drift -| @as(u32, @intCast(s)), w));
            if (sx >= 0 and sx < con.LEVEL_W and sy >= 0 and sy < con.LEVEL_H) {
                // lighter blue at tip, darker at tail
                const brightness: u32 = 180 - @as(u32, @intCast(s)) * 30;
                const color: u32 = (brightness << 16) | (brightness << 8) | 0xFF;
                screen.setPixel(sx, sy, color);
            }
        }
    }
}

/// Fireflies — softly glowing dots that drift and pulse
pub fn fireflies(screen: *ScreenBuffer, t: usize) void {
    _ = t;
    frame +%= 1;

    const w: u32 = @intCast(con.LEVEL_W);
    const h: u32 = @intCast(con.LEVEL_H);

    for (0..60) |i| {
        const seed = hash(@intCast(i * 3571));

        // slow drifting position
        const drift_x = @mod(seed + frame / 3, w);
        const drift_y = @mod(seed / 5 + frame / 5, h);

        // wobble using frame
        const wobble_x: i32 = @as(i32, @intCast(@mod(hash(seed +% frame / 7), 5))) - 2;
        const wobble_y: i32 = @as(i32, @intCast(@mod(hash(seed +% frame / 9), 5))) - 2;

        const x: i32 = @as(i32, @intCast(drift_x)) + wobble_x;
        const y: i32 = @as(i32, @intCast(drift_y)) + wobble_y;

        // pulse: each firefly blinks on/off with its own phase
        const pulse_phase = @mod(frame + seed, 120);
        const visible = pulse_phase < 60;

        if (visible and x >= 0 and x < con.LEVEL_W and y >= 0 and y < con.LEVEL_H) {
            // warm yellow-green glow
            const bright: u32 = if (pulse_phase < 30) pulse_phase * 4 else (60 - pulse_phase) * 4;
            const r: u32 = @min(bright + 80, 255);
            const g: u32 = @min(bright + 100, 255);
            const b: u32 = 20;
            const color: u32 = (r << 24) | (g << 16) | (b << 8) | 0xFF;
            screen.setPixel(x, y, color);

            // glow halo (dimmer surrounding pixels)
            const dim_color: u32 = ((r / 3) << 24) | ((g / 3) << 16) | ((b / 3) << 8) | 0x80;
            if (x > 0) screen.setPixel(x - 1, y, dim_color);
            if (x + 1 < con.LEVEL_W) screen.setPixel(x + 1, y, dim_color);
            if (y > 0) screen.setPixel(x, y - 1, dim_color);
            if (y + 1 < con.LEVEL_H) screen.setPixel(x, y + 1, dim_color);
        }
    }
}

/// Starfield — parallax stars scrolling downward at different speeds
pub fn starfield(screen: *ScreenBuffer, t: usize) void {
    _ = t;
    frame +%= 1;

    const w: u32 = @intCast(con.LEVEL_W);
    const h: u32 = @intCast(con.LEVEL_H);

    // Three layers: far (dim/slow), mid, near (bright/fast)
    const layers = [_]struct { count: u32, speed: u32, brightness: u32 }{
        .{ .count = 100, .speed = 1, .brightness = 80 },
        .{ .count = 60, .speed = 2, .brightness = 160 },
        .{ .count = 30, .speed = 4, .brightness = 255 },
    };

    for (layers) |layer| {
        for (0..layer.count) |i| {
            const seed = hash(@intCast(i * 6571 + layer.speed * 9999));
            const x: i32 = @intCast(@mod(seed, w));
            const base_y = @mod(seed / 3, h);
            const y: i32 = @intCast(@mod(base_y + frame * layer.speed, h));

            // twinkle: slight brightness variation
            const twinkle = @mod(hash(seed +% frame / 4), 40);
            const b = @min(layer.brightness + twinkle, @as(u32, 255));
            const color: u32 = (b << 24) | (b << 16) | (b << 8) | 0xFF;

            if (x >= 0 and x < con.LEVEL_W and y >= 0 and y < con.LEVEL_H) {
                screen.setPixel(x, y, color);
            }
        }
    }
}

/// Matrix rain — green falling columns of characters (represented as bright dots)
pub fn matrix(screen: *ScreenBuffer, t: usize) void {
    _ = t;
    frame +%= 1;

    const w: u32 = @intCast(con.LEVEL_W);
    const h: u32 = @intCast(con.LEVEL_H);
    const col_spacing: u32 = 6;
    const num_cols = w / col_spacing;

    for (0..num_cols) |ci| {
        const col_seed = hash(@intCast(ci * 8831));
        const x: i32 = @intCast(@as(u32, @intCast(ci)) * col_spacing + @mod(col_seed, col_spacing));
        const fall_speed: u32 = 2 + @mod(col_seed / 11, 3);
        const trail_len: u32 = 8 + @mod(col_seed / 23, 16);
        const head_y = @mod(@mod(col_seed / 3, h) + frame * fall_speed, h);

        for (0..trail_len) |ti| {
            const ty: i32 = @as(i32, @intCast(head_y)) - @as(i32, @intCast(ti)) * 3;
            if (ty >= 0 and ty < con.LEVEL_H and x >= 0 and x < con.LEVEL_W) {
                // head is bright white-green, trail fades to dark green
                const fade: u32 = @intCast(ti);
                const g: u32 = if (ti == 0) 255 else @max(255 -| fade * 30, 40);
                const r: u32 = if (ti == 0) 200 else 0;
                const b: u32 = if (ti == 0) 200 else 0;
                const color: u32 = (r << 24) | (g << 16) | (b << 8) | 0xFF;
                screen.setPixel(x, ty, color);
            }
        }
    }
}
