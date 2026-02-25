pub const Screen = union(enum) {
    context: ContextMenuState,
    inventory: InventoryState,
    action: ActionMenuState,
};

const MAX_MENU_DEPTH = 3;

pub const MenuState = struct {
    stack: [MAX_MENU_DEPTH]Screen = undefined,
    depth: u2 = 0,

    pub fn push(self: *MenuState, screen: Screen) void {
        if (self.depth >= MAX_MENU_DEPTH) return;
        self.stack[self.depth] = screen;
        self.depth += 1;
    }

    pub fn pop(self: *MenuState) void {
        self.depth -|= 1;
    }

    pub fn current(self: *MenuState) ?*Screen {
        if (self.depth == 0) return null;
        return &self.stack[self.depth - 1];
    }
};

pub const ContextMenuState = struct {
    index: usize = 0,
};
pub const InventoryState = struct {
    index: usize = 0,
};
pub const ActionMenuState = struct {
    index: usize = 0,
};
