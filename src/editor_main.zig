const std = @import("std");
const assert = std.debug.assert;
const Window = @import("window.zig").Window;
const draw = @import("draw.zig");
const ui = @import("ui.zig");
const Image = @import("image.zig").Image;
const ScreenBuffer = @import("screen.zig").ScreenBuffer;
const DialogueState = @import("dialogue.zig").DialogueState;
const DialogueSequence = @import("dialogue.zig").DialogueSequence;
const dialogues = @import("dialogue.zig");
const control = @import("control.zig");
const sprites = @import("sprites.zig");
const StoryCheckpoint = @import("story.zig").StoryCheckpoint;
const con = @import("constants.zig");
const effects = @import("effects.zig");
const Level = @import("level.zig").Level;
const entity = @import("entity.zig");
const audio = @import("audio.zig");

const Npc = entity.Npc;
const Item = entity.Item;

const Inputs = control.Inputs;
const updateInputs = control.updateInputs;

const TILE_CURSOR_VELOCITY = 1;

const EditorState = struct {
    tile_cursor_x: i32 = con.LEVEL_W_HALF,
    tile_cursor_y: i32 = con.LEVEL_H_HALF,
    camera_x: i32 = 0,
    camera_y: i32 = 0,
    npcs: [1000]Npc = .{Npc{}} ** 1000,
    level: Level,

    // pub fn initFromBackgroundImageFile(background_path: []const u8, level_folder: []const u8) !EditorState {
    //     var buf: [256]u8 = undefined;
    //     // create new level in level folder
    //     {
    //         try std.fs.makeDirAbsolute(level_folder);
    //         const new_background_path = try std.fmt.bufPrintZ(&buf, "{s}/background.png", .{background_path});
    //         try std.fs.copyFileAbsolute(background_path, new_background_path, .{});
    //     }
    //     return EditorState.initFromSavedLevel(level_folder);
    // }

    pub fn initFromSavedLevel(path: []const u8) EditorState {
        return .{
            .level = Level.from_folder(path, "level"),
        };
    }

    pub fn camera_follow_tile_cursor(self: *EditorState) void {
        self.camera_x = self.tile_cursor_x - @divFloor(con.NATIVE_W, 2) + @divFloor(con.PLAYER_W, 2);
        self.camera_y = self.tile_cursor_y - @divFloor(con.NATIVE_H, 2) + @divFloor(con.PLAYER_H, 2);

        self.camera_x = @max(self.camera_x, con.NATIVE_W_HALF);
        self.camera_y = @max(self.camera_y, con.NATIVE_H_HALF);

        self.camera_x = @min(self.camera_x, con.LEVEL_W - con.NATIVE_W);
        self.camera_y = @min(self.camera_y, con.LEVEL_H - con.NATIVE_H);
    }

    pub fn step(self: *EditorState, inputs: Inputs) void {
        if (inputs.directions.contains(.up)) self.tile_cursor_y -= 1 * TILE_CURSOR_VELOCITY;
        if (inputs.directions.contains(.down)) self.tile_cursor_y += 1 * TILE_CURSOR_VELOCITY;
        if (inputs.directions.contains(.left)) self.tile_cursor_x -= 1 * TILE_CURSOR_VELOCITY;
        if (inputs.directions.contains(.right)) self.tile_cursor_x += 1 * TILE_CURSOR_VELOCITY;

        self.camera_follow_tile_cursor();
    }
};

const RenderState = struct {
    screen: ScreenBuffer,
    screen_upscaled: ScreenBuffer,
    level: ScreenBuffer,
    storage: sprites.SpriteStorage,

    pub fn step(self: *RenderState, editor_state: *EditorState) void {
        draw.fill(&self.screen, 0x0);
        draw.fill(&self.screen_upscaled, 0x0);

        draw.fill_checkerboard(&self.level, 8, 0xFF00FF, 0x0);

        draw.draw_image(&self.level, editor_state.level.bg, 0, 0);
        draw.draw_image(&self.level, editor_state.level.fg, 0, 0);

        draw.draw_image(&self.level, self.storage.get(.cursor), editor_state.tile_cursor_x, editor_state.tile_cursor_y);

        draw.view(&self.level, &self.screen, editor_state.camera_x, editor_state.camera_y);
    }
};

fn blit(screen: ScreenBuffer, window: *Window) void {
    assert(screen.w == window.w);
    assert(screen.h == window.h);
    for (0..screen.data.len) |i| {
        window.f.buf[i] = screen.data[i];
    }
}

pub fn main() !void {
    // the editor exists to build up a Large Array of Things (LAOT)
    // the large array of things is then serialised to disk
    // this is then loaded when a level is loaded in the game as the
    // starting game state.
    // can start from either a png or an existing level folder

    std.log.debug("starting editor", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    const level_screen: ScreenBuffer = try ScreenBuffer.init(allocator, con.LEVEL_W, con.LEVEL_H);
    var screen: ScreenBuffer = try ScreenBuffer.init(allocator, con.NATIVE_W, con.NATIVE_H);
    var screen_upscaled: ScreenBuffer = try ScreenBuffer.init(allocator, con.UPSCALED_W, con.UPSCALED_H);

    var window = try Window.init(allocator, con.UPSCALED_W, con.UPSCALED_H);
    defer window.deinit();
    window.before_loop();

    var storage = sprites.SpriteStorage.init();
    storage.load();

    var editor_state = EditorState.initFromSavedLevel("assets/levels/parade");

    var render_state: RenderState = .{
        .screen = screen,
        .screen_upscaled = screen_upscaled,
        .level = level_screen,
        .storage = storage,
    };

    var inputs = Inputs{};
    while (window.loop()) {
        updateInputs(&inputs, window);
        editor_state.step(inputs);
        render_state.step(&editor_state);

        screen.upscale(&screen_upscaled, con.SCALE);
        blit(render_state.screen_upscaled, &window);
    }
}
