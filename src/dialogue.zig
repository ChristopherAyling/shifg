// structs

pub const DialogueLine = struct {
    speaker_name: []const u8,
    text: []const u8,
};

pub const DialogueSequence = struct {
    id: u32,
    lines: []const DialogueLine,
};

// sequences

pub const PROLOGUE = DialogueSequence{
    .id = 0,
    .lines = &[_]DialogueLine{
        .{ .speaker_name = "Narrator", .text = "hey" },
        .{ .speaker_name = "Narrator", .text = "you are finally awake" },
        .{ .speaker_name = "Narrator", .text = "1" },
        .{ .speaker_name = "Narrator", .text = "2" },
        .{ .speaker_name = "Narrator", .text = "3" },
        .{ .speaker_name = "Narrator", .text = "4" },
    },
};

pub const TUTORIAL = DialogueSequence{
    .id = 0,
    .lines = &[_]DialogueLine{
        .{ .speaker_name = "Narrator", .text = "like a gameboy" },
        .{ .speaker_name = "Narrator", .text = "arrow keys, a, b, e=start" },
    },
};
