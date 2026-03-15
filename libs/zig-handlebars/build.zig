const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target options
    const target = b.standardTargetOptions(.{});

    // Standard optimization options
    const optimize = b.standardOptimizeOption(.{});

    // Create the library module
    const lib_mod = b.addModule("zig-handlebars", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add tests
    const unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);

    // Add example executable
    const example_mod = b.addModule("example", .{
        .root_source_file = b.path("src/test_partial.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "zig-handlebars", .module = lib_mod },
        },
    });

    const example = b.addExecutable(.{
        .name = "example",
        .root_module = example_mod,
    });

    const run_example = b.addRunArtifact(example);
    if (b.args) |args| {
        run_example.addArgs(args);
    }

    const run_step = b.step("run", "Run example");
    run_step.dependOn(&run_example.step);
}
