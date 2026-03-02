const std = @import("std");

extern "env" fn log_write(ptr: [*]const u8, len: usize) void;

pub const std_options: std.Options = .{
    .logFn = customLog,
};

fn customLog(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    _ = message_level;
    _ = scope;
    var buf: [4096]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, format, args) catch return;
    log_write(msg.ptr, msg.len);
}
export fn yo() void {
    std.log.debug("yo", .{});
}

export fn frame() void {
    std.log.debug("frame start", .{});
    std.log.debug("frame end", .{});
}

pub fn main() void {
    // std.log.debug("yo", .{});
}
