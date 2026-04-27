//! Math block rendering - handles $$ math blocks

const std = @import("std");
const Allocator = std.mem.Allocator;
const ParserState = @import("../parser.zig").ParserState;
const HtmlWriter = @import("../html_writer.zig").HtmlWriter;

/// Check if line is a math block delimiter
pub fn isMathBlockDelimiter(line: []const u8) bool {
    const trimmed = std.mem.trim(u8, line, " \r\n\t");
    return std.mem.startsWith(u8, trimmed, "$$");
}

/// Get math block content (line between opening and closing $$)
pub fn getMathBlockContent(line: []const u8) []const u8 {
    const trimmed = std.mem.trim(u8, line, " \r\n\t");
    if (trimmed.len > 2) {
        return trimmed[2..];
    }
    return "";
}

/// Render opening of math block
pub fn renderMathBlockOpen(writer: *HtmlWriter, allocator: Allocator) !void {
    try writer.write(allocator, "<pre class=\"math-block\">");
}

/// Render closing of math block
pub fn renderMathBlockClose(writer: *HtmlWriter, allocator: Allocator) !void {
    try writer.write(allocator, "</pre>\n");
}

/// Render the math block content
pub fn renderMathContent(
    state: *ParserState,
    writer: *HtmlWriter,
    allocator: Allocator,
) !void {
    try writer.write(allocator, state.math_buffer.items);
}
