const Image = @import("image.zig").Image;

pub const SpriteKey = enum {
    // misc
    missing,
    splash,
    // characters
    estraven,
    genly,
    argaven,
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
        self.images[@intFromEnum(SpriteKey.missing)] = Image.from_file("assets/missing.png");
        self.images[@intFromEnum(SpriteKey.splash)] = Image.from_file("assets/splash.png");
        self.images[@intFromEnum(SpriteKey.estraven)] = Image.from_file("assets/estraven.png");
        self.images[@intFromEnum(SpriteKey.genly)] = Image.from_file("assets/genly.png");
        self.images[@intFromEnum(SpriteKey.argaven)] = Image.from_file("assets/argaven.png");
    }
};
