//! Paragraph rendering - handles regular text paragraphs

const std = @import("std");
const Allocator = std.mem.Allocator;
const ParserState = @import("../parser.zig").ParserState;
const HtmlWriter = @import("../html_writer.zig").HtmlWriter;
const processInline = @import("../inline.zig").processInline;
const processLineBreaks = @import("../inline.zig").processLineBreaks;

/// Check if line is a paragraph continuation
pub fn isParagraphContinuation(line: []const u8) bool {
    const trimmed = std.mem.trim(u8, line, " \r\n\t");
    return trimmed.len > 0;
}

/// Render opening of paragraph
pub fn renderParagraphOpen(writer: *HtmlWriter, allocator: Allocator) !void {
    try writer.write(allocator, "<p>");
}

/// Render closing of paragraph
pub fn renderParagraphClose(writer: *HtmlWriter, allocator: Allocator) !void {
    try writer.write(allocator, "</p>\n");
}

/// Render paragraph line with inline processing
pub fn renderParagraphLine(
    writer: *HtmlWriter,
    allocator: Allocator,
    line: []const u8,
) !void {
    const trimmed = std.mem.trim(u8, line, " \r\n\t");
    if (trimmed.len == 0) return;

    const processed = try processInline(allocator, trimmed);
    const processed_with_break = try processLineBreaks(allocator, processed);
    try writer.write(allocator, processed_with_break);
    allocator.free(processed);
    if (processed_with_break.ptr != processed.ptr) {
        allocator.free(processed_with_break);
    }
}

/// Render paragraph separator (space between lines in same paragraph)
pub fn renderParagraphSeparator(writer: *HtmlWriter, allocator: Allocator) !void {
    try writer.write(allocator, " ");
}
