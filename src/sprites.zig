const Image = @import("image.zig").Image;

pub const SpriteKey = enum {
    // misc
    missing,
    camera,
    splash,
    // characters
    estraven,
    genly,
    argaven,
    // editor
    cursor,
    //items
    redflag,
    potion,
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

    pub fn load(self: *SpriteStorage) void {
        // misc
        self.images[@intFromEnum(SpriteKey.missing)] = Image.from_file("assets/missing.png");
        self.images[@intFromEnum(SpriteKey.camera)] = Image.from_file("assets/camera.png");
        self.images[@intFromEnum(SpriteKey.splash)] = Image.from_file("assets/splash.png");

        // players
        self.images[@intFromEnum(SpriteKey.genly)] = Image.from_file("assets/genly.png");

        // npcs
        self.images[@intFromEnum(SpriteKey.estraven)] = Image.from_file("assets/estraven.png");
        self.images[@intFromEnum(SpriteKey.argaven)] = Image.from_file("assets/argaven.png");

        // editor
        self.images[@intFromEnum(SpriteKey.cursor)] = Image.from_file("assets/cursor.png");

        // items
        self.images[@intFromEnum(SpriteKey.redflag)] = Image.from_file("assets/redflag.png");
        self.images[@intFromEnum(SpriteKey.potion)] = Image.from_file("assets/potion.png");
    }
};
