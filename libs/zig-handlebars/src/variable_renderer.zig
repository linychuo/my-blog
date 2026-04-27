//! Variable rendering - renders template variables with context

const std = @import("std");
const Allocator = std.mem.Allocator;
const Context = @import("context.zig").Context;
const escapeHtml = @import("html_escape.zig").escapeHtml;

pub const VariableRenderer = struct {
    allocator: Allocator,
    escape_enabled: bool,

    pub fn init(allocator: Allocator) VariableRenderer {
        return .{
            .allocator = allocator,
            .escape_enabled = true,
        };
    }

    pub fn setEscapeEnabled(self: *VariableRenderer, enabled: bool) void {
        self.escape_enabled = enabled;
    }

    /// Render a variable to the result array
    pub fn renderVariable(
        self: *VariableRenderer,
        result: *std.ArrayList(u8),
        name: []const u8,
        unescaped: bool,
        context: *const Context,
    ) !void {
        if (std.mem.startsWith(u8, name, "~> page") or std.mem.startsWith(u8, name, "> page")) {
            return;
        }

        if (context.get(name)) |value| {
            if (unescaped) {
                try result.appendSlice(self.allocator, value);
            } else if (self.escape_enabled) {
                const escaped = try escapeHtml(self.allocator, value);
                defer self.allocator.free(escaped);
                try result.appendSlice(self.allocator, escaped);
            } else {
                try result.appendSlice(self.allocator, value);
            }
        }
    }
};
