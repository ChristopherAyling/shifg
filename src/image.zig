const std = @import("std");

pub const Image = struct {
    data: []const u32,
    w: i32,
    h: i32,
};
