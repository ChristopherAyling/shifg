const std = @import("std");

export fn yo() void {
    std.log.debug("yo", .{});
    std.log.info("yo", .{});
    std.log.warn("yo", .{});
    std.log.err("yo", .{});
}

export fn frame() void {
    std.log.debug("frame start", .{});
    std.log.debug("frame end", .{});
}

pub fn main() void {
    // std.log.debug("yo", .{});
}
