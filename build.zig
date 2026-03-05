const std = @import("std");

fn configureGameLibrary(b: *std.Build, target: std.Build.ResolvedTarget, exe: *std.Build.Step.Compile) void {
    _ = target;
    exe.addIncludePath(b.path("src"));
}

fn configurePlatformExecutable(b: *std.Build, target: std.Build.ResolvedTarget, exe: *std.Build.Step.Compile) void {
    exe.addIncludePath(b.path("src"));
    exe.addCSourceFile(.{ .file = b.path("src/vendor/fenster.c"), .flags = &[_][]const u8{} });
    exe.addCSourceFile(.{ .file = b.path("src/vendor/miniaudio.c"), .flags = &[_][]const u8{} });

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

fn add_game_native(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
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

    {
        const run_cmd = b.addRunArtifact(platform);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = b.step("run", "Run game");
        run_step.dependOn(&run_cmd.step);
    }
}

fn add_editor_native(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    const game_lib = b.addLibrary(.{
        .linkage = .dynamic,
        .name = "editor",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/editor.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    configureGameLibrary(b, target, game_lib);
    b.installArtifact(game_lib);

    const platform: *std.Build.Step.Compile = b.addExecutable(.{
        .name = "editor_platform_native",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/editor_platform_native.zig"),
            .optimize = optimize,
            .target = target,
        }),
    });
    configurePlatformExecutable(b, target, platform);
    b.installArtifact(platform);

    {
        const run_cmd = b.addRunArtifact(platform);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = b.step("edit", "edit levels");
        run_step.dependOn(&run_cmd.step);
    }
}

fn add_wasm(b: *std.Build, optimize: std.builtin.OptimizeMode) void {
    // WASM build - outputs to zig-out/web/ for static hosting
    const wasm_target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .wasi,
    });

    const wasm_game_lib = b.addExecutable(.{
        .name = "game",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/platform_wasm.zig"),
            .target = wasm_target,
            .optimize = optimize,
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

    // install server exe to web/ subfolder

    const server_exe = b.addExecutable(.{
        .name = "server",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/server.zig"),
            .target = b.graph.host,
        }),
    });

    const install_server = b.addInstallArtifact(server_exe, .{
        .dest_dir = .{ .override = .{ .custom = "web/" } },
    });

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

    // Copy audio/ to web/audio/
    const install_audio = b.addInstallDirectory(.{
        .source_dir = b.path("src/assets/audio/"),
        .install_dir = .prefix,
        .install_subdir = "web/audio",
    });

    // Create a "web" step that builds everything for static hosting
    const web_step = b.step("web", "Build web version for static hosting");
    web_step.dependOn(&install_server.step);
    web_step.dependOn(&install_wasm.step);
    web_step.dependOn(&install_html.step);
    web_step.dependOn(&install_vendor.step);
    web_step.dependOn(&install_audio.step);

    const serve_cmd = b.addRunArtifact(server_exe);
    serve_cmd.step.dependOn(b.getInstallStep());
    const serve_step = b.step("webdev", "fast local server for developing web platform");
    serve_step.dependOn(&serve_cmd.step);

    {
        // GitHub Pages publish step - outputs to pub/ for static hosting
        const pub_step = b.step("pub", "Build for GitHub Pages (outputs to pub/)");

        // Install wasm to pub/
        const pub_wasm = b.addInstallArtifact(wasm_game_lib, .{
            .dest_dir = .{ .override = .{ .custom = "../pub" } },
        });
        pub_step.dependOn(&pub_wasm.step);

        // Copy index.html to pub/
        const pub_html = b.addInstallFile(b.path("src/web/index.html"), "../pub/index.html");
        pub_step.dependOn(&pub_html.step);

        // Copy vendor/ to pub/vendor/
        const pub_vendor = b.addInstallDirectory(.{
            .source_dir = b.path("src/web/vendor/"),
            .install_dir = .prefix,
            .install_subdir = "../pub/vendor",
        });
        pub_step.dependOn(&pub_vendor.step);

        // Copy audio/ to pub/audio/
        const pub_audio = b.addInstallDirectory(.{
            .source_dir = b.path("src/assets/audio/"),
            .install_dir = .prefix,
            .install_subdir = "../pub/audio",
        });
        pub_step.dependOn(&pub_audio.step);
    }
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    add_game_native(b, target, optimize);
    add_editor_native(b, target, optimize);
    add_wasm(b, optimize);
}
