const ScrollMenuIndex = struct {
    len: usize,
    current: usize = 0,

    pub fn init(len: usize) ScrollMenuIndex {
        return .{
            .len = len,
        };
    }

    pub fn inc(self: *ScrollMenuIndex) void {
        self.current = (self.current + 1) % self.len;
    }

    pub fn dec(self: *ScrollMenuIndex) void {
        self.current = if (self.current == 0) self.len - 1 else self.current - 1;
    }
};

const ScrollMenu = struct {
    index: ScrollMenuIndex,
    labels: []const []const u8,

    pub fn init(labels: []const []const u8) void {
        return .{
            .index = ScrollMenuIndex.init(labels.len),
            .labels = labels,
        };
    }
};
