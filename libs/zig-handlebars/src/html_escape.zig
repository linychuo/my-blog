//! HTML escaping utilities

const std = @import("std");
const Allocator = std.mem.Allocator;

/// Escape HTML special characters in a string
/// Converts: & -> &amp;, < -> &lt;, > -> &gt;, " -> &quot;, ' -> &#x27;
pub fn escapeHtml(allocator: Allocator, input: []const u8) ![]const u8 {
    // First pass: calculate the required size
    var escape_count: usize = 0;
    for (input) |c| {
        switch (c) {
            '&', '<', '>', '"', '\'' => escape_count += 1,
            else => {},
        }
    }

    // If no escaping needed, return a copy of the original
    if (escape_count == 0) {
        return allocator.dupe(u8, input);
    }

    // Calculate new size
    const new_size = input.len + escape_count * 5; // Max expansion per char
    var result = try allocator.alloc(u8, new_size);
    errdefer allocator.free(result);

    var i: usize = 0;
    var j: usize = 0;
    while (i < input.len) : (i += 1) {
        switch (input[i]) {
            '&' => {
                @memcpy(result[j .. j + 5], "&amp;");
                j += 5;
            },
            '<' => {
                @memcpy(result[j .. j + 4], "&lt;");
                j += 4;
            },
            '>' => {
                @memcpy(result[j .. j + 4], "&gt;");
                j += 4;
            },
            '"' => {
                @memcpy(result[j .. j + 6], "&quot;");
                j += 6;
            },
            '\'' => {
                @memcpy(result[j .. j + 6], "&#x27;");
                j += 6;
            },
            else => {
                result[j] = input[i];
                j += 1;
            },
        }
    }

    // Shrink to actual size
    return try allocator.realloc(result, j);
}

test "escapeHtml escapes special characters" {
    const allocator = std.testing.allocator;

    const input = "<script>alert('XSS')</script>";
    const expected = "&lt;script&gt;alert(&#x27;XSS&#x27;)&lt;/script&gt;";

    const result = try escapeHtml(allocator, input);
    defer allocator.free(result);

    try std.testing.expectEqualStrings(expected, result);
}

test "escapeHtml handles ampersand" {
    const allocator = std.testing.allocator;

    const input = "Tom & Jerry";
    const expected = "Tom &amp; Jerry";

    const result = try escapeHtml(allocator, input);
    defer allocator.free(result);

    try std.testing.expectEqualStrings(expected, result);
}

test "escapeHtml with no special chars" {
    const allocator = std.testing.allocator;

    const input = "Hello World";
    const result = try escapeHtml(allocator, input);
    defer allocator.free(result);

    try std.testing.expectEqualStrings("Hello World", result);
}

test "escapeHtml empty string" {
    const allocator = std.testing.allocator;

    const input = "";
    const result = try escapeHtml(allocator, input);
    defer allocator.free(result);

    try std.testing.expectEqualStrings("", result);
}
