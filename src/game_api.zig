const Inputs = @import("control.zig").Inputs;
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const SpriteStorage = @import("sprites.zig").SpriteStorage;
// const GameState = @import("game.zig").GameState;
const audio = @import("audio.zig");
pub const GameState = @import("game_state.zig");

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
};

// Rendering resources owned by platform, passed to DLL
pub const RenderContext = struct {
    screen: *ScreenBuffer,
    // level: *ScreenBuffer,
    // storage: *SpriteStorage,
};

// Function pointer types for dlsym
pub const GameStepFn = *const fn (*GameMemory, Inputs, PlatformAPI) void;
pub const RenderStepFn = *const fn (*GameMemory, *RenderContext) void;
