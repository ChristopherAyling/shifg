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
    data: []u8,
    w: i32,
    h: i32,
};

pub fn load(filename: [:0]const u8) Image {
    var x: c_int = 0;
    var y: c_int = 0;
    var channels_in_file: c_int = 0;
    const data = c.stbi_load(filename.ptr, &x, &y, &channels_in_file, 3) orelse {
        std.debug.print("Failed to load image: {s}\n", .{filename});
        @panic("Image load failed");
    };
    const len = @as(usize, @intCast(x)) * @as(usize, @intCast(y)) * 3;
    return .{ .data = data[0..len], .w = @as(i32, x), .h = @as(i32, y) };
}
