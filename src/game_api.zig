const Inputs = @import("control.zig").Inputs;
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const Level = @import("level.zig").Level;
const SpriteStorage = @import("sprites.zig").SpriteStorage;
const audio = @import("audio.zig");
pub const GameState = @import("game_state.zig").GameState;
const ThingPool = @import("things.zig").ThingPool;

// Memory block passed from platform to DLL
pub const GameMemory = struct {
    state: *GameState,
    is_initialized: bool,
};

// Callbacks so game can request audio without owning AudioSystem
pub const PlatformAPI = struct {
    playSound: *const fn (audio.SfxTrack) void,
    setMusic: *const fn (audio.MusicTrack) void,
    stopMusic: *const fn () void,
    load_level: *const fn ([]const u8) Level,
    load_level_things: *const fn ([]const u8, *ThingPool) void,
};

// Rendering resources owned by platform, passed to DLL
pub const RenderContext = struct {
    screen: *ScreenBuffer,
    level: *ScreenBuffer,
    storage: *SpriteStorage,
};

// Function pointer types for dlsym (use pointers for C-ABI compatibility)
pub const GameStepFn = *const fn (*GameMemory, *const Inputs, *const PlatformAPI) callconv(.c) void;
pub const RenderStepFn = *const fn (*GameMemory, *RenderContext) callconv(.c) void;
