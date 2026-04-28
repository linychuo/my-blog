const std = @import("std");
const Allocator = std.mem.Allocator;
const markdown = @import("zig-markdown");
const Post = @import("../Post.zig").Post;
const TemplateEngine = @import("zig-handlebars").TemplateEngine;
const Context = @import("zig-handlebars").Context;
const FileSystem = @import("../FileSystem.zig");
const path = @import("../utils/path.zig");
const html = @import("../utils/html.zig");
const datetime = @import("../utils/datetime.zig");

pub fn generatePostPage(allocator: Allocator, template_engine: *TemplateEngine, dest_dir: []const u8, post: Post) !void {
    const html_content = try markdown.toHtml(allocator, post.content);
    defer allocator.free(html_content);

    var ctx = Context.init(allocator);
    defer ctx.deinit();

    try ctx.set("title", post.title);
    try ctx.set("date_time", post.date_time);
    try ctx.set("content", html_content);

    const tags_html = try html.buildTagsHtml(allocator, post.tags);
    defer allocator.free(tags_html);
    try ctx.set("tags", tags_html);

    var full_title = std.ArrayList(u8){};
    defer full_title.deinit(allocator);
    try full_title.appendSlice(allocator, post.title);
    try full_title.appendSlice(allocator, " - ");
    try ctx.set("page_title", full_title.items);
    try ctx.set("year", datetime.getCurrentYear());

    const page_html = try template_engine.render("post.hbs", &ctx);
    defer allocator.free(page_html);

    template_engine.setPageContent(page_html);
    const full_html = try template_engine.render("layout.hbs", &ctx);
    defer allocator.free(full_html);

    const post_path = try path.buildPostPath(allocator, post.filename, post.date_time);
    defer allocator.free(post_path);

    try FileSystem.writeHtmlFile(allocator, dest_dir, post_path, full_html);
}
