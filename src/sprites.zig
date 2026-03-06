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
    avowed_priest,

    // editor
    cursor,
    //items
    redflag,
    potion,
    // portals
    portal_source,
    portal_dest,
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
