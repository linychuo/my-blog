//! Inline Markdown Processing - Handles inline elements like bold, italic, links, etc.

const std = @import("std");
const Allocator = std.mem.Allocator;

/// Process inline markdown elements - UTF-8 safe version
pub fn processInline(allocator: Allocator, text: []const u8) ![]const u8 {
    var result = try std.ArrayList(u8).initCapacity(allocator, 0);
    errdefer result.deinit(allocator);

    // Pre-allocate estimated size to reduce reallocations
    try result.ensureUnusedCapacity(allocator, text.len);

    var i: usize = 0;
    while (i < text.len) {
        // Bold: **text**
        if (i + 1 < text.len and text[i] == '*' and text[i + 1] == '*') {
            i += 2;
            const start = i;
            while (i + 1 < text.len and !(text[i] == '*' and text[i + 1] == '*')) {
                i += 1;
            }
            if (i + 1 < text.len) {
                try result.appendSlice(allocator, "<strong>");
                try result.appendSlice(allocator, text[start..i]);
                try result.appendSlice(allocator, "</strong>");
                i += 2;
                continue;
            }
        }

        // Italic: *text*
        if (i + 1 < text.len and text[i] == '*' and text[i + 1] != '*') {
            i += 1;
            const start = i;
            // Find closing *, but not **
            while (i < text.len) {
                if (text[i] == '*') {
                    // Check if it's not **
                    const is_bold = (i + 1 < text.len and text[i + 1] == '*');
                    if (is_bold) {
                        i += 1; // Skip this *, continue searching
                    } else {
                        break; // Found closing *
                    }
                }
                i += 1;
            }
            if (i < text.len and i > start and text[i] == '*') {
                try result.appendSlice(allocator, "<em>");
                try result.appendSlice(allocator, text[start..i]);
                try result.appendSlice(allocator, "</em>");
                i += 1;
                continue;
            }
            // No closing found, output as regular text
            i = start;
        }

        // Strikethrough: ~~text~~
        if (i + 1 < text.len and text[i] == '~' and text[i + 1] == '~') {
            i += 2;
            const start = i;
            while (i + 1 < text.len and !(text[i] == '~' and text[i + 1] == '~')) {
                i += 1;
            }
            if (i + 1 < text.len) {
                try result.appendSlice(allocator, "<del>");
                try result.appendSlice(allocator, text[start..i]);
                try result.appendSlice(allocator, "</del>");
                i += 2;
                continue;
            }
        }

        // Inline code: `code`
        if (text[i] == '`') {
            i += 1;
            const start = i;
            while (i < text.len and text[i] != '`') {
                i += 1;
            }
            if (i < text.len) {
                try result.appendSlice(allocator, "<code>");
                try result.appendSlice(allocator, text[start..i]);
                try result.appendSlice(allocator, "</code>");
                i += 1;
                continue;
            }
        }

        // Image: ![alt](url)
        if (i + 1 < text.len and text[i] == '!' and text[i + 1] == '[') {
            i += 2;
            const alt_start = i;
            while (i < text.len and text[i] != ']') {
                i += 1;
            }
            if (i < text.len) {
                const alt = text[alt_start..i];
                i += 1;
                if (i < text.len and text[i] == '(') {
                    i += 1;
                    const url_start = i;
                    while (i < text.len and text[i] != ')') {
                        i += 1;
                    }
                    if (i < text.len) {
                        const url = text[url_start..i];
                        try result.appendSlice(allocator, "<img src=\"");
                        try result.appendSlice(allocator, url);
                        try result.appendSlice(allocator, "\" alt=\"");
                        try result.appendSlice(allocator, alt);
                        try result.appendSlice(allocator, "\">");
                        i += 1;
                        continue;
                    }
                }
            }
        }

        // Link: [text](url)
        if (text[i] == '[') {
            i += 1;
            const text_start = i;
            while (i < text.len and text[i] != ']') {
                i += 1;
            }
            if (i < text.len) {
                const link_text = text[text_start..i];
                i += 1;
                if (i < text.len and text[i] == '(') {
                    i += 1;
                    const url_start = i;
                    while (i < text.len and text[i] != ')') {
                        i += 1;
                    }
                    if (i < text.len) {
                        const url = text[url_start..i];
                        try result.appendSlice(allocator, "<a href=\"");
                        try result.appendSlice(allocator, url);
                        try result.appendSlice(allocator, "\">");
                        try result.appendSlice(allocator, link_text);
                        try result.appendSlice(allocator, "</a>");
                        i += 1;
                        continue;
                    }
                }
            }
        }

        // Copy current byte (handles UTF-8 multibyte chars correctly)
        try result.append(allocator, text[i]);
        i += 1;
    }

    return result.toOwnedSlice(allocator);
}

/// Process line breaks - converts trailing \ to <br>
/// Returns the original text if no line break, or a new allocated string with <br> appended
/// Caller must free the returned slice if it differs from the input
pub fn processLineBreaks(allocator: Allocator, text: []const u8) ![]const u8 {
    if (text.len >= 1 and text[text.len - 1] == '\\') {
        var result = try std.ArrayList(u8).initCapacity(allocator, text.len + 3);
        try result.appendSlice(allocator, text[0 .. text.len - 1]);
        try result.appendSlice(allocator, "<br>");
        return result.toOwnedSlice(allocator);
    }
    // Return the original text (no need to free)
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
