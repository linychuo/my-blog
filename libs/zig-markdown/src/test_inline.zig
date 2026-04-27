//! Tests for inline markdown processing

const std = @import("std");
const markdown = @import("zig-markdown");
const processInline = markdown.inline_processing.processInline;

test "inline code in sentence" {
    const allocator = std.testing.allocator;
    const md = "This is a `SELECT` statement.";
    const html = try markdown.toHtml(allocator, md);
    defer allocator.free(html);

    try std.testing.expect(std.mem.indexOf(u8, html, "<code>SELECT</code>") != null);
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
    try std.testing.expect(std.mem.indexOf(u8, result, "中文") != null);
}

test "processInline strikethrough" {
    const allocator = std.testing.allocator;
    const result = try processInline(allocator, "~~deleted~~");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("<del>deleted</del>", result);
}

test "processInline combined" {
    const allocator = std.testing.allocator;
    const result = try processInline(allocator, "**bold** *italic* `code`");
    defer allocator.free(result);
    try std.testing.expect(std.mem.indexOf(u8, result, "<strong>bold</strong>") != null);
    try std.testing.expect(std.mem.indexOf(u8, result, "<em>italic</em>") != null);
    try std.testing.expect(std.mem.indexOf(u8, result, "<code>code</code>") != null);
}

// Boundary tests - unclosed markdown syntax
test "processInline unclosed bold" {
    const allocator = std.testing.allocator;
    // **bold with no closing ** should output as-is
    const result = try processInline(allocator, "**bold");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("**bold", result);
}

test "processInline unclosed strikethrough" {
    const allocator = std.testing.allocator;
    // ~~text with no closing ~~ should output as-is
    const result = try processInline(allocator, "~~text");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("~~text", result);
}

test "processInline empty inline code" {
    const allocator = std.testing.allocator;
    // Empty code ticks
    const result = try processInline(allocator, "``");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("<code></code>", result);
}

test "processInline incomplete link" {
    const allocator = std.testing.allocator;
    // Just text in brackets without URL
    const result = try processInline(allocator, "[text]");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("[text]", result);
}

test "processInline incomplete image" {
    const allocator = std.testing.allocator;
    // Image syntax without URL
    const result = try processInline(allocator, "![alt]");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("![alt]", result);
}

test "processInline single asterisk" {
    const allocator = std.testing.allocator;
    const result = try processInline(allocator, "*");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("*", result);
}

test "processInline double asterisk only" {
    const allocator = std.testing.allocator;
    const result = try processInline(allocator, "**");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("**", result);
}

test "processInline single tilde" {
    const allocator = std.testing.allocator;
    const result = try processInline(allocator, "~");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("~", result);
}

test "processInline unclosed bold in sentence" {
    const allocator = std.testing.allocator;
    const result = try processInline(allocator, "Hello **world today");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("Hello **world today", result);
}

test "processInline link missing closing paren" {
    const allocator = std.testing.allocator;
    const result = try processInline(allocator, "[text](url");
    defer allocator.free(result);
    // Missing ) should output as-is
    try std.testing.expectEqualStrings("[text](url", result);
}

test "processInline very long number list item" {
    const allocator = std.testing.allocator;
    const result = try processInline(allocator, "999999999999999. item");
    defer allocator.free(result);
    // Large number followed by period and space should be recognized
    try std.testing.expect(std.mem.indexOf(u8, result, "<li>") != null);
}
