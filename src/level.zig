const std = @import("std");
const assert = std.debug.assert;
const Image = @import("image.zig").Image;
const con = @import("constants.zig");
const entity = @import("entity.zig");
const Npc = entity.Npc;
const Item = entity.Item;
const dialogue = @import("dialogue.zig");
const audio = @import("audio.zig");

// entity is a tagged union of all entity types
// types: NPC, sign, door, item
// has an update function called every frame

// const EntityMap = Image; // u32: spritekey|spritekey|dialoguekey|dialoguekey. 16b keys for each. also don't need to use 8bit sections

pub const Level = struct {
    name: []const u8, // can lookup a static map
    bg: Image,
    fg: Image,
    music: audio.MusicTrack,

    pub fn from_folder(path: []const u8, name: []const u8) Level {
        var buf: [256]u8 = undefined;

        const bg_path = std.fmt.bufPrintZ(&buf, "{s}/bg.png", .{path}) catch unreachable;
        const bg = Image.from_file(bg_path);

        const fg_path = std.fmt.bufPrintZ(&buf, "{s}/fg.png", .{path}) catch unreachable;
        const fg = Image.from_file(fg_path);

        // const entity_path = std.fmt.bufPrintZ(&buf, "{s}/entities.shif", .{path}) catch unreachable;
        // _ = entity_path;
        // const entity_map = EntityMap.from_file(entity_path);
        // TODO assert they are the same size etc

        return .{
            .name = name,
            .bg = bg,
            .fg = fg,
            .music = undefined,
        };
    }

    // populate entity buffer
    pub fn load_entities(self: Level, npcs: []Npc) void {
        _ = self;
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
