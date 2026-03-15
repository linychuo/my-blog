//! Table block handling for Markdown parser

const std = @import("std");
const Allocator = std.mem.Allocator;
const HtmlWriter = @import("../html_writer.zig").HtmlWriter;
const processInline = @import("../inline.zig").processInline;

/// Check if line is a table separator (|---|---|)
pub fn isTableSeparator(line: []const u8) bool {
    var i: usize = 0;
    while (i < line.len) {
        const c = line[i];
        if (c == '|') {
            i += 1;
            continue;
        }
        if (c == ' ' or c == '-' or c == ':') {
            i += 1;
            continue;
        }
        return false;
    }
    return true;
}

/// Render a table row
pub fn renderTableRow(
    writer: *HtmlWriter,
    allocator: Allocator,
    line: []const u8,
    is_header: bool,
) !void {
    var cells = try std.ArrayList([]const u8).initCapacity(allocator, 0);
    defer cells.deinit(allocator);

    var start: usize = 0;
    var i: usize = 0;
    while (i < line.len) : (i += 1) {
        if (line[i] == '|') {
            if (i > start) {
                const cell = std.mem.trim(u8, line[start..i], " \r\n\t");
                if (cell.len > 0) {
                    try cells.append(allocator, cell);
                }
            }
            start = i + 1;
        }
    }
    // Last cell
    if (start < line.len) {
        const cell = std.mem.trim(u8, line[start..], " \r\n\t");
        if (cell.len > 0) {
            try cells.append(allocator, cell);
        }
    }

    if (cells.items.len == 0) return;

    if (is_header) {
        try writer.write(allocator, "<table>\n<thead>\n<tr>\n");
        for (cells.items) |cell| {
            try writer.write(allocator, "<th>");
            const processed = try processInline(allocator, cell);
            defer allocator.free(processed);
            try writer.write(allocator, processed);
            try writer.write(allocator, "</th>\n");
        }
        try writer.write(allocator, "</tr>\n</thead>\n<tbody>\n");
    } else {
        try writer.write(allocator, "<tr>\n");
        for (cells.items) |cell| {
            try writer.write(allocator, "<td>");
            const processed = try processInline(allocator, cell);
            defer allocator.free(processed);
            try writer.write(allocator, processed);
            try writer.write(allocator, "</td>\n");
        }
        try writer.write(allocator, "</tr>\n");
    }
}

/// Close table if open
pub fn closeTable(writer: *HtmlWriter, allocator: Allocator) !void {
    try writer.write(allocator, "</tbody>\n</table>\n");
}

test "isTableSeparator" {
    try std.testing.expect(isTableSeparator("|---|---|"));
    try std.testing.expect(isTableSeparator("| :--- | ---: |"));
    try std.testing.expect(!isTableSeparator("|---|not"));
    try std.testing.expect(!isTableSeparator("not a separator"));
}
