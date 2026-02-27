const dialogue = @import("dialogue.zig");
const ThingRef = @import("things.zig").ThingRef;

pub const Screen = union(enum) {
    context: ContextMenuState,
    inventory: InventoryState,
    action: ActionMenuState,
    examine: ExaminationMenuState,
    dialogue: DialogueMenuState,
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

pub const ExaminationMenuState = struct {
    examination_target_ref: ThingRef,
};

pub const ContextMenuState = struct {
    context_target_ref: ThingRef,
    index: usize = 0,
    priority: enum { attack, pick_up, talk, move_to },

    pub fn inc(self: *ContextMenuState) void {
        self.index = @min(self.index + 1, self.max_index());
    }

    pub fn dec(self: *ContextMenuState) void {
        self.index -|= 1;
    }

    pub fn max_index(self: ContextMenuState) usize {
        _ = self;
        return 1;
    }
};
pub const InventoryState = struct {
    index: usize = 0,
};
pub const ActionMenuState = struct {
    // TODO preallocate state for 8 action items.
    index: usize = 0,

    pub fn set(self: *ActionMenuState, index: usize) void {
        if (index > self.max_index()) return;
        self.index = index;
    }

    pub fn max_index(self: ActionMenuState) usize {
        _ = self;
        return 7;
    }
};

pub const DialogueMenuState = struct {
    index: usize = 0,
    sequence: dialogue.DialogueSequence,

    fn max_index(self: DialogueMenuState) usize {
        return self.sequence.lines.len - 1;
    }

    pub fn advance(self: *DialogueMenuState) void {
        self.index = @min(self.index + 1, self.max_index());
    }

    pub fn get_line(self: DialogueMenuState) dialogue.DialogueLine {
        return self.sequence.lines[self.index];
    }

    pub fn is_complete(self: *DialogueMenuState) bool {
        return self.index == self.max_index();
    }
};
