const std = @import("std");
const Allocator = std.mem.Allocator;

const c = @cImport({
    @cInclude("fenster.c");
});

pub const Window = struct {
    f: c.fenster,
    id_buffer: []u32,
    w: u32,
    h: u32,
    debug: bool = true,
    fps: u32 = 60,
    pub fn init(allocator: Allocator, w: u32, h: u32) !Window {
        var buf = try allocator.alloc(u32, w * h);
        const id_buffer = try allocator.alloc(u32, w * h);
        const f = std.mem.zeroInit(c.fenster, .{
            .width = @as(c_int, @intCast(w)), //fmt
            .height = @as(c_int, @intCast(h)),
            .title = "game",
            .buf = &buf[0],
        });
        return Window{ .f = f, .w = w, .h = h, .id_buffer = id_buffer };
    }

    pub fn deinit(self: *Window) void {
        c.fenster_close(&self.f);
    }

    pub fn sleep(self: *Window, duration: i64) void {
        _ = self;
        c.fenster_sleep(duration);
    }

    pub fn before_loop(self: *Window) void {
        _ = c.fenster_open(&self.f);
    }

    pub fn loop(self: *Window) bool {
        return c.fenster_loop(&self.f) == 0;
    }

    pub fn set_pixel(self: *Window, x: u32, y: u32, color: u32) void {
        if (x >= self.w or y >= self.h) return;
        self.f.buf[y * self.w + x] = color;
    }

    pub fn set_id(self: *Window, x: u32, y: u32, id: u32) void {
        if (x >= self.w or y >= self.h) return;
        self.id_buffer[y * self.w + x] = id;
    }

    pub fn get_id(self: *Window, x: u32, y: u32) u32 {
        return self.id_buffer[y * self.w + x];
    }

    pub fn key(self: Window, k: usize) bool {
        return self.f.keys[k] != 0;
    }
};
