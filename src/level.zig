const std = @import("std");
const assert = std.debug.assert;
const Image = @import("image.zig").Image;
const con = @import("constants.zig");

// entity is a tagged union of all entity types
// types: NPC, sign, door, item
// has an update function called every frame
const Entity = struct {
    x: i32,
    y: i32,
    sprite: Image,

    pub fn update(self: *Entity) void {
        _ = self;
    }
};

const EntityMap = Image;

pub const Level = struct {
    name: []const u8, // can lookup a static map
    sprite: Image,
    entity_map: EntityMap,

    pub fn from_folder(path: []const u8, name: []const u8) Level {
        var buf: [256]u8 = undefined;

        const sprite_path = std.fmt.bufPrintZ(&buf, "{s}/sprite.png", .{path}) catch unreachable;
        const sprite = Image.from_file(sprite_path);

        const entity_path = std.fmt.bufPrintZ(&buf, "{s}/entity_map.png", .{path}) catch unreachable;
        const entity_map = EntityMap.from_file(entity_path);
        // TODO assert they are the same size etc

        assert(sprite.w == entity_map.w);
        assert(sprite.h == entity_map.h);

        return .{
            .name = name,
            .sprite = sprite,
            .entity_map = entity_map,
        };
    }

    // populate entity buffer
    pub fn spawn_entities(self: Level) void {
        _ = self;
        // iterate over all non empty squares in the entity map.
        // the entity map contains entity ids in some cells.
        //
    }
};
