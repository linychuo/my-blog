//! Zig Markdown - A pure Zig Markdown to HTML converter

const std = @import("std");
const Allocator = std.mem.Allocator;
const ParserState = @import("parser.zig").ParserState;
const HtmlWriter = @import("html_writer.zig").HtmlWriter;
const closeParagraphAndLists = @import("parser.zig").closeParagraphAndLists;
const closeLists = @import("parser.zig").closeLists;
const closeTable = @import("parser.zig").closeTable;
const closeAll = @import("parser.zig").closeAll;
const renderHeader = @import("parser.zig").renderHeader;
const processInline = @import("inline.zig").processInline;
const processLineBreaks = @import("inline.zig").processLineBreaks;
const table = @import("blocks/table.zig");

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
        if (std.mem.startsWith(u8, trimmed, "$$")) {
            if (state.in_math_block) {
                try closeParagraphAndLists(&state, &writer, allocator);
                try writer.write(allocator, "<pre class=\"math-block\">");
                try writer.write(allocator, state.math_buffer.items);
                try writer.write(allocator, "</pre>\n");
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
        if (std.mem.startsWith(u8, trimmed, "```")) {
            if (state.in_code_block) {
                try closeParagraphAndLists(&state, &writer, allocator);
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
            } else {
                try closeParagraphAndLists(&state, &writer, allocator);
                state.in_code_block = true;
                if (trimmed.len > 3) {
                    try state.code_language.appendSlice(allocator, trimmed[3..]);
                    state.code_buffer.clearRetainingCapacity();
                }
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

            // Check if this is a separator line (|---|---|)
            if (table.isTableSeparator(trimmed)) {
                continue; // Skip separator line
            }

            // Parse and render table row
            // First row is header, subsequent rows are body
            try table.renderTableRow(&writer, allocator, trimmed, !state.in_table);
            state.in_table = true;
            continue;
        }

        // Check for indented content (4 spaces = continuation of list item)
        if (line.len >= 4 and std.mem.startsWith(u8, line, "    ") and trimmed.len > 0) {
            if (state.in_table) {
                try closeTable(&state, &writer, allocator);
            }
            if (state.in_list or state.in_ordered_list) {
                const content = std.mem.trimLeft(u8, line, " ");
                if (state.list_item_open) {
                    try writer.write(allocator, "</li>\n");
                    state.list_item_open = false;
                }
                try writer.write(allocator, "<li class=\"continuation\">");
                const processed = try processInline(allocator, content);
                defer allocator.free(processed);
                try writer.write(allocator, processed);
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
                try writer.write(allocator, "</p>\n");
                state.in_paragraph = false;
            }
            if (state.list_item_open) {
                try writer.write(allocator, "</li>\n");
                state.list_item_open = false;
            }
            if (state.in_list) {
                try writer.write(allocator, "</ul>\n");
                state.in_list = false;
            }
            if (state.in_ordered_list) {
                try writer.write(allocator, "</ol>\n");
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
            try writer.write(allocator, "<ul>\n<li>");
            try writer.write(allocator, "<strong>");
            try writer.write(allocator, trimmed[7..]);
            try writer.write(allocator, "</strong>");
            state.list_item_open = true;
            state.in_list = true;
            continue;
        }

        // Headers h1-h6
        {
            var header_matched = false;
            inline for (.{ .{ "#", 1 }, .{ "##", 2 }, .{ "###", 3 }, .{ "####", 4 }, .{ "#####", 5 }, .{ "######", 6 } }) |header| {
                const marker = header[0];
                const level = header[1];
                if (!header_matched and std.mem.startsWith(u8, trimmed, marker ++ " ")) {
                    const content_start = marker.len + 1;
                    try renderHeader(&state, &writer, allocator, level, trimmed[content_start..]);
                    header_matched = true;
                }
            }
            if (header_matched) continue;
        }

        // Ordered list items
        if (std.mem.startsWith(u8, trimmed, "1. ") or
            std.mem.startsWith(u8, trimmed, "2. ") or
            std.mem.startsWith(u8, trimmed, "3. ") or
            std.mem.startsWith(u8, trimmed, "4. ") or
            std.mem.startsWith(u8, trimmed, "5. ") or
            std.mem.startsWith(u8, trimmed, "6. ") or
            std.mem.startsWith(u8, trimmed, "7. ") or
            std.mem.startsWith(u8, trimmed, "8. ") or
            std.mem.startsWith(u8, trimmed, "9. "))
        {
            if (state.in_paragraph) {
                try writer.write(allocator, "</p>\n");
                state.in_paragraph = false;
            }
            if (state.in_list) {
                try writer.write(allocator, "</ul>\n");
                state.in_list = false;
            }
            if (state.list_item_open) {
                try writer.write(allocator, "</li>\n");
                state.list_item_open = false;
            }
            if (!state.in_ordered_list) {
                try writer.write(allocator, "<ol>\n");
                state.in_ordered_list = true;
            }
            var i: usize = 0;
            while (i < trimmed.len and trimmed[i] != ' ') : (i += 1) {}
            if (i < trimmed.len) i += 1;
            try writer.write(allocator, "<li>");
            const processed = try processInline(allocator, trimmed[i..]);
            defer allocator.free(processed);
            try writer.write(allocator, processed);
            state.list_item_open = true;
            continue;
        }

        // Unordered list items
        if (std.mem.startsWith(u8, trimmed, "- ") or
            std.mem.startsWith(u8, trimmed, "* ") or
            std.mem.startsWith(u8, trimmed, "+ "))
        {
            if (state.in_paragraph) {
                try writer.write(allocator, "</p>\n");
                state.in_paragraph = false;
            }
            if (state.in_ordered_list) {
                try writer.write(allocator, "</ol>\n");
                state.in_ordered_list = false;
            }
            if (state.list_item_open) {
                try writer.write(allocator, "</li>\n");
                state.list_item_open = false;
            }
            if (!state.in_list) {
                try writer.write(allocator, "<ul>\n");
                state.in_list = true;
            }
            try writer.write(allocator, "<li>");
            const processed = try processInline(allocator, trimmed[2..]);
            defer allocator.free(processed);
            try writer.write(allocator, processed);
            state.list_item_open = true;
            continue;
        }

        // Blockquote
        if (std.mem.startsWith(u8, trimmed, "> ")) {
            if (state.in_paragraph) {
                try writer.write(allocator, "</p>\n");
                state.in_paragraph = false;
            }
            try closeLists(&state, &writer, allocator);
            if (state.list_item_open) {
                try writer.write(allocator, "</li>\n");
                state.list_item_open = false;
            }
            try writer.write(allocator, "<blockquote>");
            const content = trimmed[2..];
            const processed = try processInline(allocator, content);
            const processed_with_break = try processLineBreaks(allocator, processed);
            try writer.write(allocator, processed_with_break);
            // Free the allocated memory
            allocator.free(processed);
            if (processed_with_break.ptr != processed.ptr) allocator.free(processed_with_break);
            try writer.write(allocator, "</blockquote>\n");
            continue;
        }

        // Horizontal rule
        if (std.mem.eql(u8, trimmed, "---") or
            std.mem.eql(u8, trimmed, "***") or
            std.mem.eql(u8, trimmed, "___"))
        {
            if (state.in_paragraph) {
                try writer.write(allocator, "</p>\n");
                state.in_paragraph = false;
            }
            try closeLists(&state, &writer, allocator);
            if (state.list_item_open) {
                try writer.write(allocator, "</li>\n");
                state.list_item_open = false;
            }
            try writer.write(allocator, "<hr>\n");
            continue;
        }

        // Regular paragraph
        if (!state.in_paragraph) {
            try closeLists(&state, &writer, allocator);
            if (state.list_item_open) {
                try writer.write(allocator, "</li>\n");
                state.list_item_open = false;
            }
            try writer.write(allocator, "<p>");
            state.in_paragraph = true;
        } else {
            try writer.write(allocator, " ");
        }
        const processed = try processInline(allocator, trimmed);
        const processed_with_break = try processLineBreaks(allocator, processed);
        try writer.write(allocator, processed_with_break);
        // Free the allocated memory
        allocator.free(processed);
        if (processed_with_break.ptr != processed.ptr) allocator.free(processed_with_break);
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
