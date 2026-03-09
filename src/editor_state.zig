const MenuState = @import("menus.zig").MenuState;
const ThingPool = @import("things.zig").ThingPool;
const Level = @import("level.zig").Level;

pub const EditorState = struct {
    menu: MenuState = .{},
    things: ThingPool = .{},
    level: ?Level = null,
    portal_dest_level: ?Level = null,
    cursor_x: i32 = 0,
    cursor_y: i32 = 0,
    camera_x: i32 = 0,
    camera_y: i32 = 0,
};
