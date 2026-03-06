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
        .{ .speaker_name = "Argaven:", .text = "i am argaven 2" },
    },
};

pub const PARADE_ESTRAVEN = DialogueSequence{
    .id = 0,
    .lines = &[_]DialogueLine{
        .{ .speaker_name = "Estraven:", .text = "estraven, am I" },
        .{ .speaker_name = "Estraven:", .text = "estraven, am I, 2" },
    },
};

// library

const LIBRARY_GATE_AVOWED_PRIEST_INTRO = DialogueSequence{ .id = 0, .lines = &[_]DialogueLine{
    .{ .speaker_name = "Avowed Priest", .text = "To enter the library," },
    .{ .speaker_name = "Avowed Priest", .text = "you must provide a work\nnot already in the collection" },
} };

// TODO probably have some lookup like system like with sprites

pub const MISSING = DialogueSequence{
    .id = 0,
    .lines = &[_]DialogueLine{
        .{ .speaker_name = "past you:", .text = "knock knock" },
        .{ .speaker_name = "past you:", .text = "interupting cow" },
        .{ .speaker_name = "past you:", .text = "moo" },
    },
};

pub const DialogKey = enum {
    Missing,
    Prologue,
    ParadeArgaven,
    ParadeEstraven,
    LibraryGateAvowedPriestIntro,
};

// pub const DialogLookup = std.EnumArray(DialogKey, DialogueSequence).initUndefined();

pub const dialog_lookup = init: {
    var map = std.EnumArray(DialogKey, DialogueSequence).initUndefined();
    map.set(.Missing, MISSING);
    map.set(.Prologue, PROLOGUE);
    map.set(.ParadeArgaven, PARADE_ARGAVEN);
    map.set(.ParadeEstraven, PARADE_ESTRAVEN);
    map.set(.LibraryGateAvowedPriestIntro, LIBRARY_GATE_AVOWED_PRIEST_INTRO);
    break :init map;
};
