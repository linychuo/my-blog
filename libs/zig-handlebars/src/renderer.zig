//! Template renderer - parses and renders Handlebars templates

const std = @import("std");
const Allocator = std.mem.Allocator;
const TemplateError = @import("error.zig").TemplateError;
const Context = @import("context.zig").Context;
const VariableRenderer = @import("variable_renderer.zig").VariableRenderer;
const parseTag = @import("tag_parser.zig").parseTag;
const findTagEnd = @import("tag_parser.zig").findTagEnd;

pub const Renderer = struct {
    allocator: Allocator,
    variable_renderer: VariableRenderer,

    pub fn init(allocator: Allocator) Renderer {
        return .{
            .allocator = allocator,
            .variable_renderer = VariableRenderer.init(allocator),
        };
    }

    pub fn setEscapeEnabled(self: *Renderer, enabled: bool) void {
        self.variable_renderer.setEscapeEnabled(enabled);
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
                    try self.variable_renderer.renderVariable(&result, t.name, unescaped, context);
                }

                i = end;
            } else {
                try result.append(self.allocator, template[i]);
                i += 1;
            }
        }

        return result.toOwnedSlice(self.allocator);
    }
};
