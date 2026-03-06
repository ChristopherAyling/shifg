const std = @import("std");
const DialogKey = @import("dialogue.zig").DialogKey;
const SpriteKey = @import("sprites.zig").SpriteKey;

pub const NpcKey = enum {
    Argaven,
    Estraven,
    // candlekeep
    AvowedPriest,

    pub fn get_spritekey(self: NpcKey) SpriteKey {
        return switch (self) {
            .Argaven => .argaven,
            .Estraven => .estraven,
            .AvowedPriest => .avowed_priest,
        };
    }
};

// can extend this in the future to be also keyed by an event / story beat / advancement system
pub const npc_dialog_lookup = init: {
    var map = std.EnumArray(NpcKey, DialogKey).initUndefined();
    map.set(.Argaven, .ParadeArgaven);
    map.set(.Estraven, .ParadeEstraven);
    map.set(.AvowedPriest, .LibraryGateAvowedPriestIntro);
    break :init map;
};
