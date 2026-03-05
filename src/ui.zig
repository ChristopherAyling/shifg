const std = @import("std");
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const draw = @import("draw.zig");
const Image = @import("image.zig").Image;
const con = @import("constants.zig");
const sprites = @import("sprites.zig");

pub const ContextMenuItem = struct {
    label: []const u8,
    // sprite: sprites.SpriteKey = .missing,
};

pub const ContextMenuItems = struct {
    items: [4]?ContextMenuItem = .{null} ** 4,
    count: usize = 0,

    pub fn add(self: *ContextMenuItems, label: []const u8) void {
        if (self.count < 4) {
            self.items[self.count] = .{ .label = label };
            self.count += 1;
        } else {
            @panic("too many items attempted to be added to ContextMenuItems");
        }
    }
};

const PADDING: i32 = 4;

const TEXTBOX_X = 5;
const TEXTBOX_Y = 99;

const TEXT_COLOR = 0x22EEEE;
const TEXTBOX_COLOR = 0x22AA88;
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

pub fn drawTextBox(screen: *ScreenBuffer, speaker: []const u8, text: []const u8) void {
    draw.draw_rec(screen, TEXTBOX_X, TEXTBOX_Y, TEXTBOX_X + TEXTBOX_WIDTH, TEXTBOX_Y + TEXTBOX_HEIGHT, TEXTBOX_COLOR, 0x555555);
    draw.draw_text(screen, speaker, TEXTBOX_X + 3, TEXTBOX_Y + 3, 0xFFFFFF);
    draw.draw_text(screen, text, TEXTBOX_X + 5, TEXTBOX_Y + 12, TEXT_COLOR);
}

pub fn draw_context_menu(screen: *ScreenBuffer, x0: i32, y0: i32, idx: usize, items: ContextMenuItems) void {
    const N_LABELS: i32 = @intCast(items.count);

    const MENU_WIDTH = blk: {
        var max: usize = 0;
        for (items.items) |maybe_item| {
            if (maybe_item) |item| {
                if (item.label.len > max) max = item.label.len;
            }
        }
        break :blk max;
    };
    const iMENU_WIDTH: i32 = @intCast(MENU_WIDTH);

    draw.draw_rec(
        screen,
        x0,
        y0,
        x0 + ((con.FONT_W + 1) * iMENU_WIDTH) + (2 * PADDING),
        y0 + (con.FONT_H + PADDING) * N_LABELS + PADDING,
        0x00F0F0,
        0x787276,
    );

    for (0..items.count) |i| {
        if (items.items[i]) |item| {
            const ii: i32 = @intCast(i);
            // TODO put sprite in menu maybe?
            draw.draw_text(
                screen,
                item.label,
                x0 + PADDING,
                y0 + (con.FONT_H + PADDING) * ii + PADDING,
                0xFFF0F0,
            );
        }
    }

    const iidx: i32 = @intCast(idx);
    draw.draw_line(
        screen,
        x0 + PADDING,
        y0 + (con.FONT_H + PADDING) * iidx + PADDING + con.FONT_H,
        x0 + iMENU_WIDTH * (con.FONT_W + 1) + PADDING - 1,
        y0 + (con.FONT_H + PADDING) * iidx + PADDING + con.FONT_H,
        0xFFF000,
    );
}
