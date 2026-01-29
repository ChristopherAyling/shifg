const std = @import("std");
const Window = @import("window.zig").Window;

const UP = 17;
const DOWN = 18;
const LEFT = 20;
const RIGHT = 19;
const SPACE = 32;
const A = 65;
const B = 66;
const E = 69;

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
};

pub const Inputs = struct {
    directions: std.EnumSet(Direction) = .{},
    a: ButtonState = .{},
    b: ButtonState = .{},
    start: ButtonState = .{},

    pub const Direction = enum { up, down, left, right };
};

pub fn updateInputs(inputs: *Inputs, window: Window) void {
    // handle directions
    inputs.directions = .{};
    if (window.key(UP)) inputs.directions.insert(.up);
    if (window.key(DOWN)) inputs.directions.insert(.down);
    if (window.key(LEFT)) inputs.directions.insert(.left);
    if (window.key(RIGHT)) inputs.directions.insert(.right);

    // handle button presses
    inputs.a.update(window.key(A) or window.key(SPACE));
    inputs.b.update(window.key(B));
    inputs.start.update(window.key(E));
}
