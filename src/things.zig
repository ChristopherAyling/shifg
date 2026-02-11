const sprites = @import("sprites.zig");

pub const Kind = enum {
    UNSET,
    NPC,
    ITEM,
};

pub const Thing = struct {
    active: bool = false,
    kind: Kind = .UNSET,
    name: []const u8 = "",
    x: i32 = 0,
    y: i32 = 0,
    spritekey: sprites.SpriteKey = .missing,
    reputation: i32 = 0,
};

pub const ThingIterator = struct {
    items: []const Thing,
    index: usize = 1,

    pub fn next_active(self: *ThingIterator) ?Thing {
        while (self.index < self.items.len) {
            const item = self.items[self.index];
            self.index += 1;
            if (item.active) return item;
        }
        return null;
    }
};

pub const ThingRef = struct {
    idx: usize,
};

pub const Things = struct {
    things: [1000]Thing = .{Thing{}} ** 1000,
    nextFreeSlot: usize = 0,

    pub fn add(self: *Things, kind: Kind) *ThingRef {
        self.things[self.nextFreeSlot] = .{
            .kind = kind,
            .active = true,
        };
        const ptr = &self.things[self.nextFreeSlot];
        self.nextFreeSlot += 1;
        return ptr;
    }

    pub fn iter(self: Things) ThingIterator {
        return .{ .items = self.things };
    }
};
