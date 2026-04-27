//! Partials handling for template inheritance

const std = @import("std");
const Allocator = std.mem.Allocator;
const TemplateError = @import("error.zig").TemplateError;
const Context = @import("context.zig").Context;

/// PartialsManager handles loading and caching of partial templates
pub const PartialsManager = struct {
    allocator: Allocator,
    fs_dir: std.fs.Dir,
    partials_dir: []const u8,
    cache: std.StringHashMap([]const u8),

    pub fn init(allocator: Allocator, fs_dir: std.fs.Dir, partials_dir: []const u8) PartialsManager {
        return .{
            .allocator = allocator,
            .fs_dir = fs_dir,
            .partials_dir = partials_dir,
            .cache = std.StringHashMap([]const u8).init(allocator),
        };
    }

    pub fn deinit(self: *PartialsManager) void {
        // Free all cached partials (keys and values)
        var it = self.cache.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            self.allocator.free(entry.value_ptr.*);
        }
        self.cache.deinit();
    }

    /// Check if cache is empty (for testing)
    pub fn cacheCount(self: *const PartialsManager) usize {
        return self.cache.count();
    }

    /// Load a partial by name (without extension)
    pub fn loadPartial(self: *PartialsManager, name: []const u8) TemplateError![]const u8 {
        // Check cache first
        if (self.cache.get(name)) |cached| {
            return cached;
        }

        // Build path: partials_dir/name.hbs
        const path = try std.fs.path.join(self.allocator, &.{ self.partials_dir, name });
        defer self.allocator.free(path);

        const path_with_ext = try std.fmt.allocPrint(self.allocator, "{s}.hbs", .{path});
        defer self.allocator.free(path_with_ext);

        const file = self.fs_dir.openFile(path_with_ext, .{}) catch |err| {
            std.debug.print("Failed to open partial: {s}, error: {}\n", .{ path_with_ext, err });
            return TemplateError.TemplateNotFound;
        };
        defer file.close();

        const content = file.readToEndAlloc(self.allocator, 1024 * 1024) catch {
            return TemplateError.FileReadFailed;
        };
        defer self.allocator.free(content); // Free the original after copying

        // Cache the content - make a copy that we own
        const content_copy = try self.allocator.dupe(u8, content);
        errdefer self.allocator.free(content_copy);
        const name_copy = try self.allocator.dupe(u8, name);
        errdefer self.allocator.free(name_copy);
        try self.cache.put(name_copy, content_copy);

        return content_copy;
    }
};

test "PartialsManager loads partial" {
    const allocator = std.testing.allocator;
    const cwd = std.fs.cwd();
    var manager = PartialsManager.init(allocator, cwd, "templates/partials");
    defer manager.deinit();

    const content = try manager.loadPartial("test");
    // Don't free content - it's owned by the manager's cache

    try std.testing.expectEqualStrings("test content", content);
}

test "PartialsManager caches partial" {
    const allocator = std.testing.allocator;
    const cwd = std.fs.cwd();
    var manager = PartialsManager.init(allocator, cwd, "templates/partials");
    defer manager.deinit();

    // Load twice - second should come from cache
    const content1 = try manager.loadPartial("test");
    // Don't free - owned by cache

    const content2 = try manager.loadPartial("test");

    // Both should return same pointer (from cache)
    try std.testing.expectEqual(content1.ptr, content2.ptr);
}

test "PartialsManager returns error for missing partial" {
    const allocator = std.testing.allocator;
    const cwd = std.fs.cwd();
    var manager = PartialsManager.init(allocator, cwd, "templates/partials");
    defer manager.deinit();

    try std.testing.expectError(
        TemplateError.TemplateNotFound,
        manager.loadPartial("nonexistent"),
    );
}
