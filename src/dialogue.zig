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
        .{ .speaker_name = "Narrator", .text = "hey" },
        .{ .speaker_name = "Narrator", .text = "you are finally awake.\nThere is much you should know." },
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
