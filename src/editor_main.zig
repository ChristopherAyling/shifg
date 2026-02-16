const std = @import("std");
const assert = std.debug.assert;
const Window = @import("window.zig").Window;
const draw = @import("draw.zig");
const ui = @import("ui.zig");
const eui = @import("editor_ui.zig");
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
const audio = @import("audio.zig");

const ThingPool = @import("things.zig").ThingPool;

const Inputs = control.Inputs;
const updateInputs = control.updateInputs;

const TILE_CURSOR_VELOCITY = 1;

// TODO collect these into a single traverseable structure
const PLAYER_SPRITE_KEYS = &[_]sprites.SpriteKey{
    .genly,
};

const NPC_SPRITE_KEYS = &[_]sprites.SpriteKey{
    .argaven,
    .estraven,
};

const ITEM_SPRITE_KEYS = &[_]sprites.SpriteKey{
    .redflag,
    .potion,
};

var MENU_LABELS: []const []const u8 = &.{
    "save",
    "load",
    "rename",
    "music",
    "effects",
    "quit",
};

var MENU_MUSIC_LABELS: []const []const u8 = std.meta.fieldNames(audio.MusicTrack);
var MENU_EFFECTS_LABELS: []const []const u8 = std.meta.fieldNames(effects.EffectKeys);

const EditorMode = enum {
    Navigate, // move cursor around. a_pressed->ADD, b_pressed->remove(), start->MENU/SETTINGS
    Add, // choose an NPC from a menu to place
    Menu, // save, load, rename, change music, effects etc
    MenuMusic, // music submenu
    MenuEffects, // save()
    // MOVE
    // EDIT/INSPECT
    // PLAY

};

const EditorState = struct {
    level: Level,
    path: []const u8,

    quit: bool = false,
    mode: EditorMode = .Navigate,
    tile_cursor_x: i32 = con.LEVEL_W_HALF,
    tile_cursor_y: i32 = con.LEVEL_H_HALF,
    camera_x: i32 = 0,
    camera_y: i32 = 0,

    /// new things system
    things: ThingPool = .{},

    audio_system: audio.AudioSystem = undefined,

    // adding
    add_selection_index: usize = 0,

    // menu
    menu_selection_index: usize = 0,
    submenu_selection_index: usize = 0,
    submenu_len: usize = 0,

    pub fn initFromSavedLevel(path: []const u8) EditorState {
        const state: EditorState = .{
            .path = path,
            .level = Level.from_folder(path, "level"),
        };
        return state;
    }

    pub fn deinit(self: *EditorState) void {
        self.audio_system.deinit();
    }

    fn save(self: *EditorState) void {
        std.log.debug("saving level ...", .{});
        self.level.save_things(&self.things);
        std.log.debug("... level saved", .{});
    }

    fn save_and_quit(self: *EditorState) void {
        self.save();
        self.quit = true;
    }

    fn load(self: *EditorState) void {
        self.level.load_things(&self.things);
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
        switch (self.mode) {
            .Navigate => {
                if (inputs.start.pressed) {
                    self.mode = .Menu;
                    self.audio_system.playSound(.close);
                } else if (inputs.a.pressed) {
                    self.mode = .Add;
                    self.add_selection_index = 0;
                    self.audio_system.playSound(.close);
                } else if (!inputs.is_any_direction_active() and inputs.b.pressed) {
                    // delete all things in range
                    var it = self.things.iter();
                    while (it.next_active()) |thing| {
                        if (thing.manhat_dist(self.tile_cursor_x, self.tile_cursor_y) < 8) {
                            thing.active = false;
                        }
                    }
                } else if (inputs.b.held and inputs.left.pressed) {
                    // find closest thing and set tile cursor to be there
                    var closest_ref = ThingPool.get_nil_ref();
                    var closest_dist: i32 = std.math.maxInt(i32);
                    var it = self.things.iter_ref();
                    while (it.next_active()) |ref| {
                        const thing = self.things.get(ref);
                        const dist = thing.manhat_dist(self.tile_cursor_x, self.tile_cursor_y);
                        if (dist < closest_dist) {
                            closest_dist = dist;
                            closest_ref = ref;
                        }
                    }
                    if (self.things.get_or_null(closest_ref)) |closest| {
                        self.tile_cursor_x = closest.x;
                        self.tile_cursor_y = closest.y;
                    }
                } else {
                    if (!inputs.b.held) {
                        if (inputs.directions.contains(.up)) self.tile_cursor_y -= 1 * TILE_CURSOR_VELOCITY;
                        if (inputs.directions.contains(.down)) self.tile_cursor_y += 1 * TILE_CURSOR_VELOCITY;
                        if (inputs.directions.contains(.left)) self.tile_cursor_x -= 1 * TILE_CURSOR_VELOCITY;
                        if (inputs.directions.contains(.right)) self.tile_cursor_x += 1 * TILE_CURSOR_VELOCITY;
                    }
                }
            },
            .Add => {
                self.submenu_len = 3;
                if (inputs.b.pressed) {
                    self.mode = .Navigate;
                    self.audio_system.playSound(.close);
                } else if (inputs.a.pressed) {
                    self.audio_system.playSound(.click);
                    switch (self.submenu_selection_index) {
                        0 => {
                            _ = self.things.add_npc(NPC_SPRITE_KEYS[self.add_selection_index], self.tile_cursor_x, self.tile_cursor_y);
                        },
                        1 => {
                            _ = self.things.add_player(PLAYER_SPRITE_KEYS[self.add_selection_index], self.tile_cursor_x, self.tile_cursor_y);
                        },
                        2 => {
                            _ = self.things.add_item(ITEM_SPRITE_KEYS[self.add_selection_index], self.tile_cursor_x, self.tile_cursor_y);
                        },
                        else => {
                            _ = self.things.add_npc(NPC_SPRITE_KEYS[self.add_selection_index], self.tile_cursor_x, self.tile_cursor_y);
                        },
                    }

                    self.mode = .Navigate;
                } else {
                    if (inputs.up.pressed) self.add_selection_index -|= 1;
                    if (inputs.down.pressed) self.add_selection_index = @min(@as(i32, @intCast(NPC_SPRITE_KEYS.len - 1)), self.add_selection_index + 1);
                    if (inputs.left.pressed) self.submenu_selection_index -|= 1;
                    if (inputs.right.pressed) self.submenu_selection_index = (self.submenu_selection_index + 1) % self.submenu_len;
                }
            },
            .Menu => {
                if (inputs.start.pressed or inputs.b.pressed) {
                    self.mode = .Navigate;
                    self.audio_system.playSound(.close);
                } else if (inputs.a.pressed) {
                    // TODO
                    self.audio_system.playSound(.click);
                    switch (self.menu_selection_index) {
                        0 => {
                            // save
                            self.save();
                            // TODO add toast or one time message or something
                        },
                        1 => {
                            // load
                            self.load();
                        },
                        2 => {
                            // rename
                        },
                        3 => {
                            // music
                            self.mode = .MenuMusic;
                            self.submenu_selection_index = 0; // TODO default this to current music index
                        },
                        4 => {
                            // effects
                            self.mode = .MenuEffects;
                            self.submenu_selection_index = 0; // TODO default this to current effects index
                        },
                        5 => {
                            self.quit = true;
                        },
                        else => {},
                    }
                } else {
                    if (inputs.up.pressed) self.menu_selection_index -|= 1;
                    if (inputs.down.pressed) self.menu_selection_index = @min(MENU_LABELS.len - 1, self.menu_selection_index + 1);
                }
            },
            .MenuMusic => {
                if (inputs.start.pressed or inputs.b.pressed) {
                    self.mode = .Menu;
                    self.menu_selection_index = 3;
                    self.audio_system.playSound(.close);
                    // set music back to chosen
                    self.audio_system.setMusic(self.level.music);
                } else if (inputs.a.pressed) {
                    self.level.music = @enumFromInt(self.submenu_selection_index);
                    self.mode = .Navigate;
                } else {
                    if (inputs.up.pressed) self.submenu_selection_index -|= 1;
                    if (inputs.down.pressed) self.submenu_selection_index = @min(MENU_MUSIC_LABELS.len - 1, self.submenu_selection_index + 1);
                }
                // TODO start playing the song that is being hovered
                self.audio_system.setMusic(@enumFromInt(self.submenu_selection_index));
            },
            .MenuEffects => {
                if (inputs.start.pressed or inputs.b.pressed) {
                    self.mode = .Menu;
                    self.menu_selection_index = 4;
                    self.audio_system.playSound(.close);
                } else if (inputs.a.pressed) {
                    // TODO set level.effectkey
                    self.mode = .Navigate;
                } else {
                    if (inputs.up.pressed) self.submenu_selection_index -|= 1;
                    if (inputs.down.pressed) self.submenu_selection_index = @min(MENU_EFFECTS_LABELS.len - 1, self.submenu_selection_index + 1);
                }
                // TODO preview effect that is being hovered
            },
        }

        self.camera_follow_tile_cursor();
    }
};

const RenderState = struct {
    screen: ScreenBuffer,
    screen_upscaled: ScreenBuffer,
    level: ScreenBuffer,
    storage: sprites.SpriteStorage,

    pub fn step(self: *RenderState, editor_state: *EditorState) void {
        // set glaring defaults so we can easily spot render errors
        draw.fill(&self.screen, 0xFF0000);
        draw.fill(&self.screen_upscaled, 0x00FF00);
        draw.fill_checkerboard(&self.level, 8, 0xFF00FF, 0x0);

        // render level
        draw.draw_image(&self.level, editor_state.level.bg, 0, 0);
        draw.draw_image(&self.level, editor_state.level.fg, 0, 0);
        draw.draw_image(&self.level, self.storage.get(.cursor), editor_state.tile_cursor_x, editor_state.tile_cursor_y);
        // for (editor_state.npcs) |npc| {
        //     if (npc.active) {
        //         draw.draw_image(&self.level, self.storage.get(npc.spritekey), npc.x, npc.y);
        //     }
        // }

        var iter = editor_state.things.iter();
        while (iter.next_active()) |thing| {
            draw.draw_image(&self.level, self.storage.get(thing.spritekey), thing.x, thing.y);
        }
        draw.view(&self.level, &self.screen, editor_state.camera_x, editor_state.camera_y);

        // render ui
        switch (editor_state.mode) {
            .Navigate => {},
            .Add => {
                switch (editor_state.submenu_selection_index) {
                    0 => {
                        eui.draw_sprite_menu(&self.screen, 0, 0, &self.storage, editor_state.add_selection_index, NPC_SPRITE_KEYS, "NPC");
                    },
                    1 => {
                        eui.draw_sprite_menu(&self.screen, 0, 0, &self.storage, editor_state.add_selection_index, PLAYER_SPRITE_KEYS, "PLY");
                    },
                    2 => {
                        eui.draw_sprite_menu(&self.screen, 0, 0, &self.storage, editor_state.add_selection_index, ITEM_SPRITE_KEYS, "ITM");
                    },
                    else => {
                        eui.draw_sprite_menu(&self.screen, 0, 0, &self.storage, editor_state.add_selection_index, NPC_SPRITE_KEYS, "NPC");
                    },
                }
            },
            .Menu => {
                eui.draw_text_menu(&self.screen, 0, 0, editor_state.menu_selection_index, MENU_LABELS);
            },
            .MenuMusic => {
                eui.draw_text_menu(&self.screen, 0, 0, editor_state.menu_selection_index, MENU_LABELS);
                eui.draw_text_menu(&self.screen, 16, 8, editor_state.submenu_selection_index, MENU_MUSIC_LABELS);
            },
            .MenuEffects => {
                eui.draw_text_menu(&self.screen, 0, 0, editor_state.menu_selection_index, MENU_LABELS);
                eui.draw_text_menu(&self.screen, 16, 8, editor_state.submenu_selection_index, MENU_EFFECTS_LABELS);
            },
        }

        // upscale
        self.screen.upscale(&self.screen_upscaled, con.SCALE);
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
    const screen: ScreenBuffer = try ScreenBuffer.init(allocator, con.NATIVE_W, con.NATIVE_H);
    const screen_upscaled: ScreenBuffer = try ScreenBuffer.init(allocator, con.UPSCALED_W, con.UPSCALED_H);

    var window = try Window.init(allocator, con.UPSCALED_W, con.UPSCALED_H, "shif - editor");
    defer window.deinit();
    window.before_loop();

    var storage = sprites.SpriteStorage.init();
    storage.load();

    // var editor_state = EditorState.initFromSavedLevel("assets/levels/parade");
    var editor_state: *EditorState = try allocator.create(EditorState);
    editor_state.* = EditorState.initFromSavedLevel("/Users/chris/gaming/gam1/assets/levels/cornelia");
    editor_state.audio_system.init();
    editor_state.load();
    defer editor_state.deinit();
    defer allocator.destroy(editor_state);

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
        render_state.step(editor_state);

        blit(render_state.screen_upscaled, &window);

        if (editor_state.quit) break;
    }
}
