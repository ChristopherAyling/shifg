const std = @import("std");
const assert = std.debug.assert;
const Image = @import("image.zig").Image;
const con = @import("constants.zig");
const entity = @import("entity.zig");
const Npc = entity.Npc;
const Item = entity.Item;
const dialogue = @import("dialogue.zig");

// entity is a tagged union of all entity types
// types: NPC, sign, door, item
// has an update function called every frame

const EntityMap = Image; // u32: spritekey|spritekey|dialoguekey|dialoguekey. 16b keys for each. also don't need to use 8bit sections

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
    pub fn load_entities(self: Level, npcs: []Npc) void {
        _ = self;
        // mark all existing entities as inactive
        for (npcs) |*npc| {
            npc.active = false;
        }
        // iterate over all non empty squares in the entity map.
        // the entity map contains entity ids in some cells.
        // npcs
        npcs[0] = Npc{
            .active = true,
            .spritekey = .argaven,
            .x = 230,
            .y = 270,
            .dialogue = dialogue.PARADE_ARGAVEN,
        };

        npcs[1] = Npc{
            .active = true,
            .spritekey = .estraven,
            .x = 220,
            .y = 270,
            .dialogue = dialogue.PARADE_ESTRAVEN,
        };
        // items
    }
};
