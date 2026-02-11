const std = @import("std");
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

    pub fn next(self: *ThingIterator) ?Thing {
        while (self.index < self.items.len) {
            const item = self.items[self.index];
            self.index += 1;
            return item;
        }
        return null;
    }

    pub fn next_kind(self: *ThingIterator, kind: Kind) ?Thing {
        while (self.index < self.items.len) {
            const item = self.items[self.index];
            self.index += 1;
            if (item.kind == kind) return item;
        }
        return null;
    }

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
    slot: usize,
};

pub const ThingPool = struct {
    // slot 0 = NIL slot.
    things: [1000]Thing = .{Thing{}} ** 1000,
    nextFreeSlot: usize = 1, // TODO use a freelist

    pub fn reset(self: *ThingPool) void {
        var it = self.iter();
        while (it.next()) |item| {
            item.active = false;
        }
    }

    pub fn get(self: *ThingPool, ref: ThingRef) *Thing {
        return &self.things[ref.slot];
    }

    pub fn add(self: *ThingPool, kind: Kind) ThingRef {
        self.things[self.nextFreeSlot] = .{
            .kind = kind,
            .active = true,
        };
        const ref: ThingRef = .{ .slot = self.nextFreeSlot };
        self.nextFreeSlot += 1;
        return ref;
    }

    pub fn add_npc(self: *ThingPool, spritekey: sprites.SpriteKey, x: i32, y: i32) ThingRef {
        const ref = self.add(.NPC);
        const npc = self.get(ref);
        npc.spritekey = spritekey;
        npc.x = x;
        npc.y = y;
        return ref;
    }

    pub fn iter(self: *const ThingPool) ThingIterator {
        return .{ .items = &self.things };
    }

    pub fn len_active(self: *const ThingPool) usize {
        var count: usize = 0;
        var it = self.iter();
        while (it.next_active()) |_| {
            count += 1;
        }
        return count;
    }

    pub fn dbg(self: *const ThingPool) void {
        std.log.debug("THINGPOOL DBG: len_active: {any}/{any}", .{ self.len_active(), self.things.len });
    }
};
