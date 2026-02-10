const std = @import("std");

fn configureExecutable(b: *std.Build, target: std.Build.ResolvedTarget, exe: *std.Build.Step.Compile) void {
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

    // game
    const game: *std.Build.Step.Compile = b.addExecutable(.{
        .name = "shif",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/game_main.zig"),
            .optimize = optimize,
            .target = target,
        }),
    });
    configureExecutable(b, target, game);
    b.installArtifact(game);

    const editor: *std.Build.Step.Compile = b.addExecutable(.{
        .name = "editor",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/editor_main.zig"),
            .optimize = optimize,
            .target = target,
        }),
    });
    configureExecutable(b, target, editor);
    b.installArtifact(editor);

    {
        const run_cmd = b.addRunArtifact(game);
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
}
