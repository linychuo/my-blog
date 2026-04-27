//! Markdown Parser - Encapsulates parsing state and logic

const std = @import("std");
const Allocator = std.mem.Allocator;
const HtmlWriter = @import("html_writer.zig").HtmlWriter;

/// Parser state for tracking markdown context
pub const ParserState = struct {
    in_paragraph: bool = false,
    in_code_block: bool = false,
    in_math_block: bool = false,
    in_list: bool = false,
    in_ordered_list: bool = false,
    in_table: bool = false,
    list_item_open: bool = false,

    code_buffer: std.ArrayList(u8) = .{},
    code_language: std.ArrayList(u8) = .{},
    math_buffer: std.ArrayList(u8) = .{},

    pub fn deinit(self: *ParserState, allocator: Allocator) void {
        self.code_buffer.deinit(allocator);
        self.code_language.deinit(allocator);
        self.math_buffer.deinit(allocator);
    }

    pub fn resetBuffers(self: *ParserState) void {
        self.code_buffer.clearRetainingCapacity();
        self.code_language.clearRetainingCapacity();
        self.math_buffer.clearRetainingCapacity();
    }

    /// Append to buffer with newline handling
    pub fn appendToBuffer(buffer: *std.ArrayList(u8), allocator: Allocator, content: []const u8) !void {
        if (buffer.items.len > 0) try buffer.append(allocator, '\n');
        try buffer.appendSlice(allocator, content);
    }

    /// Returns true if currently in any list context
    pub fn inList(self: *const ParserState) bool {
        return self.in_list or self.in_ordered_list;
    }

    /// Close any open list item (used when transitioning between list types or ending list)
    pub fn closeListItem(state: *ParserState, writer: *HtmlWriter, allocator: Allocator) !void {
        if (state.list_item_open) {
            try writer.write(allocator, "</li>\n");
            state.list_item_open = false;
        }
    }
};

/// Close all open list tags
pub fn closeLists(state: *ParserState, writer: *HtmlWriter, allocator: Allocator) !void {
    if (state.in_list) {
        try writer.write(allocator, "</ul>\n");
        state.in_list = false;
    }
    if (state.in_ordered_list) {
        try writer.write(allocator, "</ol>\n");
        state.in_ordered_list = false;
    }
}

/// Close paragraph and lists - extracted common pattern
pub fn closeParagraphAndLists(state: *ParserState, writer: *HtmlWriter, allocator: Allocator) !void {
    if (state.in_paragraph) {
        try writer.write(allocator, "</p>\n");
        state.in_paragraph = false;
    }
    try closeLists(state, writer, allocator);
    if (state.list_item_open) {
        try writer.write(allocator, "</li>\n");
        state.list_item_open = false;
    }
}

/// Close table if open
pub fn closeTable(state: *ParserState, writer: *HtmlWriter, allocator: Allocator) !void {
    if (state.in_table) {
        try writer.write(allocator, "</tbody>\n</table>\n");
        state.in_table = false;
    }
}

/// Close all open tags at end of parsing
pub fn closeAll(state: *ParserState, writer: *HtmlWriter, allocator: Allocator) !void {
    // Close unclosed math block
    if (state.in_math_block and state.math_buffer.items.len > 0) {
        try writer.write(allocator, "<pre class=\"math-block\">");
        try writer.write(allocator, state.math_buffer.items);
        try writer.write(allocator, "</pre>\n");
    }
    // Close unclosed code block
    if (state.in_code_block and state.code_buffer.items.len > 0) {
        try writer.write(allocator, "<pre><code");
        if (state.code_language.items.len > 0) {
            try writer.write(allocator, " class=\"language-");
            try writer.write(allocator, state.code_language.items);
            try writer.write(allocator, "\"");
        }
        try writer.write(allocator, ">");
        try writer.write(allocator, state.code_buffer.items);
        try writer.write(allocator, "</code></pre>\n");
    }
    // Close paragraph
    if (state.in_paragraph) {
        try writer.write(allocator, "</p>\n");
    }
    // Close lists
    try closeLists(state, writer, allocator);
    // Close any remaining code buffer
    if (state.code_buffer.items.len > 0) {
        try writer.write(allocator, "<pre><code>");
        try writer.write(allocator, state.code_buffer.items);
        try writer.write(allocator, "</code></pre>\n");
    }
    // Close table
    try closeTable(state, writer, allocator);
}
