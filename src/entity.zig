const DialogueSequence = @import("dialogue.zig").DialogueSequence;
const sprites = @import("sprites.zig");
// array per entity type
// 1000 each
// active flags

// npcs

pub const Npc = struct {
    active: bool = false,
    spritekey: sprites.SpriteKey = .missing,
    name: []const u8 = "",
    x: i32 = 0,
    y: i32 = 0,
    dialogue: DialogueSequence = undefined,
};

// items

pub const Item = struct {
    active: bool = false,
    spritekey: sprites.SpriteKey = .missing,
    name: []const u8 = "",
    x: i32 = 0,
    y: i32 = 0,
};
