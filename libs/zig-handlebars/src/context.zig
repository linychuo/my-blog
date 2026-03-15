//! Template context for storing variables

const std = @import("std");
const Allocator = std.mem.Allocator;
const TemplateError = @import("error.zig").TemplateError;

/// Context holds template variables with proper memory ownership
pub const Context = struct {
    allocator: Allocator,
    data: std.StringHashMap([]const u8),

    pub fn init(allocator: Allocator) Context {
        return .{
            .allocator = allocator,
            .data = std.StringHashMap([]const u8).init(allocator),
        };
    }

    pub fn deinit(self: *Context) void {
        // Free all allocated keys and values
        var it = self.data.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            self.allocator.free(entry.value_ptr.*);
        }
        self.data.deinit();
    }

    /// Set a variable in the context. Copies both key and value.
    pub fn set(self: *Context, key: []const u8, value: []const u8) !void {
        const key_copy = try self.allocator.dupe(u8, key);
        errdefer self.allocator.free(key_copy);
        const value_copy = try self.allocator.dupe(u8, value);
        errdefer self.allocator.free(value_copy);
        try self.data.put(key_copy, value_copy);
    }

    /// Get a variable from the context
    pub fn get(self: *const Context, key: []const u8) ?[]const u8 {
        return self.data.get(key);
    }

    /// Get a variable or return error if missing
    pub fn getOrError(self: *const Context, key: []const u8) TemplateError![]const u8 {
        return self.get(key) orelse TemplateError.ContextKeyMissing;
    }

    /// Check if a key exists in the context
    pub fn has(self: *const Context, key: []const u8) bool {
        return self.data.contains(key);
    }
};

test "Context basic set and get" {
    const allocator = std.testing.allocator;
    var ctx = Context.init(allocator);
    defer ctx.deinit();

    try ctx.set("title", "Hello World");
    try ctx.set("count", "42");

    try std.testing.expectEqualStrings("Hello World", ctx.get("title").?);
    try std.testing.expectEqualStrings("42", ctx.get("count").?);
}

test "Context memory ownership" {
    const allocator = std.testing.allocator;
    {
        var ctx = Context.init(allocator);
        defer ctx.deinit();

        // Value that will be copied
        const original = "test value";
        try ctx.set("key", original);

        // Original can go out of scope, context owns its copy
    }
    // If we reach here without crash, memory management is correct
}

test "Context has method" {
    const allocator = std.testing.allocator;
    var ctx = Context.init(allocator);
    defer ctx.deinit();

    try ctx.set("exists", "value");

    try std.testing.expect(ctx.has("exists"));
    try std.testing.expect(!ctx.has("missing"));
}

test "Context getOrError" {
    const allocator = std.testing.allocator;
    var ctx = Context.init(allocator);
    defer ctx.deinit();

    try ctx.set("key", "value");

    const found = try ctx.getOrError("key");
    try std.testing.expectEqualStrings("value", found);

    const missing = ctx.getOrError("missing");
    try std.testing.expectError(TemplateError.ContextKeyMissing, missing);
}

test "Context empty value" {
    const allocator = std.testing.allocator;
    var ctx = Context.init(allocator);
    defer ctx.deinit();

    try ctx.set("empty", "");
    try std.testing.expectEqualStrings("", ctx.get("empty").?);
}
