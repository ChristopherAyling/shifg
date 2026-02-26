const std = @import("std");
const Window = @import("window.zig").Window;

const ButtonState = struct {
    pressed: bool = false,
    held: bool = false,
    released: bool = false,

    pub fn update(self: *ButtonState, is_down: bool) void {
        self.released = false;

        if (is_down) {
            self.pressed = !self.held;
            self.held = true;
        } else {
            self.released = self.held;
            self.pressed = false;
            self.held = false;
        }
    }

    pub fn is_active(self: ButtonState) bool {
        return self.pressed or self.held;
    }
};

pub const Inputs = struct {
    directions: std.EnumSet(Direction) = .{},
    a: ButtonState = .{}, // general "interact button"
    b: ButtonState = .{}, // general "cancel/back button"
    x: ButtonState = .{}, // brings up cursor
    y: ButtonState = .{}, // brings up context menu
    start: ButtonState = .{}, // inventory
    up: ButtonState = .{},
    down: ButtonState = .{},
    left: ButtonState = .{},
    right: ButtonState = .{},

    pub const Direction = enum { up, down, left, right };

    pub fn is_any_direction_active(self: Inputs) bool {
        return self.up.is_active() or self.down.is_active() or self.left.is_active() or self.right.is_active();
    }
};
