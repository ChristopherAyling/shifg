const std = @import("std");

fn configureGameLibrary(b: *std.Build, target: std.Build.ResolvedTarget, exe: *std.Build.Step.Compile) void {
    _ = target;
    exe.addIncludePath(b.path("src"));
}

fn configurePlatformExecutable(b: *std.Build, target: std.Build.ResolvedTarget, exe: *std.Build.Step.Compile) void {
    exe.addIncludePath(b.path("src"));
    exe.addCSourceFile(.{ .file = b.path("src/fenster.c"), .flags = &[_][]const u8{} });
    exe.addCSourceFile(.{ .file = b.path("src/miniaudio.c"), .flags = &[_][]const u8{} });

    switch (target.result.os.tag) {
        .macos => exe.linkFramework("Cocoa"),
        .windows => exe.linkSystemLibrary("gdi32"),
        .linux => exe.linkSystemLibrary("X11"),
        else => {},
    }
    exe.linkLibC();

    exe.linkFramework("AudioToolbox");
    exe.linkFramework("CoreAudio");
    exe.linkFramework("CoreFoundation");
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    b.installDirectory(.{
        .source_dir = b.path("assets/"),
        .install_dir = .bin,
        .install_subdir = "assets",
    });

    const game_lib = b.addLibrary(.{
        .linkage = .dynamic,
        .name = "game",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/game.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    configureGameLibrary(b, target, game_lib);
    b.installArtifact(game_lib);

    // game
    const platform: *std.Build.Step.Compile = b.addExecutable(.{
        .name = "platform_native",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/platform_native.zig"),
            .optimize = optimize,
            .target = target,
        }),
    });
    configurePlatformExecutable(b, target, platform);
    b.installArtifact(platform);

    const editor: *std.Build.Step.Compile = b.addExecutable(.{
        .name = "editor_native",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/editor_native.zig"),
            .optimize = optimize,
            .target = target,
        }),
    });
    configurePlatformExecutable(b, target, editor);
    b.installArtifact(editor);

    {
        const run_cmd = b.addRunArtifact(platform);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = b.step("run", "Run game");
        run_step.dependOn(&run_cmd.step);
    }

    {
        const run_cmd = b.addRunArtifact(editor);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = b.step("edit", "Run editor");
        run_step.dependOn(&run_cmd.step);
    }

    // thingdump
    const thingdump: *std.Build.Step.Compile = b.addExecutable(.{
        .name = "thingdump",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/thingdump_main.zig"),
            .optimize = optimize,
            .target = target,
        }),
    });
    b.installArtifact(thingdump);

    {
        const run_cmd = b.addRunArtifact(thingdump);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = b.step("dump", "Run thingdump");
        run_step.dependOn(&run_cmd.step);
    }

    // WASM build - outputs to zig-out/web/ for static hosting
    {
        const wasm_target = b.resolveTargetQuery(.{
            .cpu_arch = .wasm32,
            .os_tag = .wasi,
        });

        // Embedded assets module (at project root so it can access assets/)
        const embedded_assets_module = b.createModule(.{
            .root_source_file = b.path("embedded_assets.zig"),
            .target = wasm_target,
            .optimize = optimize,
        });

        const wasm_game_lib = b.addExecutable(.{
            .name = "game",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/platform_wasm.zig"),
                .target = wasm_target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "embedded_assets", .module = embedded_assets_module },
                },
            }),
        });
        wasm_game_lib.addIncludePath(b.path("src"));
        wasm_game_lib.linkLibC();
        wasm_game_lib.root_module.export_symbol_names = &.{
            // dbg
            "yo",
            // game control
            "game_frame",
            "game_init",
            // memory transfer
            "get_framebuffer_ptr",
            "get_framebuffer_len",
            "get_screen_w",
            "get_screen_h",
            "set_input_state",
        };

        // Install wasm to web/ subfolder
        const install_wasm = b.addInstallArtifact(wasm_game_lib, .{
            .dest_dir = .{ .override = .{ .custom = "web" } },
        });

        // Copy index.html to web/
        const install_html = b.addInstallFile(b.path("src/web/index.html"), "web/index.html");

        // Copy vendor/ to web/vendor/
        const install_vendor = b.addInstallDirectory(.{
            .source_dir = b.path("src/web/vendor/"),
            .install_dir = .prefix,
            .install_subdir = "web/vendor",
        });

        // Create a "web" step that builds everything for static hosting
        const web_step = b.step("web", "Build web version for static hosting");
        web_step.dependOn(&install_wasm.step);
        web_step.dependOn(&install_html.step);
        web_step.dependOn(&install_vendor.step);
    }
}
