const std = @import("std");
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const draw = @import("draw.zig");
const image = @import("image.zig");

const TEXTBOX_X = 5;
const TEXTBOX_Y = 99;

const TEXT_COLOR = 0x00FFFF;
const TEXTBOX_COLOR = 0xFFFF00;
const TEXTBOX_WIDTH = 150;
const TEXTBOX_HEIGHT = 40;

pub fn drawTextBox(screen: *ScreenBuffer, text: []const u8) void {
    draw.draw_rec(screen, TEXTBOX_X, TEXTBOX_Y, TEXTBOX_X + TEXTBOX_WIDTH, TEXTBOX_Y + TEXTBOX_HEIGHT, TEXTBOX_COLOR, 0x555555);
    draw.draw_text(screen, text, TEXTBOX_X + 5, TEXTBOX_Y + 5, TEXT_COLOR);
}
