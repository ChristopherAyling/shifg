const MenuState = @import("menus.zig").MenuState;
const ThingPool = @import("things.zig").ThingPool;
const Level = @import("level.zig").Level;

pub const EditorState = struct {
    menu: MenuState = .{},
    things: ThingPool = .{},
    level: ?Level = null,
};
