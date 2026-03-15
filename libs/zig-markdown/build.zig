const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target options allow the person running `zig build` to choose
    // what target to build for.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const optimize = b.standardOptimizeOption(.{});

    // Create the markdown library module
    const lib_mod = b.addModule("zig-markdown", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Main library tests (from markdown.zig and inline.zig)
    const unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run all unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
