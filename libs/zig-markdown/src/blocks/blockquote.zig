//! Blockquote rendering - handles > quotes

const std = @import("std");
const Allocator = std.mem.Allocator;
const HtmlWriter = @import("../html_writer.zig").HtmlWriter;
const processInline = @import("../inline.zig").processInline;
const processLineBreaks = @import("../inline.zig").processLineBreaks;

/// Check if line is a blockquote
pub fn isBlockquote(line: []const u8) bool {
    const trimmed = std.mem.trim(u8, line, " \r\n\t");
    return std.mem.startsWith(u8, trimmed, "> ");
}

/// Get blockquote content
pub fn getBlockquoteContent(line: []const u8) []const u8 {
    const trimmed = std.mem.trim(u8, line, " \r\n\t");
    return trimmed[2..];
}

/// Render opening of blockquote
pub fn renderBlockquoteOpen(writer: *HtmlWriter, allocator: Allocator) !void {
    try writer.write(allocator, "<blockquote>");
}

/// Render closing of blockquote
pub fn renderBlockquoteClose(writer: *HtmlWriter, allocator: Allocator) !void {
    try writer.write(allocator, "</blockquote>\n");
}

/// Render a blockquote line with inline processing
pub fn renderBlockquoteLine(
    writer: *HtmlWriter,
    allocator: Allocator,
    line: []const u8,
) !void {
    const content = getBlockquoteContent(line);
    const processed = try processInline(allocator, content);
    const processed_with_break = try processLineBreaks(allocator, processed);
    try writer.write(allocator, processed_with_break);
    allocator.free(processed);
    if (processed_with_break.ptr != processed.ptr) {
        allocator.free(processed_with_break);
    }
}
