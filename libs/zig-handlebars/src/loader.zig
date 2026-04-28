//! Template loader - loads template files from filesystem

const std = @import("std");
const TemplateError = @import("error.zig").TemplateError;

pub const Loader = struct {
    allocator: std.mem.Allocator,
    fs_dir: std.fs.Dir,
    templates_dir: []const u8,

    pub fn init(allocator: std.mem.Allocator, templates_dir: []const u8) Loader {
        return .{
            .allocator = allocator,
            .fs_dir = std.fs.cwd(),
            .templates_dir = templates_dir,
        };
    }

    pub fn initWithDir(
        allocator: std.mem.Allocator,
        fs_dir: std.fs.Dir,
        templates_dir: []const u8,
    ) Loader {
        return .{
            .allocator = allocator,
            .fs_dir = fs_dir,
            .templates_dir = templates_dir,
        };
    }

    /// Load a template file by name
    pub fn load(self: *const Loader, name: []const u8) TemplateError![]const u8 {
        const path = try std.fmt.allocPrint(self.allocator, "{s}/{s}", .{ self.templates_dir, name });
        defer self.allocator.free(path);

        const file = self.fs_dir.openFile(path, .{}) catch |err| {
            std.debug.print("Failed to open template: {s}, error: {}\n", .{ path, err });
            return TemplateError.TemplateNotFound;
        };
        defer file.close();

        return file.readToEndAlloc(self.allocator, 1024 * 1024) catch {
            return TemplateError.FileReadFailed;
        };
    }
};
