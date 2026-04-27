const std = @import("std");
const Allocator = std.mem.Allocator;
const Post = @import("../Post.zig").Post;
const TemplateEngine = @import("zig-handlebars").TemplateEngine;
const Context = @import("zig-handlebars").Context;
const FileSystem = @import("../FileSystem.zig");
const path = @import("../utils/path.zig");
const html = @import("../utils/html.zig");

fn getCurrentYear() []const u8 {
    const timestamp = std.time.timestamp();
    var buf: [5]u8 = undefined;
    const year: i64 = 1970 + @divFloor(timestamp, 31536000);
    return std.fmt.bufPrint(&buf, "{d}", .{year}) catch "2026";
}

pub fn generateTagPages(allocator: Allocator, template_engine: *TemplateEngine, dest_dir: []const u8, posts: []const Post) !void {
    var tag_map = std.StringHashMap(std.ArrayListUnmanaged(Post)).init(allocator);
    defer {
        var it = tag_map.iterator();
        while (it.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            entry.value_ptr.deinit(allocator);
        }
        tag_map.deinit();
    }

    for (posts) |post| {
        var tag_iter = std.mem.tokenizeScalar(u8, post.tags, ' ');
        while (tag_iter.next()) |tag| {
            const tag_copy = try allocator.dupe(u8, tag);
            errdefer allocator.free(tag_copy);
            const gop = try tag_map.getOrPut(tag_copy);
            if (gop.found_existing) {
                allocator.free(tag_copy);
            } else {
                gop.value_ptr.* = .{};
            }
            try gop.value_ptr.append(allocator, post);
        }
    }

    var it = tag_map.iterator();
    while (it.next()) |entry| {
        const tag_name = entry.key_ptr.*;
        const tag_posts = entry.value_ptr;

        var posts_html = std.ArrayList(u8){};
        defer posts_html.deinit(allocator);

        for (tag_posts.items) |post| {
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

        var post_count_buf: [16]u8 = undefined;
        const post_count_str = std.fmt.bufPrint(&post_count_buf, "{d}", .{tag_posts.items.len}) catch "0";

        var page_title_buf: [256]u8 = undefined;
        const page_title_str = std.fmt.bufPrint(&page_title_buf, "Posts tagged with \"{s}\" - ", .{tag_name}) catch "";

        try ctx.set("tag_name", tag_name);
        try ctx.set("post_count", post_count_str);
        try ctx.set("posts", posts_html.items);
        try ctx.set("page_title", page_title_str);
        try ctx.set("year", getCurrentYear());

        const page_html = try template_engine.render("tag.hbs", &ctx);
        defer allocator.free(page_html);

        template_engine.setPageContent(page_html);
        const full_html = try template_engine.render("layout.hbs", &ctx);
        defer allocator.free(full_html);

        var output_filename = std.ArrayList(u8){};
        defer output_filename.deinit(allocator);
        try output_filename.appendSlice(allocator, "tags/");
        try output_filename.appendSlice(allocator, tag_name);
        try output_filename.appendSlice(allocator, ".html");

        try FileSystem.writeHtmlFile(allocator, dest_dir, output_filename.items, full_html);

        std.debug.print("  Generated: tags/{s}.html\n", .{tag_name});
    }
}
