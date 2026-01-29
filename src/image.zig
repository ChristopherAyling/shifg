const std = @import("std");

const c = @cImport({
    @cDefine("STB_IMAGE_IMPLEMENTATION", "1");
    @cDefine("STBI_NO_GIF", "1");
    @cDefine("STBI_NO_HDR", "1");
    @cDefine("STBI_NO_TGA", "1");
    @cDefine("STBI_NO_PSD", "1");
    @cDefine("STBI_NO_PIC", "1");
    @cDefine("STBI_NO_PNM", "1");
    @cInclude("stb_image.h");
});

pub const Image = struct {
    data: []u32,
    w: i32,
    h: i32,
};

pub fn load(filename: [:0]const u8) Image {
    var x: c_int = undefined;
    var y: c_int = undefined;
    var channels_in_file: c_int = undefined;

    const raw = c.stbi_load(filename.ptr, &x, &y, &channels_in_file, 4) orelse {
        std.debug.print("Failed to load image: {s}\n", .{filename});
        @panic("Image load failed");
    };

    const pixels = @as(usize, @intCast(x)) * @as(usize, @intCast(y));
    const data: [*]u32 = @ptrCast(@alignCast(raw));

    return .{ .data = data[0..pixels], .w = @intCast(x), .h = @intCast(y) };
}
