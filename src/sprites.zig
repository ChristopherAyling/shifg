const image = @import("image.zig");

const TRANSPARENT = 0x00000000;
const SKIN = 0xFFDCADFF;
const HAIR = 0x4A3728FF;
const SHIRT = 0x3388EEFF;
const PANTS = 0x445566FF;
const EYES = 0x222222FF;

const PLAYER_SPRITE_DATA = [_]u32{
    // row 0 - hair
    TRANSPARENT, TRANSPARENT, HAIR,  HAIR,  HAIR,        HAIR,  TRANSPARENT, TRANSPARENT,
    // row 1 - head top
    TRANSPARENT, HAIR,        HAIR,  HAIR,  HAIR,        HAIR,  HAIR,        TRANSPARENT,
    // row 2 - eyes
    TRANSPARENT, SKIN,        EYES,  SKIN,  SKIN,        EYES,  SKIN,        TRANSPARENT,
    // row 3 - face
    TRANSPARENT, SKIN,        SKIN,  SKIN,  SKIN,        SKIN,  SKIN,        TRANSPARENT,
    // row 4 - neck
    TRANSPARENT, TRANSPARENT, SKIN,  SKIN,  SKIN,        SKIN,  TRANSPARENT, TRANSPARENT,
    // row 5 - body/arms
    TRANSPARENT, SHIRT,       SHIRT, SHIRT, SHIRT,       SHIRT, SHIRT,       TRANSPARENT,
    // row 6 - waist
    TRANSPARENT, TRANSPARENT, SHIRT, SHIRT, SHIRT,       SHIRT, TRANSPARENT, TRANSPARENT,
    // row 7 - legs
    TRANSPARENT, TRANSPARENT, PANTS, PANTS, TRANSPARENT, PANTS, PANTS,       TRANSPARENT,
};

pub const PLAYER_SPRITE = image.Image{
    .data = &PLAYER_SPRITE_DATA,
    .w = 8,
    .h = 8,
};
