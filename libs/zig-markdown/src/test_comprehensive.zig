//! Comprehensive tests for zig-markdown

const std = @import("std");
const markdown = @import("markdown.zig");
const toHtml = markdown.toHtml;

test "basic bold and italic" {
    const allocator = std.testing.allocator;
    
    const bold_md = "**bold text**";
    const bold_html = try toHtml(allocator, bold_md);
    defer allocator.free(bold_html);
    try std.testing.expect(std.mem.indexOf(u8, bold_html, "<strong>bold text</strong>") != null);
    
    const italic_md = "*italic text*";
    const italic_html = try toHtml(allocator, italic_md);
    defer allocator.free(italic_html);
    try std.testing.expect(std.mem.indexOf(u8, italic_html, "<em>italic text</em>") != null);
}

test "code block with language" {
    const allocator = std.testing.allocator;
    const markdown_text =
        \\```rust
        \\fn main() {
        \\    println!("Hello!");
        \\}
        \\```
    ;
    const html = try toHtml(allocator, markdown_text);
    defer allocator.free(html);
    
    try std.testing.expect(std.mem.indexOf(u8, html, "language-rust") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "fn main()") != null);
}

test "math block single line" {
    const allocator = std.testing.allocator;
    const markdown_text = "$$E = mc^2$$";
    const html = try toHtml(allocator, markdown_text);
    defer allocator.free(html);
    
    try std.testing.expect(std.mem.indexOf(u8, html, "<pre class=\"math-block\">") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "E = mc^2") != null);
}

test "math block multiline" {
    const allocator = std.testing.allocator;
    const markdown_text =
        \\$$
        \\f(x) = x^2 + 2x + 1
        \\$$
    ;
    const html = try toHtml(allocator, markdown_text);
    defer allocator.free(html);
    
    try std.testing.expect(std.mem.indexOf(u8, html, "<pre class=\"math-block\">") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "f(x)") != null);
}

test "table with formatting" {
    const allocator = std.testing.allocator;
    const markdown_text =
        \\| **Name** | **Age** |
        \\|----------|---------|
        \\| Alice    | 25      |
        \\| Bob      | 30      |
    ;
    const html = try toHtml(allocator, markdown_text);
    defer allocator.free(html);
    
    try std.testing.expect(std.mem.indexOf(u8, html, "<table>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<th>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<td>Alice</td>") != null);
}

test "nested unordered lists" {
    const allocator = std.testing.allocator;
    const markdown_text =
        \\- Fruits
        \\    - Apple
        \\    - Banana
        \\- Vegetables
        \\    - Carrot
    ;
    const html = try toHtml(allocator, markdown_text);
    defer allocator.free(html);
    
    try std.testing.expect(std.mem.indexOf(u8, html, "<ul>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "Apple") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "Carrot") != null);
}

test "ordered list" {
    const allocator = std.testing.allocator;
    const markdown_text =
        \\1. First
        \\2. Second
        \\3. Third
    ;
    const html = try toHtml(allocator, markdown_text);
    defer allocator.free(html);
    
    try std.testing.expect(std.mem.indexOf(u8, html, "<ol>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<li>First</li>") != null);
}

test "blockquote" {
    const allocator = std.testing.allocator;
    const markdown_text = "> This is a quote";
    const html = try toHtml(allocator, markdown_text);
    defer allocator.free(html);
    
    try std.testing.expect(std.mem.indexOf(u8, html, "<blockquote>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "This is a quote") != null);
}

test "horizontal rule" {
    const allocator = std.testing.allocator;
    
    const hr1 = try toHtml(allocator, "---");
    defer allocator.free(hr1);
    try std.testing.expect(std.mem.indexOf(u8, hr1, "<hr>") != null);
    
    const hr2 = try toHtml(allocator, "***");
    defer allocator.free(hr2);
    try std.testing.expect(std.mem.indexOf(u8, hr2, "<hr>") != null);
}

test "link and image" {
    const allocator = std.testing.allocator;
    
    const link_md = "[Click here](https://example.com)";
    const link_html = try toHtml(allocator, link_md);
    defer allocator.free(link_html);
    try std.testing.expect(std.mem.indexOf(u8, link_html, "<a href=\"https://example.com\">Click here</a>") != null);
    
    const img_md = "![Logo](logo.png)";
    const img_html = try toHtml(allocator, img_md);
    defer allocator.free(img_html);
    try std.testing.expect(std.mem.indexOf(u8, img_html, "<img src=\"logo.png\" alt=\"Logo\">") != null);
}

test "UTF-8 Chinese" {
    const allocator = std.testing.allocator;
    const markdown_text = "这是 **粗体** 文本测试";
    const html = try toHtml(allocator, markdown_text);
    defer allocator.free(html);
    
    try std.testing.expect(std.mem.indexOf(u8, html, "这是") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "粗体") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<strong>") != null);
}

test "UTF-8 Japanese" {
    const allocator = std.testing.allocator;
    const markdown_text = "これは**太字**です";
    const html = try toHtml(allocator, markdown_text);
    defer allocator.free(html);
    
    try std.testing.expect(std.mem.indexOf(u8, html, "これは") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "太字") != null);
}

test "UTF-8 emoji" {
    const allocator = std.testing.allocator;
    const markdown_text = "Hello 👋 World 🌍";
    const html = try toHtml(allocator, markdown_text);
    defer allocator.free(html);
    
    try std.testing.expect(std.mem.indexOf(u8, html, "👋") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "🌍") != null);
}

test "inline code" {
    const allocator = std.testing.allocator;
    const markdown_text = "Use `SELECT * FROM users` query";
    const html = try toHtml(allocator, markdown_text);
    defer allocator.free(html);
    
    try std.testing.expect(std.mem.indexOf(u8, html, "<code>SELECT * FROM users</code>") != null);
}

test "strikethrough" {
    const allocator = std.testing.allocator;
    const markdown_text = "This is ~~not~~ correct";
    const html = try toHtml(allocator, markdown_text);
    defer allocator.free(html);
    
    try std.testing.expect(std.mem.indexOf(u8, html, "<del>not</del>") != null);
}

test "mixed inline formatting" {
    const allocator = std.testing.allocator;
    const markdown_text = "**bold** *italic* ~~strike~~ `code` [link](url)";
    const html = try toHtml(allocator, markdown_text);
    defer allocator.free(html);
    
    try std.testing.expect(std.mem.indexOf(u8, html, "<strong>bold</strong>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<em>italic</em>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<del>strike</del>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<code>code</code>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<a href=\"url\">link</a>") != null);
}

test "empty input" {
    const allocator = std.testing.allocator;
    const html = try toHtml(allocator, "");
    defer allocator.free(html);
    
    try std.testing.expectEqualStrings("", html);
}

test "only whitespace" {
    const allocator = std.testing.allocator;
    const markdown_text = "   \n\n   ";
    const html = try toHtml(allocator, markdown_text);
    defer allocator.free(html);
    
    // Should produce empty or minimal output
    try std.testing.expect(html.len < 10);
}

test "all header levels" {
    const allocator = std.testing.allocator;
    const markdown_text =
        \\# Header 1
        \\## Header 2
        \\### Header 3
        \\#### Header 4
        \\##### Header 5
        \\###### Header 6
    ;
    const html = try toHtml(allocator, markdown_text);
    defer allocator.free(html);
    
    try std.testing.expect(std.mem.indexOf(u8, html, "<h1>Header 1</h1>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<h2>Header 2</h2>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<h3>Header 3</h3>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<h4>Header 4</h4>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<h5>Header 5</h5>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<h6>Header 6</h6>") != null);
}

test "complex document" {
    const allocator = std.testing.allocator;
    const markdown_text =
        \\# Title
        \\
        \\This is a paragraph with **bold** and *italic*.
        \\
        \\## Section
        \\
        \\- List item 1
        \\- List item 2
        \\
        \\```zig
        \\pub fn main() void {}
        \\```
        \\
        \\| Col1 | Col2 |
        \\|------|------|
        \\| A    | B    |
    ;
    const html = try toHtml(allocator, markdown_text);
    defer allocator.free(html);
    
    try std.testing.expect(std.mem.indexOf(u8, html, "<h1>Title</h1>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<h2>Section</h2>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<ul>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<pre><code") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<table>") != null);
}
