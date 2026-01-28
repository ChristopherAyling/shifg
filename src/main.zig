const std = @import("std");
const Window = @import("window.zig").Window;
const draw = @import("draw.zig");
const image = @import("image.zig");

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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    var window = try Window.init(allocator, 160, 144);
    defer window.deinit();

    const filename: [:0]const u8 = "/Users/chris/gaming/gam1/gam.png";
    const img = image.load(filename);

    window.before_loop();
    var t: f32 = 0;
    while (window.loop()) {
        const command = parseCommand(window);
        _ = command;
        draw.fill(&window, 0x0);
        draw.draw_image(&window, img, 5, 10);
        draw.draw_pixel(&window, 10, 20, 0xFFFFFF, 0);
        t += 1;
    }
}
