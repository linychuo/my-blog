//! Tag parsing - parses Handlebars template tags

const std = @import("std");

const TagType = enum {
    variable,
    unescaped_variable,
    partial,
};

const ParsedTag = struct {
    tag_type: TagType,
    name: []const u8,
};

/// Parse a tag from template starting at position i
pub fn parseTag(template: []const u8, i: usize) ?ParsedTag {
    if (i + 1 >= template.len or template[i] != '{' or template[i + 1] != '{') {
        return null;
    }

    var pos = i + 2;
    var tag_type: TagType = .variable;

    if (pos < template.len and template[pos] == '{') {
        tag_type = .unescaped_variable;
        pos += 1;
    }

    if (pos < template.len and template[pos] == '>') {
        tag_type = .partial;
        pos += 1;
        while (pos < template.len and (template[pos] == ' ' or template[pos] == '\t')) : (pos += 1) {}
    }

    var end = pos;
    while (end < template.len and template[end] != '}') : (end += 1) {}

    var brace_count: usize = 0;
    while (end < template.len and template[end] == '}') : (end += 1) {
        brace_count += 1;
    }

    const expected_braces: usize = switch (tag_type) {
        .unescaped_variable => 3,
        .partial, .variable => 2,
    };

    if (brace_count < expected_braces) {
        return null;
    }

    const tag_name = std.mem.trim(u8, template[pos..end - brace_count], " \r\n\t");

    return .{
        .tag_type = tag_type,
        .name = tag_name,
    };
}

/// Find the end position of a parsed tag
pub fn findTagEnd(template: []const u8, start: usize, tag: ParsedTag) usize {
    var pos = start + 2;
    if (tag.tag_type == .unescaped_variable) pos += 1;
    if (tag.tag_type == .partial) pos += 1;

    if (tag.tag_type == .partial) {
        while (pos < template.len and (template[pos] == ' ' or template[pos] == '\t')) : (pos += 1) {}
    }

    while (pos < template.len and template[pos] != '}') : (pos += 1) {}
    while (pos < template.len and template[pos] == '}') : (pos += 1) {}

    return pos;
}

test "parseTag variable" {
    const tag = parseTag("{{name}}", 0);
    try std.testing.expect(tag != null);
    try std.testing.expectEqualStrings("name", tag.?.name);
}

test "parseTag unescaped variable" {
    const tag = parseTag("{{{html}}}", 0);
    try std.testing.expect(tag != null);
    try std.testing.expectEqualStrings("html", tag.?.name);
}

test "parseTag partial" {
    const tag = parseTag("{{> partial}}", 0);
    try std.testing.expect(tag != null);
    try std.testing.expectEqualStrings("partial", tag.?.name);
}

test "parseTag no tag" {
    const tag = parseTag("hello", 0);
    try std.testing.expect(tag == null);
}
