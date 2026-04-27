//! Code block rendering - handles ``` fenced code blocks

const std = @import("std");
const Allocator = std.mem.Allocator;
const HtmlWriter = @import("../html_writer.zig").HtmlWriter;
const ParserState = @import("../parser.zig").ParserState;

/// Check if line is a code block delimiter
pub fn isCodeBlockDelimiter(line: []const u8) bool {
    const trimmed = std.mem.trim(u8, line, " \r\n\t");
    return std.mem.startsWith(u8, trimmed, "```");
}

/// Render closing of code block
pub fn renderCodeBlockClose(
    state: *ParserState,
    writer: *HtmlWriter,
    allocator: Allocator,
) !void {
    try writer.write(allocator, "<pre><code");
    if (state.code_language.items.len > 0) {
        try writer.write(allocator, " class=\"language-");
        try writer.write(allocator, state.code_language.items);
        try writer.write(allocator, "\"");
    }
    try writer.write(allocator, ">");
    try writer.write(allocator, state.code_buffer.items);
    try writer.write(allocator, "</code></pre>\n");
    state.code_buffer.clearRetainingCapacity();
    state.code_language.clearRetainingCapacity();
    state.in_code_block = false;
}
