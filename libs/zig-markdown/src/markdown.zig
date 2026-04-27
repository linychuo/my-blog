//! Zig Markdown - A pure Zig Markdown to HTML converter

const std = @import("std");
const Allocator = std.mem.Allocator;
const ParserState = @import("parser.zig").ParserState;
const HtmlWriter = @import("html_writer.zig").HtmlWriter;
const closeParagraphAndLists = @import("parser.zig").closeParagraphAndLists;
const closeLists = @import("parser.zig").closeLists;
const closeTable = @import("parser.zig").closeTable;
const closeAll = @import("parser.zig").closeAll;

// Block processors
const table = @import("blocks/table.zig");
const header = @import("blocks/header.zig");
const hr = @import("blocks/hr.zig");
const code_block = @import("blocks/code_block.zig");
const list = @import("blocks/list.zig");
const blockquote = @import("blocks/blockquote.zig");
const paragraph = @import("blocks/paragraph.zig");
const math_block = @import("blocks/math_block.zig");

/// Convert markdown text to HTML
pub fn toHtml(allocator: Allocator, markdown: []const u8) ![]const u8 {
    var result = try std.ArrayList(u8).initCapacity(allocator, 0);
    errdefer result.deinit(allocator);

    var state = ParserState{};
    defer state.deinit(allocator);

    var writer = HtmlWriter.init(&result);

    var lines = std.mem.splitScalar(u8, markdown, '\n');

    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \r\n\t");

        // Math block toggle with $$
        if (math_block.isMathBlockDelimiter(line)) {
            if (state.in_math_block) {
                try closeParagraphAndLists(&state, &writer, allocator);
                try math_block.renderMathBlockOpen(&writer, allocator);
                try math_block.renderMathContent(&state, &writer, allocator);
                try math_block.renderMathBlockClose(&writer, allocator);
                state.math_buffer.clearRetainingCapacity();
                state.in_math_block = false;
            } else {
                try closeParagraphAndLists(&state, &writer, allocator);
                state.in_math_block = true;
            }
            continue;
        }

        // Inside math block
        if (state.in_math_block) {
            try ParserState.appendToBuffer(&state.math_buffer, allocator, trimmed);
            continue;
        }

        // Code block toggle with language
        if (code_block.isCodeBlockDelimiter(line)) {
            if (state.in_code_block) {
                try closeParagraphAndLists(&state, &writer, allocator);
                try code_block.renderCodeBlockClose(&state, &writer, allocator);
            } else {
                try closeParagraphAndLists(&state, &writer, allocator);
                state.in_code_block = true;
                const t = std.mem.trim(u8, line, " \r\n\t");
                if (t.len > 3) {
                    try state.code_language.appendSlice(allocator, t[3..]);
                }
                state.code_buffer.clearRetainingCapacity();
            }
            continue;
        }

        // Inside code block
        if (state.in_code_block) {
            try ParserState.appendToBuffer(&state.code_buffer, allocator, line);
            continue;
        }

        // Check for markdown table
        if (std.mem.startsWith(u8, trimmed, "|")) {
            try closeParagraphAndLists(&state, &writer, allocator);

            if (table.isTableSeparator(trimmed)) {
                continue;
            }

            try table.renderTableRow(&writer, allocator, trimmed, !state.in_table);
            state.in_table = true;
            continue;
        }

        // Check for indented content (4 spaces = continuation of list item)
        if (line.len >= 4 and std.mem.startsWith(u8, line, "    ") and trimmed.len > 0) {
            if (state.in_table) {
                try closeTable(&state, &writer, allocator);
            }
            if (state.inList()) {
                const content = std.mem.trimLeft(u8, line, " ");
                if (state.list_item_open) {
                    try writer.write(allocator, "</li>\n");
                    state.list_item_open = false;
                }
                try writer.write(allocator, "<li class=\"continuation\">");
                try writer.write(allocator, content);
                try writer.write(allocator, "</li>\n");
                continue;
            } else {
                try closeParagraphAndLists(&state, &writer, allocator);
                if (state.code_buffer.items.len == 0) {
                    try writer.write(allocator, "<pre><code>");
                }
                try state.code_buffer.appendSlice(allocator, trimmed);
                continue;
            }
        }

        // Empty line ends paragraph, list, and table
        if (trimmed.len == 0) {
            if (state.in_table) {
                try closeTable(&state, &writer, allocator);
            }
            if (state.in_paragraph) {
                try paragraph.renderParagraphClose(&writer, allocator);
                state.in_paragraph = false;
            }
            if (state.list_item_open) {
                try list.renderListItemClose(&writer, allocator);
                state.list_item_open = false;
            }
            if (state.in_list) {
                try list.renderUnorderedListClose(&writer, allocator);
                state.in_list = false;
            }
            if (state.in_ordered_list) {
                try list.renderOrderedListClose(&writer, allocator);
                state.in_ordered_list = false;
            }
            if (state.code_buffer.items.len > 0) {
                try writer.write(allocator, state.code_buffer.items);
                try writer.write(allocator, "</code></pre>\n");
                state.code_buffer.clearRetainingCapacity();
            }
            continue;
        }

        // Headers - #### (special list header)
        if (std.mem.startsWith(u8, trimmed, "- #### ")) {
            if (state.in_table) {
                try closeTable(&state, &writer, allocator);
            }
            try closeParagraphAndLists(&state, &writer, allocator);
            try list.renderUnorderedListOpen(&writer, allocator);
            try list.renderListItemOpen(&writer, allocator);
            try writer.write(allocator, "<strong>");
            try writer.write(allocator, trimmed[7..]);
            try writer.write(allocator, "</strong>");
            state.list_item_open = true;
            state.in_list = true;
            continue;
        }

        // Headers h1-h6
        if (header.detectHeader(line) > 0) {
            const level = header.detectHeader(line);
            const content = header.getHeaderContent(line, level);
            try header.renderHeader(&state, &writer, allocator, level, content);
            continue;
        }

        // Ordered list items
        if (list.isOrderedListItem(line)) |list_num| {
            if (list_num > 0) {
                if (state.in_paragraph) {
                    try paragraph.renderParagraphClose(&writer, allocator);
                    state.in_paragraph = false;
                }
                if (state.in_list) {
                    try list.renderUnorderedListClose(&writer, allocator);
                    state.in_list = false;
                }
                if (state.list_item_open) {
                    try list.renderListItemClose(&writer, allocator);
                    state.list_item_open = false;
                }
                if (!state.in_ordered_list) {
                    try list.renderOrderedListOpen(&writer, allocator);
                    state.in_ordered_list = true;
                }
                try list.renderOrderedListItem(&writer, allocator, line);
                state.list_item_open = true;
                continue;
            }
        }

        // Unordered list items
        if (list.isUnorderedListItem(line)) {
            if (state.in_paragraph) {
                try paragraph.renderParagraphClose(&writer, allocator);
                state.in_paragraph = false;
            }
            if (state.in_ordered_list) {
                try list.renderOrderedListClose(&writer, allocator);
                state.in_ordered_list = false;
            }
            if (state.list_item_open) {
                try list.renderListItemClose(&writer, allocator);
                state.list_item_open = false;
            }
            if (!state.in_list) {
                try list.renderUnorderedListOpen(&writer, allocator);
                state.in_list = true;
            }
            try list.renderUnorderedListItem(&writer, allocator, line);
            state.list_item_open = true;
            continue;
        }

        // Blockquote
        if (blockquote.isBlockquote(line)) {
            if (state.in_paragraph) {
                try paragraph.renderParagraphClose(&writer, allocator);
                state.in_paragraph = false;
            }
            try closeLists(&state, &writer, allocator);
            if (state.list_item_open) {
                try list.renderListItemClose(&writer, allocator);
                state.list_item_open = false;
            }
            try blockquote.renderBlockquoteOpen(&writer, allocator);
            try blockquote.renderBlockquoteLine(&writer, allocator, line);
            try blockquote.renderBlockquoteClose(&writer, allocator);
            continue;
        }

        // Horizontal rule
        if (hr.isHorizontalRule(line)) {
            if (state.in_paragraph) {
                try paragraph.renderParagraphClose(&writer, allocator);
                state.in_paragraph = false;
            }
            try closeLists(&state, &writer, allocator);
            if (state.list_item_open) {
                try list.renderListItemClose(&writer, allocator);
                state.list_item_open = false;
            }
            try hr.renderHorizontalRule(&state, &writer, allocator);
            continue;
        }

        // Regular paragraph
        if (!state.in_paragraph) {
            try closeLists(&state, &writer, allocator);
            if (state.list_item_open) {
                try list.renderListItemClose(&writer, allocator);
                state.list_item_open = false;
            }
            try paragraph.renderParagraphOpen(&writer, allocator);
            state.in_paragraph = true;
        } else {
            try paragraph.renderParagraphSeparator(&writer, allocator);
        }
        try paragraph.renderParagraphLine(&writer, allocator, trimmed);
    }

    // Close any open tags
    try closeAll(&state, &writer, allocator);

    return result.toOwnedSlice(allocator);
}

test "toHtml basic" {
    const allocator = std.testing.allocator;
    const markdown = "# Hello\n\nThis is a **bold** text.";
    const html = try toHtml(allocator, markdown);
    defer allocator.free(html);

    try std.testing.expect(std.mem.indexOf(u8, html, "<h1>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<strong>") != null);
}

test "toHtml code block" {
    const allocator = std.testing.allocator;
    const markdown =
        \\```zig
        \\pub fn main() void {}
        \\```
    ;
    const html = try toHtml(allocator, markdown);
    defer allocator.free(html);

    try std.testing.expect(std.mem.indexOf(u8, html, "<pre><code") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "language-zig") != null);
}

test "toHtml UTF-8 Chinese" {
    const allocator = std.testing.allocator;
    const markdown = "这是 `SELECT` 测试（中文括号）。";
    const html = try toHtml(allocator, markdown);
    defer allocator.free(html);

    try std.testing.expect(std.mem.indexOf(u8, html, "<code>SELECT</code>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "（") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "）") != null);
}

test "toHtml table" {
    const allocator = std.testing.allocator;
    const markdown =
        \\| Column 1 | Column 2 |
        \\|----------|----------|
        \\| A        | B        |
    ;
    const html = try toHtml(allocator, markdown);
    defer allocator.free(html);

    try std.testing.expect(std.mem.indexOf(u8, html, "<table>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<th>Column 1</th>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<td>A</td>") != null);
}

test "toHtml math block" {
    const allocator = std.testing.allocator;
    const markdown = "$$\\int_0^1 x dx$$";
    const html = try toHtml(allocator, markdown);
    defer allocator.free(html);

    try std.testing.expect(std.mem.indexOf(u8, html, "<pre class=\"math-block\">") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "\\int_0^1 x dx") != null);
}

test "toHtml nested lists" {
    const allocator = std.testing.allocator;
    const markdown =
        \\- Item 1
        \\- Item 2
        \\    - Subitem 2.1
        \\    - Subitem 2.2
        \\- Item 3
    ;
    const html = try toHtml(allocator, markdown);
    defer allocator.free(html);

    try std.testing.expect(std.mem.indexOf(u8, html, "<ul>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "Subitem 2.1") != null);
}

test "toHtml multiple headers" {
    const allocator = std.testing.allocator;
    const markdown =
        \\# H1
        \\## H2
        \\### H3
        \\#### H4
        \\##### H5
        \\###### H6
    ;
    const html = try toHtml(allocator, markdown);
    defer allocator.free(html);

    try std.testing.expect(std.mem.indexOf(u8, html, "<h1>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<h2>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<h3>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<h4>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<h5>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<h6>") != null);
}

test "toHtml strikethrough" {
    const allocator = std.testing.allocator;
    const markdown = "~~deleted~~";
    const html = try toHtml(allocator, markdown);
    defer allocator.free(html);

    try std.testing.expect(std.mem.indexOf(u8, html, "<del>deleted</del>") != null);
}

test "toHtml image" {
    const allocator = std.testing.allocator;
    const markdown = "![alt text](image.png)";
    const html = try toHtml(allocator, markdown);
    defer allocator.free(html);

    try std.testing.expect(std.mem.indexOf(u8, html, "<img src=\"image.png\" alt=\"alt text\">") != null);
}

test "toHtml line break" {
    const allocator = std.testing.allocator;
    const markdown = "line1\\\nline2";
    const html = try toHtml(allocator, markdown);
    defer allocator.free(html);

    try std.testing.expect(std.mem.indexOf(u8, html, "<br>") != null);
}
