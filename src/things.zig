const std = @import("std");
const assert = @import("std").debug.assert;
const sprites = @import("sprites.zig");

pub const Kind = enum {
    UNSET,
    NPC,
    ITEM,
    DOOR,
    PLAYER,
    CAMERA,
    SELECTOR,
    PORTAL,
};

pub const InteractionMode = enum {
    NORMAL,
    SELECT,
};

pub const QueryOptions = struct {
    kind: ?Kind = null,
    active: ?bool = true,
    visible: ?bool = null,
    position: ?struct { x: i32, y: i32, thresh: i32 } = null,
    selectable: ?bool = null,

    pub fn selectable_near(x: i32, y: i32) QueryOptions {
        return .{
            .active = true,
            .selectable = true,
            .position = .{
                .x = x,
                .y = y,
                .thresh = 8,
            },
        };
    }

    pub fn matches(self: QueryOptions, thing: Thing) bool {
        if (self.kind) |kind| {
            if (thing.kind != kind) return false;
        }
        if (self.active) |active| {
            if (thing.active != active) return false;
        }
        if (self.visible) |visible| {
            if (thing.visible != visible) return false;
        }
        if (self.selectable) |selectable| {
            if (thing.selectable != selectable) return false;
        }
        if (self.position) |position| {
            if (@as(i32, @intFromFloat(thing.euclid_dist(position.x, position.y))) > position.thresh) return false;
        }
        return true;
    }
};

pub const PortalDest = struct {
    level_name: ?[64]u8 = null, // if null, refers to current level
    x: i32,
    y: i32,
};

pub const Thing = struct {
    active: bool = false, // is an active entity
    spritekey: sprites.SpriteKey = .missing, // what sprite to load to represent it
    visible: bool = true, // if the sprite should be loaded
    kind: Kind = .UNSET, // thing kind
    name: [64:0]u8 = .{0} ** 64,
    x: i32 = 0,
    y: i32 = 0,
    selectable: bool = false,

    // moving entity specific
    movement: u32 = 0,
    max_movement: u32 = 50,

    // player specific
    camera_ref: ThingRef = ThingRef.nil(), // associated camera
    selector_ref: ThingRef = ThingRef.nil(), // associated selector
    interaction_mode: InteractionMode = .NORMAL,

    // selector specific
    selection_target_ref: ThingRef = ThingRef.nil(), // associated selector

    // portal specific
    portal_dest: PortalDest = undefined,

    // TODO add traits bitset

    pub fn manhat_dist(self: Thing, x: i32, y: i32) i32 {
        const x_dist: i32 = @intCast(@abs(self.x - x));
        const y_dist: i32 = @intCast(@abs(self.y - y));
        return x_dist + y_dist;
    }

    pub fn euclid_dist(self: Thing, x: i32, y: i32) f64 {
        const dx: f64 = @floatFromInt(self.x - x);
        const dy: f64 = @floatFromInt(self.y - y);
        return @sqrt(dx * dx + dy * dy);
    }
};

const MAX_THINGS = 1000;
const NIL_SLOT = 0;

pub const ThingRef = struct {
    slot: u32,
    gen: u32,

    pub fn init(slot: u32, gen: u32) ThingRef {
        return .{ .slot = slot, .gen = gen };
    }

    pub fn nil() ThingRef {
        return .{ .slot = NIL_SLOT, .gen = 0 };
    }

    pub fn is_nil(self: ThingRef) bool {
        return self.slot == NIL_SLOT;
    }
};

pub const ThingIterator = struct {
    pool: *ThingPool,
    current_slot: u32 = 1,

    pub fn next(self: *ThingIterator) ?*Thing {
        while (self.current_slot < self.pool.len) {
            const slot = self.current_slot;
            self.current_slot += 1;
            return &self.pool.things[slot];
        }
        return null;
    }

    pub fn next_match(self: *ThingIterator, q: QueryOptions) ?*Thing {
        while (self.next()) |thing| {
            if (q.matches(thing.*)) return thing;
        }
        return null;
    }

    pub fn next_active_near(self: *ThingIterator, x: i32, y: i32, thresh: i32) ?*Thing {
        const q: QueryOptions = .{
            .active = true,
            .position = .{ .x = x, .y = y, .thresh = thresh },
        };
        if (self.next_match(q)) |thing| return thing;
        return null;
    }

    pub fn next_active_kind(self: *ThingIterator, kind: Kind) ?*Thing {
        const q: QueryOptions = .{
            .active = true,
            .kind = kind,
        };
        if (self.next_match(q)) |thing| return thing;
        return null;
    }

    pub fn next_active(self: *ThingIterator) ?*Thing {
        const q: QueryOptions = .{
            .active = true,
        };
        if (self.next_match(q)) |thing| return thing;
        return null;
    }
};

pub const ThingRefIterator = struct {
    pool: *ThingPool,
    current_slot: u32 = 1,

    pub fn next(self: *ThingRefIterator) ?ThingRef {
        while (self.current_slot < self.pool.len) {
            const slot = self.current_slot;
            self.current_slot += 1;
            return ThingRef.init(slot, self.pool.gens[slot]);
        }
        return null;
    }

    pub fn next_match(self: *ThingRefIterator, q: QueryOptions) ?ThingRef {
        while (self.next()) |ref| {
            if (q.matches(self.pool.things[ref.slot])) return ref;
        }
        return null;
    }

    pub fn next_active_kind(self: *ThingRefIterator, kind: Kind) ?ThingRef {
        const q: QueryOptions = .{
            .active = true,
            .kind = kind,
        };
        if (self.next_match(q)) |thing| return thing;
        return null;
    }

    pub fn next_active(self: *ThingRefIterator) ?ThingRef {
        const q: QueryOptions = .{
            .active = true,
        };
        if (self.next_match(q)) |thing| return thing;
        return null;
    }
};

pub const ThingPool = struct {
    things: [MAX_THINGS]Thing = .{Thing{}} ** MAX_THINGS,
    gens: [MAX_THINGS]u32 = .{0} ** MAX_THINGS,
    nextFreeSlot: u32 = 1, // TODO use a freelist
    len: u32 = MAX_THINGS,

    pub fn get_player(self: *ThingPool) *Thing {
        var it = self.iter();
        if (it.next_active_kind(.PLAYER)) |player| {
            return player;
        }
        unreachable;
        // return self.get_nil();
    }

    pub fn from_file(self: *ThingPool, path: []const u8) void {
        const file = std.fs.openFileAbsolute(path, .{}) catch return;
        defer file.close();
        _ = file.readAll(std.mem.asBytes(self)) catch unreachable;
    }

    pub fn to_file(self: *ThingPool, path: []const u8) void {
        const file = std.fs.createFileAbsolute(path, .{ .truncate = true }) catch unreachable;
        defer file.close();
        file.writeAll(std.mem.asBytes(self)) catch unreachable;
    }

    pub fn reset(self: *ThingPool) void {
        var it = self.iter();
        while (it.next()) |item| {
            item.active = false;
        }
    }

    pub fn get(self: *ThingPool, ref: ThingRef) *Thing {
        if (ref.slot >= MAX_THINGS) return self.get_nil(); // slot in bounds
        if (self.gens[ref.slot] != ref.gen) return self.get_nil(); // slot correct generation
        const thing = &self.things[ref.slot];
        if (!thing.active) return self.get_nil(); // guard against inactive access
        return thing;
    }

    pub fn get_or_null(self: *ThingPool, ref: ThingRef) ?*Thing {
        // function exists to play nicely with zig null checking
        if (ref.is_nil()) return null;
        if (self.gens[ref.slot] != ref.gen) return null;
        const thing = self.get(ref);
        if (!thing.active) return null;
        return thing;
    }

    pub fn get_nil_ref() ThingRef {
        return ThingRef.nil();
    }

    pub fn get_nil(self: *ThingPool) *Thing {
        return &self.things[NIL_SLOT];
    }

    // constructors

    pub fn add(self: *ThingPool, kind: Kind) ThingRef {
        // anything being added must be through this function!!!! handles free slots and generations.
        self.things[self.nextFreeSlot] = .{
            .kind = kind,
            .active = true,
        };
        const new_slot = self.nextFreeSlot;
        self.gens[new_slot] += 1;
        const ref: ThingRef = .{ .slot = new_slot, .gen = self.gens[new_slot] };
        self.nextFreeSlot += 1;
        return ref;
    }

    pub fn add_npc(self: *ThingPool, spritekey: sprites.SpriteKey, x: i32, y: i32) ThingRef {
        const ref = self.add(.NPC);
        const thing = self.get(ref);
        thing.spritekey = spritekey;
        thing.x = x;
        thing.y = y;
        thing.selectable = true;
        return ref;
    }

    pub fn add_player(self: *ThingPool, spritekey: sprites.SpriteKey, x: i32, y: i32) ThingRef {
        const ref = self.add(.PLAYER);
        const thing = self.get(ref);
        thing.spritekey = spritekey;
        thing.x = x;
        thing.y = y;
        thing.selectable = true;

        thing.camera_ref = self.add_camera(x, y);
        thing.selector_ref = self.add_selector(x, y);

        thing.interaction_mode = .NORMAL;

        return ref;
    }

    pub fn add_camera(self: *ThingPool, x: i32, y: i32) ThingRef {
        const ref = self.add(.CAMERA);
        const thing = self.get(ref);
        thing.spritekey = .camera;
        thing.x = x;
        thing.y = y;
        thing.visible = false;
        return ref;
    }

    pub fn add_selector(self: *ThingPool, x: i32, y: i32) ThingRef {
        const ref = self.add(.SELECTOR);
        const thing = self.get(ref);
        thing.spritekey = .selector;
        thing.x = x;
        thing.y = y;
        thing.visible = false;
        return ref;
    }

    pub fn add_item(self: *ThingPool, spritekey: sprites.SpriteKey, x: i32, y: i32) ThingRef {
        const ref = self.add(.ITEM);
        const thing = self.get(ref);
        thing.spritekey = spritekey;
        thing.x = x;
        thing.y = y;
        thing.selectable = true;
        return ref;
    }

    pub fn add_portal(self: *ThingPool, x: i32, y: i32, dest: PortalDest) ThingRef {
        const ref = self.add(.PORTAL);
        const thing = self.get(ref);
        thing.spritekey = .portal_source;
        thing.x = x;
        thing.y = y;
        thing.visible = false;
        thing.portal_dest = dest;
        return ref;
    }

    pub fn iter(self: *ThingPool) ThingIterator {
        return .{ .pool = self };
    }

    pub fn iter_ref(self: *ThingPool) ThingRefIterator {
        return .{ .pool = self };
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
