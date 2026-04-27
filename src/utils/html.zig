const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn buildTagsHtml(allocator: Allocator, tags: []const u8) ![]const u8 {
    var html = std.ArrayList(u8){};
    errdefer html.deinit(allocator);

    var tag_iter = std.mem.tokenizeScalar(u8, tags, ' ');
    while (tag_iter.next()) |tag| {
        try html.appendSlice(allocator, "<a href=\"/tags/");
        try html.appendSlice(allocator, tag);
        try html.appendSlice(allocator, ".html\" class=\"article-tag\">");
        try html.appendSlice(allocator, tag);
        try html.appendSlice(allocator, "</a>");
    }

    return html.toOwnedSlice(allocator);
}

pub fn buildPostItemHtml(allocator: Allocator, title: []const u8, post_path: []const u8, date_time: []const u8, tags_html: []const u8) ![]const u8 {
    var html = std.ArrayList(u8){};
    errdefer html.deinit(allocator);

    try html.appendSlice(allocator, "<li class=\"post-item\"><div class=\"post-title\"><a href=\"/");
    try html.appendSlice(allocator, post_path);
    try html.appendSlice(allocator, "\">");
    try html.appendSlice(allocator, title);
    try html.appendSlice(allocator, "</a></div><div class=\"post-meta\"><time class=\"post-date\" datetime=\"");
    try html.appendSlice(allocator, date_time);
    try html.appendSlice(allocator, "\">");
    try html.appendSlice(allocator, date_time);
    try html.appendSlice(allocator, "</time>");
    try html.appendSlice(allocator, tags_html);
    try html.appendSlice(allocator, "</div></li>\n");

    return html.toOwnedSlice(allocator);
}
