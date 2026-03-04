const std = @import("std");
const assert = @import("std").debug.assert;
const dialogue = @import("dialogue.zig");
const ThingRef = @import("things.zig").ThingRef;
const SpriteKey = @import("sprites.zig").SpriteKey;

pub const Screen = union(enum) {
    // game only
    context: ContextMenuState,
    inventory: InventoryState,

    // shared
    action: ActionMenuState,
    dialogue: DialogueMenuState,
    examine: ExaminationMenuState,

    // editor only
    editor_place: EditorPlaceMenuState,
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

// editor only

const MAX_LABEL_LEN = 64;

const Label = struct {
    data: [MAX_LABEL_LEN]u8,
    len: usize,

    pub fn init(src: []const u8) Label {
        assert(src.len < MAX_LABEL_LEN);
        var label: Label = .{ .data = undefined, .len = src.len };
        @memcpy(label.data[0..src.len], src);
        return label;
    }

    pub fn get(self: *const Label) []const u8 {
        return self.data[0..self.len];
    }
};

const Item = struct {
    label: ?Label,
    icon: ?SpriteKey,
};

const MAX_ITEM_LIST_LEN = 10;

pub const ItemList = struct {
    items: [MAX_ITEM_LIST_LEN]Item = undefined,
    count: usize = 0,

    pub fn init() ItemList {
        return .{};
    }

    pub fn add(self: *ItemList, label: []const u8) void {
        assert(self.count < MAX_ITEM_LIST_LEN);
        self.items[self.count] = .{ .label = Label.init(label), .icon = null };
        self.count += 1;
    }

    pub fn max_index(self: ItemList) usize {
        return self.count -| 1;
    }

    pub fn get(self: ItemList, index: usize) Item {
        return self.items[index];
    }

    pub fn longest_label(self: ItemList) usize {
        var longest: usize = 0;
        for (0..self.count) |i| {
            if (self.items[i].label) |label| longest = @max(label.len, longest);
        }
        return longest;
    }
};

pub const NamedItemList = struct {
    name: Label,
    item_list: ItemList,

    pub fn init(name: []const u8) NamedItemList {
        return .{
            .name = Label.init(name),
            .item_list = ItemList.init(),
        };
    }

    pub fn add(self: *NamedItemList, label: []const u8) void {
        self.item_list.add(label);
    }

    pub fn max_index(self: NamedItemList) usize {
        return self.item_list.max_index();
    }

    pub fn get(self: NamedItemList, index: usize) Item {
        return self.item_list.get(index);
    }
};

const MAX_ITEM_LIST_COLLECTION_LEN = 10;

pub const NamedItemListCollection = struct {
    named_item_lists: [MAX_ITEM_LIST_COLLECTION_LEN]NamedItemList = undefined,
    count: usize = 0,

    pub fn init() NamedItemListCollection {
        return .{};
    }

    pub fn add(self: *NamedItemListCollection, named_item_list: NamedItemList) void {
        assert(self.count < MAX_ITEM_LIST_COLLECTION_LEN);
        self.named_item_lists[self.count] = named_item_list;
        self.count += 1;
    }

    pub fn max_index(self: NamedItemListCollection) usize {
        return self.count -| 1;
    }

    pub fn get(self: NamedItemListCollection, index: usize) NamedItemList {
        return self.named_item_lists[index];
    }
};

pub const EditorPlaceMenuState = struct {
    // categories to place: npcs, items, player etc
    category: usize,
    index: usize,
    categories: NamedItemListCollection,

    pub fn init(categories: NamedItemListCollection) EditorPlaceMenuState {
        return .{
            .category = 0,
            .index = 0,
            .categories = categories,
        };
    }

    fn max_index(self: *EditorPlaceMenuState) usize {
        return self.categories.get(self.category).max_index();
    }

    fn legalise_index(self: *EditorPlaceMenuState) void {
        self.index = @min(self.index, self.max_index());
    }

    fn legalise_category(self: *EditorPlaceMenuState) void {
        self.category = @min(self.category, self.categories.max_index());
    }

    pub fn next_category(self: *EditorPlaceMenuState) void {
        std.log.debug("next cat", .{});
        self.category +|= 1;
        self.legalise_category();
        self.legalise_index();
    }

    pub fn prev_category(self: *EditorPlaceMenuState) void {
        std.log.debug("prev cat", .{});
        self.category -|= 1;
        self.legalise_index();
    }

    pub fn inc(self: *EditorPlaceMenuState) void {
        std.log.debug("inc", .{});
        self.index +|= 1;
        self.legalise_index();
    }

    pub fn dec(self: *EditorPlaceMenuState) void {
        std.log.debug("dec", .{});
        self.index -|= 1;
    }
};
