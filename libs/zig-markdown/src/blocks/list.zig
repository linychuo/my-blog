//! List block rendering - handles ordered and unordered lists

const std = @import("std");
const Allocator = std.mem.Allocator;
const HtmlWriter = @import("../html_writer.zig").HtmlWriter;
const processInline = @import("../inline.zig").processInline;

/// Detect if line is an unordered list item (-, *, +)
pub fn isUnorderedListItem(line: []const u8) bool {
    const trimmed = std.mem.trim(u8, line, " \r\n\t");
    return std.mem.startsWith(u8, trimmed, "- ") or
        std.mem.startsWith(u8, trimmed, "* ") or
        std.mem.startsWith(u8, trimmed, "+ ");
}

/// Get unordered list item content
pub fn getUnorderedListContent(line: []const u8) []const u8 {
    const trimmed = std.mem.trim(u8, line, " \r\n\t");
    return trimmed[2..];
}

/// Detect if line is an ordered list item (1., 2., etc.)
pub fn isOrderedListItem(line: []const u8) ?usize {
    const trimmed = std.mem.trim(u8, line, " \r\n\t");
    var j: usize = 0;
    while (j < trimmed.len and trimmed[j] >= '0' and trimmed[j] <= '9') : (j += 1) {}
    if (j > 0 and j < trimmed.len and trimmed[j] == '.' and j + 1 < trimmed.len and trimmed[j + 1] == ' ') {
        return std.fmt.parseInt(usize, trimmed[0..j], 10) catch 0;
    }
    return null;
}

/// Get ordered list item content
pub fn getOrderedListContent(line: []const u8) []const u8 {
    const trimmed = std.mem.trim(u8, line, " \r\n\t");
    var i: usize = 0;
    while (i < trimmed.len and trimmed[i] != ' ') : (i += 1) {}
    if (i < trimmed.len) i += 1;
    return trimmed[i..];
}

/// Render opening of unordered list
pub fn renderUnorderedListOpen(writer: *HtmlWriter, allocator: Allocator) !void {
    try writer.write(allocator, "<ul>\n");
}

/// Render opening of ordered list
pub fn renderOrderedListOpen(writer: *HtmlWriter, allocator: Allocator) !void {
    try writer.write(allocator, "<ol>\n");
}

/// Render closing of unordered list
pub fn renderUnorderedListClose(writer: *HtmlWriter, allocator: Allocator) !void {
    try writer.write(allocator, "</ul>\n");
}

/// Render closing of ordered list
pub fn renderOrderedListClose(writer: *HtmlWriter, allocator: Allocator) !void {
    try writer.write(allocator, "</ol>\n");
}

/// Render opening of list item
pub fn renderListItemOpen(writer: *HtmlWriter, allocator: Allocator) !void {
    try writer.write(allocator, "<li>");
}

/// Render closing of list item
pub fn renderListItemClose(writer: *HtmlWriter, allocator: Allocator) !void {
    try writer.write(allocator, "</li>\n");
}

/// Render a list item with inline processing
pub fn renderUnorderedListItem(
    writer: *HtmlWriter,
    allocator: Allocator,
    line: []const u8,
) !void {
    const content = getUnorderedListContent(line);
    try renderListItemOpen(writer, allocator);
    const processed = try processInline(allocator, content);
    defer allocator.free(processed);
    try writer.write(allocator, processed);
    try renderListItemClose(writer, allocator);
}

/// Render an ordered list item with inline processing
pub fn renderOrderedListItem(
    writer: *HtmlWriter,
    allocator: Allocator,
    line: []const u8,
) !void {
    const content = getOrderedListContent(line);
    try renderListItemOpen(writer, allocator);
    const processed = try processInline(allocator, content);
    defer allocator.free(processed);
    try writer.write(allocator, processed);
    try renderListItemClose(writer, allocator);
}
