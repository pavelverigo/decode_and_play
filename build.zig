const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "decode_and_play",
        .root_source_file = .{ .path = "src/win_main.zig" },
        .target = target,
        .optimize = optimize,
    });

    if (target.getOsTag() == .windows) {
        exe.linkLibC();
        exe.linkSystemLibrary("ole32");
        exe.linkSystemLibrary("xaudio2_8");
        exe.addCSourceFile(.{ .file = .{ .path = "src/win_xaudio2.cpp" }, .flags = &.{} });
    } else unreachable;

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
