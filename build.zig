const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Import dependencies
    const zig_markdown_mod = b.dependency("zig_markdown", .{
        .target = target,
        .optimize = optimize,
    }).module("zig-markdown");

    const zig_handlebars_mod = b.dependency("zig_handlebars", .{
        .target = target,
        .optimize = optimize,
    }).module("zig-handlebars");

    // Create the hello-zig module
    const mod = b.addModule("hello_zig", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "zig-markdown", .module = zig_markdown_mod },
            .{ .name = "zig-handlebars", .module = zig_handlebars_mod },
        },
    });

    // Create the executable
    const exe = b.addExecutable(.{
        .name = "hello_zig",
        .root_module = mod,
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.setCwd(.{ .src_path = .{ .owner = b, .sub_path = "." } });

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // Tests
    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_tests.step);
}
