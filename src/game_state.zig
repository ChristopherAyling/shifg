// shared state between the platform and the game. enables hot reloading.
// if any of these structs change, you will need to reload the whole thing.
const MenuState = @import("menus.zig").MenuState;
const ThingPool = @import("things.zig").ThingPool;
const Level = @import("level.zig").Level;

const GameMode = enum {
    MainMenu,
    Overworld,
};

pub const GameState = struct {
    mode: GameMode = .MainMenu,
    menu: MenuState = .{},
    things: ThingPool = .{},
    level: ?Level = null,
};
