// structs
const std = @import("std");
const assert = std.debug.assert;
const StoryCheckpoint = @import("story.zig").StoryCheckpoint;

pub const DialogueLine = struct {
    speaker_name: []const u8,
    text: []const u8,
};

pub const DialogueSequence = struct {
    id: u32,
    lines: []const DialogueLine,
    jump_to_story_checkpoint: ?StoryCheckpoint = null,
};

// sequences

pub const PROLOGUE = DialogueSequence{
    .id = 0,
    .lines = &[_]DialogueLine{
        .{ .speaker_name = "you", .text = "i'll make my reports as if i told a\nstory," },
        .{ .speaker_name = "you", .text = "for i was taught as a child on my\nhomeworld that truth is a matter\nof imagination." },
        .{ .speaker_name = "you", .text = "the soundest of fact may fail or\nprevail in the style of its telling:" },
        .{ .speaker_name = "you", .text = "like that singular organic jewel\nof our seas," },
        .{ .speaker_name = "you", .text = "which grows brighter as one woman\nwears it and," },
        .{ .speaker_name = "you", .text = "worn by another, dulls and goes to\ndust." },
        .{ .speaker_name = "you", .text = "facts are no more solid, coherent,\nround, and real than pearls are." },
        .{ .speaker_name = "you", .text = "but both are sensitive." },
    },
    .jump_to_story_checkpoint = .prologue_complete,
};

pub const PARADE_ARGAVEN = DialogueSequence{
    .id = 0,
    .lines = &[_]DialogueLine{
        .{ .speaker_name = "Argaven:", .text = "i am argaven" },
    },
};

pub const PARADE_ESTRAVEN = DialogueSequence{
    .id = 0,
    .lines = &[_]DialogueLine{
        .{ .speaker_name = "Estraven:", .text = "I am a future traitor" },
    },
};

pub const TUTORIAL = DialogueSequence{
    .id = 0,
    .lines = &[_]DialogueLine{
        .{ .speaker_name = "Narrator", .text = "like a gameboy" },
        .{ .speaker_name = "Narrator", .text = "arrow keys, a, b, e=start" },
    },
};

// TODO probably have some lookup like system like with sprites

pub const MISSING = DialogueSequence{
    .id = 0,
    .lines = &[_]DialogueLine{
        .{ .speaker_name = "past you:", .text = "knock knock" },
        .{ .speaker_name = "past you:", .text = "interupting cow" },
        .{ .speaker_name = "past you:", .text = "moo" },
    },
};

pub const DialogueState = struct {
    dialogue_index: usize = 0,
    dialogue: *const DialogueSequence,

    pub fn init(seq: *const DialogueSequence) DialogueState {
        return .{
            .dialogue_index = 0,
            .dialogue = seq,
        };
    }

    pub fn getLine(self: DialogueState) DialogueLine {
        assert(self.dialogue_index < self.dialogue.lines.len);
        return self.dialogue.lines[self.dialogue_index];
    }

    pub fn advance(self: *DialogueState) void {
        self.dialogue_index += 1;
    }

    pub fn is_complete(self: DialogueState) bool {
        return self.dialogue_index >= self.dialogue.lines.len;
    }
};

// TODO have dialogues be looked up by keys
