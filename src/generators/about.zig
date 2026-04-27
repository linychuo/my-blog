const std = @import("std");
const Allocator = std.mem.Allocator;
const markdown = @import("zig-markdown");
const TemplateEngine = @import("zig-handlebars").TemplateEngine;
const Context = @import("zig-handlebars").Context;
const FileSystem = @import("../FileSystem.zig");

fn getCurrentYear() []const u8 {
    const timestamp = std.time.timestamp();
    var buf: [5]u8 = undefined;
    const year: i64 = 1970 + @divFloor(timestamp, 31536000);
    return std.fmt.bufPrint(&buf, "{d}", .{year}) catch "2026";
}

pub fn generateAbout(allocator: Allocator, template_engine: *TemplateEngine, dest_dir: []const u8, posts_dir: []const u8) !void {
    const about_path = try std.fs.path.join(allocator, &.{ posts_dir, "about.markdown" });
    defer allocator.free(about_path);

    const file = std.fs.cwd().openFile(about_path, .{}) catch {
        std.debug.print("  Skipped: about.markdown not found\n", .{});
        return;
    };
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(content);

    const html_content = try markdown.toHtml(allocator, content);
    defer allocator.free(html_content);

    var ctx = Context.init(allocator);
    defer ctx.deinit();

    try ctx.set("title", "About");
    try ctx.set("content", html_content);
    try ctx.set("page_title", "");
    try ctx.set("year", getCurrentYear());
    try ctx.set("tags", "");

    const page_html = try template_engine.render("about.hbs", &ctx);
    defer allocator.free(page_html);

    template_engine.setPageContent(page_html);
    const full_html = try template_engine.render("layout.hbs", &ctx);
    defer allocator.free(full_html);

    try FileSystem.writeHtmlFile(allocator, dest_dir, "about.html", full_html);

    std.debug.print("  Generated: about.html\n", .{});
}
