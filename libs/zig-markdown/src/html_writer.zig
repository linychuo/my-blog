//! HTML Writer - Helper for writing HTML output

const std = @import("std");

/// HTML Writer wrapper around ArrayList for convenient HTML generation
pub const HtmlWriter = struct {
    result: *std.ArrayList(u8),

    pub fn init(result: *std.ArrayList(u8)) HtmlWriter {
        return .{
            .result = result,
        };
    }

    pub fn write(self: *HtmlWriter, allocator: std.mem.Allocator, text: []const u8) !void {
        try self.result.appendSlice(allocator, text);
    }

    pub fn writeEscaped(self: *HtmlWriter, allocator: std.mem.Allocator, text: []const u8) !void {
        // Simple HTML escaping
        for (text) |c| {
            switch (c) {
                '&' => try self.write(allocator, "&amp;"),
                '<' => try self.write(allocator, "&lt;"),
                '>' => try self.write(allocator, "&gt;"),
                '"' => try self.write(allocator, "&quot;"),
                '\'' => try self.write(allocator, "&#39;"),
                else => try self.result.append(allocator, c),
            }
        }
    }
};
