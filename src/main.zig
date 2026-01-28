const std = @import("std");
const assert = std.debug.assert;
const Window = @import("window.zig").Window;
const draw = @import("draw.zig");
const ui = @import("ui.zig");
const image = @import("image.zig");
const ScreenBuffer = @import("screen.zig").ScreenBuffer;

const Command = enum { none, up, down, left, right, a, b, menu };

const UP = 17;
const DOWN = 18;
const LEFT = 20;
const RIGHT = 19;

pub fn parseCommand(window: Window) Command {
    var command = Command.none;
    if (window.key(UP)) {
        command = Command.up;
    }
    if (window.key(DOWN)) {
        command = Command.down;
    }
    if (window.key(LEFT)) {
        command = Command.left;
    }
    if (window.key(RIGHT)) {
        command = Command.right;
    }
    return command;
}

pub fn game_step() void {}

pub fn render_step() void {
    // needs to access state / outputs of game step
}

fn blit(screen: ScreenBuffer, window: *Window) void {
    assert(screen.w == window.w);
    assert(screen.h == window.h);
    for (0..screen.data.len) |i| {
        window.f.buf[i] = screen.data[i];
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    const NATIVE_W = 160;
    const NATIVE_H = 144;
    const SCALE = 4;
    const UPSCALED_W = NATIVE_W * SCALE;
    const UPSCALED_H = NATIVE_H * SCALE;

    var screen: ScreenBuffer = try ScreenBuffer.init(allocator, NATIVE_W, NATIVE_H);
    var screen_upscaled: ScreenBuffer = try ScreenBuffer.init(allocator, UPSCALED_W, UPSCALED_H);

    var window = try Window.init(allocator, UPSCALED_W, UPSCALED_H);
    defer window.deinit();

    const filename: [:0]const u8 = "/Users/chris/gaming/gam1/tile2.png";
    const img = image.load(filename);
    std.log.debug("img w: {any} h: {any}", .{ img.w, img.h });

    window.before_loop();
    var t: f32 = 0;

    var px: i32 = 0;
    var py: i32 = 0;

    while (window.loop()) {
        const command = parseCommand(window);
        switch (command) {
            Command.up => {
                py -= 1;
            },
            Command.down => {
                py += 1;
            },
            Command.left => {
                px -= 1;
            },
            Command.right => {
                px += 1;
            },
            else => {},
        }

        draw.fill(&screen, 0x0);
        draw.draw_image(&screen, img, px, py);
        // draw.draw_pixel(&window, 10, 20, 0xFFFFFF, 0);
        // draw.draw_text(&window, "hello", 50, 50, 0x00ff00);
        ui.drawTextBox(&screen, "hey, you are finally awake");
        t += 1;

        screen.setPixel(10, 10, 0xFF0000, 0);
        screen.upscale(&screen_upscaled, SCALE);
        blit(screen_upscaled, &window);
        window.sleep();
    }
}
