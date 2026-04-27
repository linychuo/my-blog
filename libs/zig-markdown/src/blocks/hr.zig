//! Horizontal rule rendering - handles ---, ***, ___

const std = @import("std");
const Allocator = std.mem.Allocator;
const ParserState = @import("../parser.zig").ParserState;
const HtmlWriter = @import("../html_writer.zig").HtmlWriter;
const closeParagraphAndLists = @import("../parser.zig").closeParagraphAndLists;
const closeTable = @import("../parser.zig").closeTable;

/// Check if line is a horizontal rule
pub fn isHorizontalRule(line: []const u8) bool {
    const trimmed = std.mem.trim(u8, line, " \r\n\t");
    return std.mem.eql(u8, trimmed, "---") or
        std.mem.eql(u8, trimmed, "***") or
        std.mem.eql(u8, trimmed, "___");
}

/// Render a horizontal rule, closing any open blocks first
pub fn renderHorizontalRule(
    state: *ParserState,
    writer: *HtmlWriter,
    allocator: Allocator,
) !void {
    if (state.in_table) {
        try closeTable(state, writer, allocator);
    }
    try closeParagraphAndLists(state, writer, allocator);
    try writer.write(allocator, "<hr>\n");
}
