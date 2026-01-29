const assert = @import("std").debug.assert;
const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn make_color(r: u8, g: u8, b: u8, a: u8) u32 {
    // 0 alpha is fully transparent
    // 255 alpha is fully opaque
    const rc: u32 = @intCast(r);
    const gc: u32 = @intCast(g);
    const bc: u32 = @intCast(b);
    const ac: u32 = @intCast(a);
    return (rc << 24) | (gc << 16) | (bc << 8) | ac;
}

pub const ScreenBuffer = struct {
    data: []u32, // 4x8bit channels
    w: i32,
    h: i32,

    pub fn init(allocator: Allocator, w: i32, h: i32) !ScreenBuffer {
        return .{
            .data = try allocator.alloc(u32, @intCast(w * h)),
            .w = w,
            .h = h,
        };
    }

    pub fn is_in_bounds(self: *ScreenBuffer, x: i32, y: i32) bool {
        return (x >= 0 and y >= 0 and x < self.w and y < self.h);
    }

    fn getPixelOffset(self: *ScreenBuffer, x: i32, y: i32) usize {
        return @intCast(y * self.w + x);
    }

    pub fn setPixel(self: *ScreenBuffer, x: i32, y: i32, color: u32) void {
        const offset = self.getPixelOffset(x, y);
        self.data[offset] = color;
    }

    pub fn getPixel(self: *ScreenBuffer, x: i32, y: i32) u32 {
        const offset = self.getPixelOffset(x, y);
        return self.data[offset];
    }

    pub fn add_fg(self: *ScreenBuffer, fg: *ScreenBuffer) void {
        // alpha blend every component
        assert(self.w == fg.w);
        assert(self.h == fg.h);
        for (0..@intCast(self.w)) |x| {
            for (0..@intCast(self.h)) |y| {
                const xu: usize = @intCast(x);
                const yu: usize = @intCast(y);
                const bg_pixel = self.getPixel(xu, yu);
                const fg_pixel = fg.getPixel(xu, yu);
                const new_pixel = alphaBlend(fg_pixel, bg_pixel);
                self.setPixel(x, y, new_pixel);
            }
        }
    }

    pub fn upscale(self: *ScreenBuffer, out: *ScreenBuffer, scale: i32) void {
        assert(self.w * scale == out.w);
        assert(self.h * scale == out.h);

        const scale_u: usize = @intCast(scale);

        for (0..@intCast(out.w)) |ox| {
            for (0..@intCast(out.h)) |oy| {
                // divide by scale and floor down
                const uix = ox / scale_u;
                const uiy = oy / scale_u;

                const source_pixel = self.getPixel(@intCast(uix), @intCast(uiy));
                out.setPixel(@intCast(ox), @intCast(oy), source_pixel);
            }
        }
    }
};

pub fn alphaBlend(fg: u32, bg: u32) u32 {
    // Extract components
    const fg_r = (fg >> 24) & 0xFF;
    const fg_g = (fg >> 16) & 0xFF;
    const fg_b = (fg >> 8) & 0xFF;
    const fg_a = fg & 0xFF;

    const bg_r = (bg >> 24) & 0xFF;
    const bg_g = (bg >> 16) & 0xFF;
    const bg_b = (bg >> 8) & 0xFF;
    const bg_a = bg & 0xFF;

    // Blend: out = fg * fg_a + bg * (1 - fg_a)
    // Using 255 as the max alpha value
    const inv_a = 255 - fg_a;

    const out_r = (fg_r * fg_a + bg_r * inv_a) / 255;
    const out_g = (fg_g * fg_a + bg_g * inv_a) / 255;
    const out_b = (fg_b * fg_a + bg_b * inv_a) / 255;

    // For output alpha: out_a = fg_a + bg_a * (1 - fg_a)
    const out_a = fg_a + (bg_a * inv_a) / 255;

    return (out_r << 24) | (out_g << 16) | (out_b << 8) | out_a;
}
