const Image = @import("image.zig").Image;

pub const SpriteKey = enum {
    // misc
    missing,
    camera,
    splash,
    selector,
    selector_active,
    // characters
    estraven,
    genly,
    argaven,
    // editor
    cursor,
    //items
    redflag,
    potion,

    // action menu
    action_menu_melee,
    action_menu_ranged,
    action_menu_magic,
    action_menu_throw,
    action_menu_hide,
    action_menu_dash,
    action_menu_jump,
    action_menu_shove,
};

pub const SpriteStorage = struct {
    images: [@typeInfo(SpriteKey).@"enum".fields.len]Image,

    pub fn init() SpriteStorage {
        return .{
            .images = undefined, // todo initialise with missing texture
        };
    }

    pub fn get(self: *SpriteStorage, key: SpriteKey) Image {
        return self.images[@intFromEnum(key)];
    }
};
