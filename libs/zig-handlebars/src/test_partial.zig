//! Example demonstrating partials and template rendering

const std = @import("std");
const handlebars = @import("zig-handlebars");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Initialize engine with templates directory
    var engine = handlebars.TemplateEngine.init(allocator, "templates");
    defer engine.deinit();

    // Enable partials support
    engine.enablePartials("templates/partials");

    // Create context with variables
    var ctx = handlebars.Context.init(allocator);
    defer ctx.deinit();

    try ctx.set("title", "Welcome to Zig Handlebars");
    try ctx.set("content", "<p>This is <strong>HTML</strong> content</p>");
    try ctx.set("author", "Zig Developer");

    // Example 1: Simple template with variables (HTML escaped by default)
    {
        const template =
            \\<article>
            \\  <h1>{{title}}</h1>
            \\  <p>By {{author}}</p>
            \\  <div>{{content}}</div>
            \\</article>
        ;
        const result = try engine.renderString(template, &ctx);
        defer allocator.free(result);
        std.debug.print("=== Example 1: Escaped Output ===\n{s}\n\n", .{result});
    }

    // Example 2: Unescaped HTML with triple braces
    {
        const template =
            \\<article>
            \\  <h1>{{title}}</h1>
            \\  <div class="content">{{{content}}}</div>
            \\</article>
        ;
        const result = try engine.renderString(template, &ctx);
        defer allocator.free(result);
        std.debug.print("=== Example 2: Unescaped HTML ===\n{s}\n\n", .{result});
    }

    // Example 3: Using partials
    {
        const template = "<header>{{> test}}</header><main>{{title}}</main>";
        const result = try engine.renderString(template, &ctx);
        defer allocator.free(result);
        std.debug.print("=== Example 3: Partials ===\n{s}\n\n", .{result});
    }

    // Example 4: Template inheritance
    {
        engine.setPageContent("<h1>Child Page Content</h1><p>Details here</p>");
        const template =
            \\<html>
            \\  <body>
            \\    <header>My Site</header>
            \\    <main>{{> page}}</main>
            \\    <footer>{{> test}}</footer>
            \\  </body>
            \\</html>
        ;
        const result = try engine.renderString(template, &ctx);
        defer allocator.free(result);
        std.debug.print("=== Example 4: Template Inheritance ===\n{s}\n\n", .{result});
    }

    // Example 5: XSS protection demonstration
    {
        var xss_ctx = handlebars.Context.init(allocator);
        defer xss_ctx.deinit();

        try xss_ctx.set("user_input", "<script>alert('XSS')</script>");

        const template = "<div>{{user_input}}</div>";
        const result = try engine.renderString(template, &xss_ctx);
        defer allocator.free(result);

        std.debug.print("=== Example 5: XSS Protection ===\n", .{});
        std.debug.print("Input: <script>alert('XSS')</script>\n", .{});
        std.debug.print("Output: {s}\n\n", .{result});
    }
}
