const std = @import("std");
const Window = @import("window.zig").Window;

// keys
const W_KEY = 87;
const S_KEY = 83;
const A_KEY = 65;
const D_KEY = 68;
const SPACE_KEY = 32;
const E_KEY = 69;
const B_KEY = 66;

const H_KEY = 72;
const J_KEY = 74;
const K_KEY = 75;
const L_KEY = 76;

// controls
const UP = W_KEY;
const DOWN = S_KEY;
const LEFT = A_KEY;
const RIGHT = D_KEY;
const A = H_KEY;
const B = J_KEY;
const X = K_KEY;
const Y = L_KEY;
const START = E_KEY;

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
    a: ButtonState = .{},
    b: ButtonState = .{},
    x: ButtonState = .{},
    y: ButtonState = .{},
    start: ButtonState = .{},
    up: ButtonState = .{},
    down: ButtonState = .{},
    left: ButtonState = .{},
    right: ButtonState = .{},

    pub const Direction = enum { up, down, left, right };

    pub fn is_any_direction_active(self: Inputs) bool {
        return self.up.is_active() or self.down.is_active() or self.left.is_active() or self.right.is_active();
    }
};

pub fn updateInputs(inputs: *Inputs, window: Window) void {
    // handle directions
    inputs.directions = .{};
    if (window.key(UP)) inputs.directions.insert(.up);
    if (window.key(DOWN)) inputs.directions.insert(.down);
    if (window.key(LEFT)) inputs.directions.insert(.left);
    if (window.key(RIGHT)) inputs.directions.insert(.right);

    // handle button presses
    inputs.a.update(window.key(A));
    inputs.b.update(window.key(B));
    inputs.x.update(window.key(X));
    inputs.y.update(window.key(Y));
    inputs.start.update(window.key(START));
    inputs.up.update(window.key(UP));
    inputs.down.update(window.key(DOWN));
    inputs.left.update(window.key(LEFT));
    inputs.right.update(window.key(RIGHT));
}
