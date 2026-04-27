const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Post = struct {
    title: []const u8,
    date_time: []const u8,
    tags: []const u8,
    content: []const u8,
    filename: []const u8,

    pub fn deinit(self: *Post, allocator: Allocator) void {
        allocator.free(self.title);
        allocator.free(self.date_time);
        allocator.free(self.tags);
        allocator.free(self.content);
        allocator.free(self.filename);
    }

    pub fn parse(allocator: Allocator, content: []const u8, filename: []const u8) !Post {
        var lines = std.mem.splitScalar(u8, content, '\n');
        const first_line = lines.next() orelse return error.InvalidFormat;
        if (!std.mem.eql(u8, std.mem.trim(u8, first_line, " \r\n\t"), "---")) {
            return error.InvalidFormat;
        }

        var title: ?[]const u8 = null;
        var date_time: ?[]const u8 = null;
        var tags: ?[]const u8 = null;
        var frontmatter_end: usize = 1;

        errdefer if (title) |t| allocator.free(t);
        errdefer if (date_time) |dt| allocator.free(dt);
        errdefer if (tags) |t| allocator.free(t);

        while (lines.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \r\n\t");
            if (std.mem.eql(u8, trimmed, "---")) {
                frontmatter_end += 1;
                break;
            }
            if (std.mem.startsWith(u8, trimmed, "title:")) {
                title = try extractValue(allocator, trimmed, "title:");
            } else if (std.mem.startsWith(u8, trimmed, "date_time:")) {
                date_time = try extractValue(allocator, trimmed, "date_time:");
            } else if (std.mem.startsWith(u8, trimmed, "tags:")) {
                tags = try extractValue(allocator, trimmed, "tags:");
            }
            frontmatter_end += 1;
        }

        const content_start = contentOffsetForLine(content, frontmatter_end);
        return Post{
            .title = title orelse return error.MissingTitle,
            .date_time = date_time orelse return error.MissingDateTime,
            .tags = tags orelse "",
            .content = try allocator.dupe(u8, content[content_start..]),
            .filename = try allocator.dupe(u8, filename),
        };
    }

    fn extractValue(allocator: Allocator, line: []const u8, prefix: []const u8) ![]const u8 {
        return allocator.dupe(u8, std.mem.trim(u8, line[prefix.len..], " \r\n\t\"'"));
    }

    fn contentOffsetForLine(content: []const u8, line_num: usize) usize {
        var offset: usize = 0;
        var current_line: usize = 0;
        while (offset < content.len and current_line < line_num) {
            if (content[offset] == '\n') current_line += 1;
            offset += 1;
        }
        while (offset < content.len and (content[offset] == '\n' or content[offset] == '\r')) offset += 1;
        return offset;
    }
};

pub fn sortPostsByDateDesc(_: void, a: Post, b: Post) bool {
    return std.mem.order(u8, a.date_time, b.date_time).compare(.gt);
}
