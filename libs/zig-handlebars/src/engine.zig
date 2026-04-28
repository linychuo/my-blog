//! Template engine - orchestrates template loading and rendering

const std = @import("std");
const Allocator = std.mem.Allocator;
const TemplateError = @import("error.zig").TemplateError;
const Context = @import("context.zig").Context;
const Loader = @import("loader.zig").Loader;
const PartialsManager = @import("partials.zig").PartialsManager;
const Renderer = @import("renderer.zig").Renderer;
const parseTag = @import("tag_parser.zig").parseTag;
const findTagEnd = @import("tag_parser.zig").findTagEnd;

pub const TemplateEngine = struct {
    allocator: Allocator,
    loader: Loader,
    renderer: Renderer,
    page_content: ?[]const u8,
    partials_manager: ?PartialsManager,
    template_cache: std.StringHashMap([]const u8),

    const Self = @This();

    pub fn init(allocator: Allocator, templates_dir: []const u8) Self {
        return .{
            .allocator = allocator,
            .loader = Loader.init(allocator, templates_dir),
            .renderer = Renderer.init(allocator),
            .page_content = null,
            .partials_manager = null,
            .template_cache = std.StringHashMap([]const u8).init(allocator),
        };
    }

    pub fn initWithDir(
        allocator: Allocator,
        fs_dir: std.fs.Dir,
        templates_dir: []const u8,
    ) Self {
        return .{
            .allocator = allocator,
            .loader = Loader.initWithDir(allocator, fs_dir, templates_dir),
            .renderer = Renderer.init(allocator),
            .page_content = null,
            .partials_manager = null,
            .template_cache = std.StringHashMap([]const u8).init(allocator),
        };
    }

    pub fn setEscapeEnabled(self: *Self, enabled: bool) void {
        self.renderer.setEscapeEnabled(enabled);
    }

    pub fn enablePartials(self: *Self, partials_dir: []const u8) void {
        self.partials_manager = PartialsManager.init(self.allocator, self.loader.fs_dir, partials_dir);
    }

    pub fn setPageContent(self: *Self, content: []const u8) void {
        self.page_content = content;
    }

    pub fn deinit(self: *Self) void {
        if (self.partials_manager) |*pm| {
            pm.deinit();
        }
        var it = self.template_cache.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            self.allocator.free(entry.value_ptr.*);
        }
        self.template_cache.deinit();
    }

    pub fn render(self: *Self, name: []const u8, context: *const Context) TemplateError![]const u8 {
        if (self.template_cache.get(name)) |cached| {
            return self.renderString(cached, context);
        }
        const loaded = try self.loader.load(name);
        const cached = try self.allocator.dupe(u8, loaded);
        self.allocator.free(loaded);

        const name_copy = try self.allocator.dupe(u8, name);
        errdefer self.allocator.free(name_copy);

        const gop = self.template_cache.getOrPut(name_copy) catch |err| {
            self.allocator.free(cached);
            return err;
        };
        if (gop.found_existing) {
            // Another thread already cached it (unlikely in single-threaded, but possible on error recovery)
            self.allocator.free(cached);
            return self.renderString(gop.value_ptr.*, context);
        }
        gop.value_ptr.* = cached;
        return self.renderString(cached, context);
    }

    /// Render a template string with context, processing partials recursively
    pub fn renderString(self: *Self, template: []const u8, context: *const Context) TemplateError![]const u8 {
        var result = try self.renderer.render(template, context);
        errdefer self.allocator.free(result);

        // Process partials until none remain
        var has_partials = true;
        while (has_partials) {
            const old = result;
            result = try self.processPartials(result, context, &has_partials);
            self.allocator.free(old);
        }

        return result;
    }

    /// Process all partials in a rendered template
    /// Sets has_partials to false if no partials were found
    fn processPartials(self: *Self, input: []const u8, context: *const Context, has_partials: *bool) TemplateError![]const u8 {
        var result = std.ArrayList(u8).empty;
        errdefer result.deinit(self.allocator);

        has_partials.* = false;
        var i: usize = 0;
        while (i < input.len) {
            if (i + 3 <= input.len and std.mem.eql(u8, input[i..i+3], "{{>")) {
                has_partials.* = true;
                const start = i + 3;
                var end = start;
                while (end < input.len and input[end] != '}') : (end += 1) {}
                while (end < input.len and input[end] == '}') : (end += 1) {}

                const partial_markup = input[start..end];
                const partial_name = std.mem.trim(u8, partial_markup, " \r\n\t}");

                if (std.mem.eql(u8, partial_name, "page")) {
                    if (self.page_content) |content| {
                        try result.appendSlice(self.allocator, content);
                    }
                } else if (!std.mem.eql(u8, partial_name, "(parent)")) {
                    if (self.partials_manager) |*pm| {
                        const partial_content = try pm.loadPartial(partial_name);
                        const rendered = try self.renderString(partial_content, context);
                        errdefer self.allocator.free(rendered);
                        try result.appendSlice(self.allocator, rendered);
                        self.allocator.free(rendered);
                    }
                }
                i = end;
            } else {
                try result.append(self.allocator, input[i]);
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

test "TemplateEngine handles missing variables" {
    const allocator = std.testing.allocator;
    var engine = TemplateEngine.init(allocator, "templates");
    defer engine.deinit();

    var ctx = Context.init(allocator);
    defer ctx.deinit();

    const template = "<h1>{{missing}}</h1>";
    const result = try engine.renderString(template, &ctx);
    defer allocator.free(result);

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
