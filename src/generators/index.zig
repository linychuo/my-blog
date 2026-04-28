const std = @import("std");
const Allocator = std.mem.Allocator;
const Post = @import("../Post.zig").Post;
const TemplateEngine = @import("zig-handlebars").TemplateEngine;
const Context = @import("zig-handlebars").Context;
const FileSystem = @import("../FileSystem.zig");
const path = @import("../utils/path.zig");
const html = @import("../utils/html.zig");
const datetime = @import("../utils/datetime.zig");

pub fn generateIndex(allocator: Allocator, template_engine: *TemplateEngine, dest_dir: []const u8, posts: []const Post) !void {
    var posts_html = std.ArrayList(u8){};
    defer posts_html.deinit(allocator);

    for (posts) |post| {
        const post_path = try path.buildPostPath(allocator, post.filename, post.date_time);
        defer allocator.free(post_path);

        const tags_html = try html.buildTagsHtml(allocator, post.tags);
        defer allocator.free(tags_html);

        const post_item_html = try html.buildPostItemHtml(allocator, post.title, post_path, post.date_time, tags_html);
        defer allocator.free(post_item_html);

        try posts_html.appendSlice(allocator, post_item_html);
    }

    var ctx = Context.init(allocator);
    defer ctx.deinit();
    try ctx.set("subtitle", "Software development, technology, and more");
    try ctx.set("posts", posts_html.items);
    try ctx.set("page_title", "");
    try ctx.set("year", datetime.getCurrentYear());

    const page_html = try template_engine.render("index.hbs", &ctx);
    defer allocator.free(page_html);

    template_engine.setPageContent(page_html);
    const html_content = try template_engine.render("layout.hbs", &ctx);
    defer allocator.free(html_content);
    std.debug.print("DEBUG layout output: {s}\n", .{html_content});

    try FileSystem.writeHtmlFile(allocator, dest_dir, "index.html", html_content);

    std.debug.print("  Generated: index.html\n", .{});
}
