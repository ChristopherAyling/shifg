// snow falling effect

const std = @import("std");
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const con = @import("constants.zig");

// pub fn snow(screen: *ScreenBuffer, t: usize) void {
//     _ = t;
//     for (0..50) |_| {
//         const y = std.crypto.random.intRangeAtMost(i32, 0, con.LEVEL_H - 1);
//         const x = std.crypto.random.intRangeAtMost(i32, 0, con.LEVEL_W - 1);

//         screen.setPixel(x, y, 0xFFFFFF);
//     }
//     // set a few random pixels to white

// }

// snow falling effect
// const std = @import("std");
// const ScreenBuffer = @import("screen.zig").ScreenBuffer;
// const con = @import("constants.zig");

// var frame: u32 = 0;

// pub fn snow(screen: *ScreenBuffer, t: usize) void {
//     _ = t;
//     frame +%= 1;

//     // Draw snow at pseudo-random but deterministic positions
//     // Each "snowflake" falls by incrementing y offset over time
//     for (0..80) |i| {
//         // Use index to seed position - same index = same x position
//         const seed: u32 = @intCast(i * 7919); // prime for spread
//         const x: i32 = @intCast(@mod(seed, @as(u32, @intCast(con.LEVEL_W))));

//         // y position falls over time, wraps around
//         const fall_speed: u32 = 1 + @mod(seed / 1000, 3); // vary speed 1-3
//         const y_offset = (seed / 10) + (frame * fall_speed);
//         const y: i32 = @intCast(@mod(y_offset, @as(u32, @intCast(con.LEVEL_H))));

//         screen.setPixel(x, y, 0xFFFFFF);
//     }
// }

// pub fn snow(screen: *ScreenBuffer, t: usize) void {
//     _ = t;
//     frame +%= 1;

//     for (0..160) |i| {
//         const seed: u32 = @intCast(i * 7919);
//         const x: i32 = @intCast(@mod(seed, @as(u32, @intCast(con.LEVEL_W))));

//         // Divide frame to slow down falling
//         const fall_speed: u32 = 1 + @mod(seed / 100, 3);
//         const y_offset = (seed / 10) + ((frame / 4) * fall_speed);
//         const y: i32 = @intCast(@mod(y_offset, @as(u32, @intCast(con.LEVEL_H))));

//         screen.setPixel(x, y, 0xFFFFFF);
//     }
// }

var frame: u32 = 0;

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
