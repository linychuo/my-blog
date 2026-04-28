//! Template renderer - parses and renders Handlebars templates

const std = @import("std");
const Allocator = std.mem.Allocator;
const TemplateError = @import("error.zig").TemplateError;
const Context = @import("context.zig").Context;
const escapeHtml = @import("html_escape.zig").escapeHtml;
const parseTag = @import("tag_parser.zig").parseTag;
const findTagEnd = @import("tag_parser.zig").findTagEnd;

pub const Renderer = struct {
    allocator: Allocator,
    escape_enabled: bool,

    pub fn init(allocator: Allocator) Renderer {
        return .{
            .allocator = allocator,
            .escape_enabled = true,
        };
    }

    pub fn setEscapeEnabled(self: *Renderer, enabled: bool) void {
        self.escape_enabled = enabled;
    }

    /// Render a template string with context
    pub fn render(
        self: *Renderer,
        template: []const u8,
        context: *const Context,
    ) TemplateError![]const u8 {
        var result = std.ArrayList(u8).empty;
        errdefer result.deinit(self.allocator);

        var i: usize = 0;
        while (i < template.len) {
            const tag = parseTag(template, i);
            if (tag) |t| {
                const end = findTagEnd(template, i, t);

                if (t.tag_type == .partial) {
                    try result.appendSlice(self.allocator, "{{>");
                    try result.appendSlice(self.allocator, t.name);
                    try result.appendSlice(self.allocator, "}}");
                } else {
                    const unescaped = t.tag_type == .unescaped_variable;
                    try self.renderVariable(&result, t.name, unescaped, context);
                }

                i = end;
            } else {
                try result.append(self.allocator, template[i]);
                i += 1;
            }
        }

        return result.toOwnedSlice(self.allocator);
    }

    /// Render a variable to the result array
    fn renderVariable(
        self: *Renderer,
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
