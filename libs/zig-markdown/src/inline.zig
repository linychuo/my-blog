//! Inline Markdown Processing - Handles inline elements like bold, italic, links, etc.

const std = @import("std");
const Allocator = std.mem.Allocator;

const DelimitedResult = struct {
    found: bool,
    content: []const u8,
    end_pos: usize,
};

/// Parse a delimited inline element (e.g., **text**, ~~text~~)
fn parseDelimited(
    text: []const u8,
    pos: usize,
    open_delim: []const u8,
    close_delim: []const u8,
) DelimitedResult {
    if (pos + open_delim.len + close_delim.len > text.len) {
        return .{ .found = false, .content = "", .end_pos = pos };
    }

    for (open_delim, 0..) |c, idx| {
        if (text[pos + idx] != c) {
            return .{ .found = false, .content = "", .end_pos = pos };
        }
    }

    const content_start = pos + open_delim.len;
    var i = content_start;

    while (i + close_delim.len <= text.len) {
        var match = true;
        for (close_delim, 0..) |c, idx| {
            if (text[i + idx] != c) {
                match = false;
                break;
            }
        }
        if (match) {
            return .{
                .found = true,
                .content = text[content_start..i],
                .end_pos = i + close_delim.len,
            };
        }
        i += 1;
    }

    return .{ .found = false, .content = "", .end_pos = pos };
}

/// Process inline markdown elements - UTF-8 safe version
pub fn processInline(allocator: Allocator, text: []const u8) ![]const u8 {
    var result = try std.ArrayList(u8).initCapacity(allocator, text.len);
    errdefer result.deinit(allocator);

    var i: usize = 0;
    while (i < text.len) {
        // Bold: **text**
        if (i + 1 < text.len and text[i] == '*' and text[i + 1] == '*') {
            const delim = parseDelimited(text, i, "**", "**");
            if (delim.found) {
                try result.appendSlice(allocator, "<strong>");
                try result.appendSlice(allocator, delim.content);
                try result.appendSlice(allocator, "</strong>");
                i = delim.end_pos;
                continue;
            }
        }

        // Strikethrough: ~~text~~
        if (i + 1 < text.len and text[i] == '~' and text[i + 1] == '~') {
            const delim = parseDelimited(text, i, "~~", "~~");
            if (delim.found) {
                try result.appendSlice(allocator, "<del>");
                try result.appendSlice(allocator, delim.content);
                try result.appendSlice(allocator, "</del>");
                i = delim.end_pos;
                continue;
            }
        }

        // Italic: *text*
        if (i + 1 < text.len and text[i] == '*' and text[i + 1] != '*') {
            var pos = i + 1;
            const start = pos;
            while (pos < text.len) {
                if (text[pos] == '*') {
                    const is_bold = (pos + 1 < text.len and text[pos + 1] == '*');
                    if (is_bold) {
                        pos += 1;
                    } else {
                        break;
                    }
                }
                pos += 1;
            }
            if (pos < text.len and pos > start and text[pos] == '*') {
                try result.appendSlice(allocator, "<em>");
                try result.appendSlice(allocator, text[start..pos]);
                try result.appendSlice(allocator, "</em>");
                i = pos + 1;
                continue;
            }
        }

        // Inline code: `code`
        if (text[i] == '`') {
            var pos = i + 1;
            const start = pos;
            while (pos < text.len and text[pos] != '`') {
                pos += 1;
            }
            if (pos < text.len) {
                try result.appendSlice(allocator, "<code>");
                try result.appendSlice(allocator, text[start..pos]);
                try result.appendSlice(allocator, "</code>");
                i = pos + 1;
                continue;
            }
        }

        // Image: ![alt](url)
        if (i + 1 < text.len and text[i] == '!' and text[i + 1] == '[') {
            var pos = i + 2;
            const alt_start = pos;
            while (pos < text.len and text[pos] != ']') {
                pos += 1;
            }
            if (pos < text.len) {
                const alt = text[alt_start..pos];
                pos += 1;
                if (pos < text.len and text[pos] == '(') {
                    pos += 1;
                    const url_start = pos;
                    while (pos < text.len and text[pos] != ')') {
                        pos += 1;
                    }
                    if (pos < text.len) {
                        const url = text[url_start..pos];
                        try result.appendSlice(allocator, "<img src=\"");
                        try result.appendSlice(allocator, url);
                        try result.appendSlice(allocator, "\" alt=\"");
                        try result.appendSlice(allocator, alt);
                        try result.appendSlice(allocator, "\">");
                        i = pos + 1;
                        continue;
                    }
                }
            }
        }

        // Link: [text](url)
        if (text[i] == '[') {
            var pos = i + 1;
            const text_start = pos;
            while (pos < text.len and text[pos] != ']') {
                pos += 1;
            }
            if (pos < text.len) {
                const link_text = text[text_start..pos];
                pos += 1;
                if (pos < text.len and text[pos] == '(') {
                    pos += 1;
                    const url_start = pos;
                    while (pos < text.len and text[pos] != ')') {
                        pos += 1;
                    }
                    if (pos < text.len) {
                        const url = text[url_start..pos];
                        try result.appendSlice(allocator, "<a href=\"");
                        try result.appendSlice(allocator, url);
                        try result.appendSlice(allocator, "\">");
                        try result.appendSlice(allocator, link_text);
                        try result.appendSlice(allocator, "</a>");
                        i = pos + 1;
                        continue;
                    }
                }
            }
        }

        try result.append(allocator, text[i]);
        i += 1;
    }

    return result.toOwnedSlice(allocator);
}

/// Process line breaks - converts trailing \ to <br>
pub fn processLineBreaks(allocator: Allocator, text: []const u8) ![]const u8 {
    if (text.len >= 1 and text[text.len - 1] == '\\') {
        var result = try std.ArrayList(u8).initCapacity(allocator, text.len + 3);
        try result.appendSlice(allocator, text[0 .. text.len - 1]);
        try result.appendSlice(allocator, "<br>");
        return result.toOwnedSlice(allocator);
    }
    return text;
}

test "processInline bold" {
    const allocator = std.testing.allocator;
    const result = try processInline(allocator, "**bold**");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("<strong>bold</strong>", result);
}

test "processInline italic" {
    const allocator = std.testing.allocator;
    const result = try processInline(allocator, "*italic*");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("<em>italic</em>", result);
}

test "processInline link" {
    const allocator = std.testing.allocator;
    const result = try processInline(allocator, "[text](url)");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("<a href=\"url\">text</a>", result);
}

test "processInline image" {
    const allocator = std.testing.allocator;
    const result = try processInline(allocator, "![alt](src)");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("<img src=\"src\" alt=\"alt\">", result);
}

test "processInline UTF-8" {
    const allocator = std.testing.allocator;
    const result = try processInline(allocator, "中文**bold**中文");
    defer allocator.free(result);
    try std.testing.expect(std.mem.indexOf(u8, result, "<strong>bold</strong>") != null);
}
