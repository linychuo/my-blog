//! Template engine implementation

const std = @import("std");
const Allocator = std.mem.Allocator;
const TemplateError = @import("error.zig").TemplateError;
const Context = @import("context.zig").Context;
const PartialsManager = @import("partials.zig").PartialsManager;
const escapeHtml = @import("html_escape.zig").escapeHtml;

/// TemplateEngine renders Handlebars-style templates
pub const TemplateEngine = struct {
    allocator: Allocator,
    fs_dir: std.fs.Dir,
    templates_dir: []const u8,
    page_content: ?[]const u8,
    partials_manager: ?PartialsManager,
    escape_enabled: bool,

    const Self = @This();

    /// Initialize the template engine
    /// @param allocator Memory allocator
    /// @param templates_dir Directory containing template files
    pub fn init(allocator: Allocator, templates_dir: []const u8) TemplateEngine {
        return .{
            .allocator = allocator,
            .fs_dir = std.fs.cwd(),
            .templates_dir = templates_dir,
            .page_content = null,
            .partials_manager = null,
            .escape_enabled = true,
        };
    }

    /// Initialize with custom filesystem directory
    pub fn initWithDir(
        allocator: Allocator,
        fs_dir: std.fs.Dir,
        templates_dir: []const u8,
    ) TemplateEngine {
        return .{
            .allocator = allocator,
            .fs_dir = fs_dir,
            .templates_dir = templates_dir,
            .page_content = null,
            .partials_manager = null,
            .escape_enabled = true,
        };
    }

    /// Enable or disable HTML escaping for variables
    pub fn setEscapeEnabled(self: *Self, enabled: bool) void {
        self.escape_enabled = enabled;
    }

    /// Set up partials support
    pub fn enablePartials(self: *Self, partials_dir: []const u8) void {
        self.partials_manager = PartialsManager.init(self.allocator, self.fs_dir, partials_dir);
    }

    /// Set the page content from child template (for template inheritance)
    pub fn setPageContent(self: *Self, content: []const u8) void {
        self.page_content = content;
    }

    /// Deinitialize the engine and free resources
    pub fn deinit(self: *Self) void {
        if (self.partials_manager) |*pm| {
            pm.deinit();
        }
    }

    /// Load a template file by name
    fn loadTemplate(self: *const Self, name: []const u8) TemplateError![]const u8 {
        const path = try std.fs.path.join(self.allocator, &.{ self.templates_dir, name });
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

    /// Render a template file with context
    pub fn render(self: *Self, name: []const u8, context: *const Context) TemplateError![]const u8 {
        const template = try self.loadTemplate(name);
        defer self.allocator.free(template);
        return self.renderString(template, context);
    }

    /// Render a template string with context
    pub fn renderString(self: *Self, template: []const u8, context: *const Context) TemplateError![]const u8 {
        var result = std.ArrayList(u8).empty;
        errdefer result.deinit(self.allocator);

        var i: usize = 0;
        while (i < template.len) {
            if (i + 1 < template.len and template[i] == '{' and template[i + 1] == '{') {
                i += 2;

                // Check for unescaped: {{{
                const is_unescaped = (i < template.len and template[i] == '{');
                if (is_unescaped) i += 1;

                // Check for partial: {{> name}}
                const is_partial = (i < template.len and template[i] == '>');
                if (is_partial) {
                    i += 1;
                    // Skip whitespace
                    while (i < template.len and (template[i] == ' ' or template[i] == '\t')) : (i += 1) {}
                }

                var end = i;
                while (end < template.len and template[end] != '}') : (end += 1) {}

                // Count closing braces
                var brace_count: usize = 0;
                while (end < template.len and template[end] == '}') : (end += 1) {
                    brace_count += 1;
                }

                // Validate brace count
                const expected_braces: usize = if (is_unescaped) 3 else if (is_partial) 2 else 2;
                if (brace_count < expected_braces) {
                    i -= 2;
                    try result.append(self.allocator, template[i]);
                    i += 1;
                    continue;
                }

                const tag_content = template[i .. end - brace_count];

                if (is_partial) {
                    // Handle partial: {{> name}}
                    const partial_name = std.mem.trim(u8, tag_content, " \r\n\t");
                    // Check for special template inheritance tags first
                    if (std.mem.eql(u8, partial_name, "page")) {
                        if (self.page_content) |content| {
                            try result.appendSlice(self.allocator, content);
                        }
                    } else if (std.mem.eql(u8, partial_name, "(parent)")) {
                        // Child template calling parent - skip
                    } else if (self.partials_manager) |*pm| {
                        const partial_content = try pm.loadPartial(partial_name);
                        const rendered = try self.renderString(partial_content, context);
                        try result.appendSlice(self.allocator, rendered);
                        self.allocator.free(rendered);
                    }
                } else {
                    const tag = std.mem.trim(u8, tag_content, " \r\n\t");

                    // Check for special tags
                    if (std.mem.startsWith(u8, tag, "~> page") or std.mem.startsWith(u8, tag, "> page")) {
                        // Insert page content from child template
                        if (self.page_content) |content| {
                            try result.appendSlice(self.allocator, content);
                        }
                    } else if (std.mem.startsWith(u8, tag, "~> (parent)") or std.mem.startsWith(u8, tag, "> (parent)")) {
                        // Child template calling parent - skip
                    } else if (context.get(tag)) |value| {
                        if (is_unescaped) {
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

                i = end;
            } else {
                try result.append(self.allocator, template[i]);
                i += 1;
            }
        }

        return result.toOwnedSlice(self.allocator);
    }
};

test "TemplateEngine renders simple variables" {
    const allocator = std.testing.allocator;
    var engine = TemplateEngine.init(allocator, "templates");
    defer engine.deinit();

    var ctx = Context.init(allocator);
    defer ctx.deinit();

    try ctx.set("title", "Hello World");

    const template = "<h1>{{title}}</h1>";
    const result = try engine.renderString(template, &ctx);
    defer allocator.free(result);

    try std.testing.expectEqualStrings("<h1>Hello World</h1>", result);
}

test "TemplateEngine renders unescaped HTML" {
    const allocator = std.testing.allocator;
    var engine = TemplateEngine.init(allocator, "templates");
    defer engine.deinit();

    var ctx = Context.init(allocator);
    defer ctx.deinit();

    try ctx.set("html", "<b>Bold</b>");

    const template = "<div>{{{html}}}</div>";
    const result = try engine.renderString(template, &ctx);
    defer allocator.free(result);

    try std.testing.expectEqualStrings("<div><b>Bold</b></div>", result);
}

test "TemplateEngine escapes HTML by default" {
    const allocator = std.testing.allocator;
    var engine = TemplateEngine.init(allocator, "templates");
    defer engine.deinit();

    var ctx = Context.init(allocator);
    defer ctx.deinit();

    try ctx.set("danger", "<script>alert(1)</script>");

    const template = "<div>{{danger}}</div>";
    const result = try engine.renderString(template, &ctx);
    defer allocator.free(result);

    const expected = "<div>&lt;script&gt;alert(1)&lt;/script&gt;</div>";
    try std.testing.expectEqualStrings(expected, result);
}

test "TemplateEngine with escaping disabled" {
    const allocator = std.testing.allocator;
    var engine = TemplateEngine.init(allocator, "templates");
    defer engine.deinit();

    engine.setEscapeEnabled(false);

    var ctx = Context.init(allocator);
    defer ctx.deinit();

    try ctx.set("html", "<b>Bold</b>");

    const template = "<div>{{html}}</div>";
    const result = try engine.renderString(template, &ctx);
    defer allocator.free(result);

    try std.testing.expectEqualStrings("<div><b>Bold</b></div>", result);
}

test "TemplateEngine renders partials" {
    const allocator = std.testing.allocator;
    var engine = TemplateEngine.init(allocator, "templates");
    defer engine.deinit();

    engine.enablePartials("templates/partials");

    var ctx = Context.init(allocator);
    defer ctx.deinit();

    try ctx.set("title", "Test");

    const template = "<h1>{{title}}</h1>{{> test}}";
    const result = try engine.renderString(template, &ctx);
    defer allocator.free(result);

    try std.testing.expectEqualStrings("<h1>Test</h1>test content", result);
}

test "TemplateEngine handles missing variables" {
    const allocator = std.testing.allocator;
    var engine = TemplateEngine.init(allocator, "templates");
    defer engine.deinit();

    var ctx = Context.init(allocator);
    defer ctx.deinit();

    const template = "<h1>{{missing}}</h1>";
    const result = try engine.renderString(template, &ctx);
    defer allocator.free(result);

    // Missing variables are silently ignored
    try std.testing.expectEqualStrings("<h1></h1>", result);
}

test "TemplateEngine with template inheritance" {
    const allocator = std.testing.allocator;
    var engine = TemplateEngine.init(allocator, "templates");
    defer engine.deinit();

    engine.setPageContent("<p>Child content</p>");

    var ctx = Context.init(allocator);
    defer ctx.deinit();

    const template = "<body>{{> page}}</body>";
    const result = try engine.renderString(template, &ctx);
    defer allocator.free(result);

    try std.testing.expectEqualStrings("<body><p>Child content</p></body>", result);
}
