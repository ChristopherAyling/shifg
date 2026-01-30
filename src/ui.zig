const std = @import("std");
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const draw = @import("draw.zig");
const Image = @import("image.zig").Image;

const con = @import("constants.zig");

const TEXTBOX_X = 5;
const TEXTBOX_Y = 99;

const TEXT_COLOR = 0x00FFFF;
const TEXTBOX_COLOR = 0xFFFF00;
const TEXTBOX_WIDTH = 150;
const TEXTBOX_HEIGHT = 40;

pub fn drawSplashText(screen: *ScreenBuffer, splash_sprite: Image) void {
    // draw.draw_rec(screen, TEXTBOX_X, TEXTBOX_Y, TEXTBOX_X + TEXTBOX_WIDTH, TEXTBOX_Y + TEXTBOX_HEIGHT, TEXTBOX_COLOR, 0x555555);
    draw.fill(screen, 0xFFFFFF);
    draw.draw_image(screen, splash_sprite, 0, 0);

    const title = "welcome to shif";
    const subtitle = "press start..";
    draw.draw_text(screen, title, con.NATIVE_W_HALF - (@divFloor(title.len, 2) * (con.FONT_W + 2)), con.NATIVE_H_HALF - 20, 0x00);
    draw.draw_text(screen, subtitle, con.NATIVE_W_HALF - (@divFloor(subtitle.len, 2) * (con.FONT_W + 2)), con.NATIVE_H_HALF + 30, 0x666666);
}

pub fn drawTextBox(screen: *ScreenBuffer, text: []const u8) void {
    draw.draw_rec(screen, TEXTBOX_X, TEXTBOX_Y, TEXTBOX_X + TEXTBOX_WIDTH, TEXTBOX_Y + TEXTBOX_HEIGHT, TEXTBOX_COLOR, 0x555555);
    draw.draw_text(screen, text, TEXTBOX_X + 5, TEXTBOX_Y + 5, TEXT_COLOR);
}
