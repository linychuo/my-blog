//! Header rendering - handles # headers

const std = @import("std");
const Allocator = std.mem.Allocator;
const ParserState = @import("../parser.zig").ParserState;
const HtmlWriter = @import("../html_writer.zig").HtmlWriter;
const closeParagraphAndLists = @import("../parser.zig").closeParagraphAndLists;
const closeTable = @import("../parser.zig").closeTable;
const processInline = @import("../inline.zig").processInline;

pub const HeaderProcessor = struct {};

/// Check if line is a header and return header level (0 if not a header)
pub fn detectHeader(line: []const u8) usize {
    const trimmed = std.mem.trim(u8, line, " \r\n\t");
    inline for (.{ "###### ", "##### ", "#### ", "### ", "## ", "# " }, .{ 6, 5, 4, 3, 2, 1 }) |marker, level| {
        if (std.mem.startsWith(u8, trimmed, marker)) {
            return level;
        }
    }
    return 0;
}

/// Get header content from line
pub fn getHeaderContent(line: []const u8, level: usize) []const u8 {
    const trimmed = std.mem.trim(u8, line, " \r\n\t");
    const marker_len = level + 1; // "#" + space
    return trimmed[marker_len..];
}

/// Render a header at the given level
pub fn renderHeader(
    state: *ParserState,
    writer: *HtmlWriter,
    allocator: Allocator,
    level: usize,
    content: []const u8,
) !void {
    if (level < 1 or level > 6) return;

    if (state.in_table) {
        try closeTable(state, writer, allocator);
    }
    try closeParagraphAndLists(state, writer, allocator);

    const tag = try std.fmt.allocPrint(allocator, "h{}", .{level});
    defer allocator.free(tag);

    try writer.write(allocator, "<");
    try writer.write(allocator, tag);
    try writer.write(allocator, ">");

    const processed = try processInline(allocator, content);
    defer allocator.free(processed);
    try writer.write(allocator, processed);

    try writer.write(allocator, "</");
    try writer.write(allocator, tag);
    try writer.write(allocator, ">\n");
}
