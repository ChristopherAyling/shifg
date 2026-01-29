pub const StoryCheckpoint = enum {
    // completely determines what is loaded
    game_start,
    prologue_complete,
    tutorial_complete,

    pub fn isAtLeast(self: StoryCheckpoint, other: StoryCheckpoint) bool {
        return @intFromEnum(self) >= @intFromEnum(other);
    }
};
