const Image = @import("image.zig").Image;

pub fn load_all_sprites() void {
    var sprites: [4]Image = undefined;
    sprites[0] = Image.from_file("assets/estraven.png");
    sprites[1] = Image.from_file("assets/genly.png");
    sprites[2] = Image.from_file("assets/argaven.png");
}
