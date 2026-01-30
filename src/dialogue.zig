// structs
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

pub const TUTORIAL = DialogueSequence{
    .id = 0,
    .lines = &[_]DialogueLine{
        .{ .speaker_name = "Narrator", .text = "like a gameboy" },
        .{ .speaker_name = "Narrator", .text = "arrow keys, a, b, e=start" },
    },
};
