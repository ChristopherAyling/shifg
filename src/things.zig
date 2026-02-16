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

    pub fn manhat_dist(self: Thing, x: i32, y: i32) i32 {
        const x_dist: i32 = @intCast(@abs(self.x - x));
        const y_dist: i32 = @intCast(@abs(self.y - y));
        return x_dist + y_dist;
    }
};

const NIL_SLOT = 0;

pub const ThingRef = struct {
    slot: usize,

    pub fn from_slot(slot: usize) ThingRef {
        return .{ .slot = slot };
    }

    pub fn nil() ThingRef {
        return .{ .slot = NIL_SLOT };
    }

    pub fn is_nil(self: ThingRef) bool {
        return self.slot == NIL_SLOT;
    }
};

pub const ThingIterator = struct {
    items: []Thing,
    current_slot: usize = 1,

    pub fn next(self: *ThingIterator) ?*Thing {
        while (self.current_slot < self.items.len) {
            const slot = self.current_slot;
            self.current_slot += 1;
            return &self.items[slot];
        }
        return null;
    }

    pub fn next_active_near(self: *ThingIterator, x: i32, y: i32, thresh: i32) ?*Thing {
        if (self.next_active()) |thing| {
            if (thing.manhat_dist(x, y) < thresh) return thing;
        }
        return null;
    }

    pub fn next_active_kind(self: *ThingIterator, kind: Kind) ?*Thing {
        if (self.next_active()) |thing| {
            if (thing.kind == kind) return thing;
        }
        return null;
    }

    pub fn next_active(self: *ThingIterator) ?*Thing {
        while (self.current_slot < self.items.len) {
            const slot = self.current_slot;
            self.current_slot += 1;
            if (self.items[slot].active) return &self.items[slot];
        }
        return null;
    }
};

pub const ThingRefIterator = struct {
    items: []Thing,
    current_slot: usize = 1,

    pub fn next(self: *ThingRefIterator) ?ThingRef {
        while (self.current_slot < self.items.len) {
            const slot = self.current_slot;
            self.current_slot += 1;
            return ThingRef.from_slot(slot);
        }
        return null;
    }

    pub fn next_active_kind(self: *ThingRefIterator, kind: Kind) ?ThingRef {
        while (self.current_slot < self.items.len) {
            const slot = self.current_slot;
            self.current_slot += 1;
            if (self.items[slot].active and self.items[slot].kind == kind) return ThingRef.from_slot(slot);
        }
        return null;
    }

    pub fn next_active(self: *ThingRefIterator) ?ThingRef {
        while (self.current_slot < self.items.len) {
            const slot = self.current_slot;
            self.current_slot += 1;
            if (self.items[slot].active) return ThingRef.from_slot(slot);
        }
        return null;
    }
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

    pub fn get_or_null(self: *ThingPool, ref: ThingRef) ?*Thing {
        if (ref.is_nil()) return null;
        return &self.things[ref.slot];
    }

    pub fn get_nil_ref() ThingRef {
        return ThingRef.nil();
    }

    pub fn get_nil(self: *ThingPool) *Thing {
        return &self.things[NIL_SLOT];
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

    pub fn iter(self: *ThingPool) ThingIterator {
        return .{ .items = &self.things };
    }

    pub fn iter_ref(self: *ThingPool) ThingRefIterator {
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
