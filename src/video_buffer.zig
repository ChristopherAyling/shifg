const Pixel = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

const ScreenBuffer = struct {
    // Can have multiple of these and compose them into the main layer
    // then upscale and render with fenster.
    data: []u8,
    w: i32,
    h: i32,

    fn getPixelOffset(self: *ScreenBuffer, x: i32, y: i32) usize {
        return y * self.w + x;
    }

    pub fn setPixel(self: *ScreenBuffer, x: i32, y: i32, color: u32) void {
        const offset = self.getPixelOffset(x, y);
        const components: [4]u8 = @bitCast(color);
        self.data[offset] = components[0];
        self.data[offset + 1] = components[1];
        self.data[offset + 2] = components[2];
        self.data[offset + 3] = components[3];
    }
};
