const std = @import("std");
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const draw = @import("draw.zig");
const Image = @import("image.zig").Image;
const con = @import("constants.zig");

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

pub fn draw_radial_menu(screen: *ScreenBuffer, x0: i32, y0: i32, current: usize, title: []const u8) void {
    const inner_radius = 20;
    const outer_radius = 40;
    const math = std.math;
    const n = 8;

    // Offset by half a slice so items sit at N, NE, E, SE, S, SW, W, NW
    // and dividing lines fall between them
    const slice_angle = (2.0 * math.pi) / @as(f32, n);
    const half_slice = slice_angle / 2.0;

    // Start from -pi/2 (north) so index 0 = up
    const north_offset = -math.pi / 2.0;

    // draw dividing lines between slices
    for (0..n) |i| {
        const angle = north_offset + slice_angle * @as(f32, @floatFromInt(i)) - half_slice;
        const cos_a = math.cos(angle);
        const sin_a = math.sin(angle);
        const ix = x0 + @as(i32, @intFromFloat(cos_a * @as(f32, inner_radius)));
        const iy = y0 + @as(i32, @intFromFloat(sin_a * @as(f32, inner_radius)));
        const ox = x0 + @as(i32, @intFromFloat(cos_a * @as(f32, outer_radius)));
        const oy = y0 + @as(i32, @intFromFloat(sin_a * @as(f32, outer_radius)));
        draw.draw_line(screen, ix, iy, ox, oy, 0xFFFFFF);
    }

    // draw selected slice as donut wedge
    {
        const steps = 8;
        const a0 = north_offset + slice_angle * @as(f32, @floatFromInt(current)) - half_slice;
        const a1 = a0 + slice_angle;

        var points: [(steps + 1) * 2]draw.Point = undefined;

        for (0..steps + 1) |s| {
            const t = a0 + (a1 - a0) * @as(f32, @floatFromInt(s)) / @as(f32, steps);
            points[s] = .{
                .x = x0 + @as(i32, @intFromFloat(math.cos(t) * @as(f32, outer_radius))),
                .y = y0 + @as(i32, @intFromFloat(math.sin(t) * @as(f32, outer_radius))),
            };
        }

        for (0..steps + 1) |s| {
            const t = a1 - (a1 - a0) * @as(f32, @floatFromInt(s)) / @as(f32, steps);
            points[steps + 1 + s] = .{
                .x = x0 + @as(i32, @intFromFloat(math.cos(t) * @as(f32, inner_radius))),
                .y = y0 + @as(i32, @intFromFloat(math.sin(t) * @as(f32, inner_radius))),
            };
        }

        draw.draw_poly(screen, &points, 0xFFFF00, 0x884400);
    }

    // draw title above
    const title_x = x0 - @as(i32, @intCast(title.len * 2));
    draw.draw_text(screen, title, title_x, y0 - outer_radius - 10, 0xFFFFFF);
}

// Direction mapping for WASD input:
// Index: 0=N(W), 1=NE(W+D), 2=E(D), 3=SE(S+D), 4=S(S), 5=SW(S+A), 6=W(A), 7=NW(W+A)
pub fn radial_menu_direction(up: bool, down: bool, left: bool, right: bool) ?usize {
    if (up and !down and !left and !right) return 0; // N
    if (up and !down and !left and right) return 1; // NE
    if (!up and !down and !left and right) return 2; // E
    if (!up and down and !left and right) return 3; // SE
    if (!up and down and !left and !right) return 4; // S
    if (!up and down and left and !right) return 5; // SW
    if (!up and !down and left and !right) return 6; // W
    if (up and !down and left and !right) return 7; // NW
    return null;
}
