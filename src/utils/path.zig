const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn buildPostPath(allocator: Allocator, filename: []const u8, date_time: []const u8) ![]const u8 {
    var result = std.ArrayList(u8){};
    errdefer result.deinit(allocator);

    if (date_time.len >= 8) {
        // Split date_time into year, month, day
        var date_parts = std.mem.splitScalar(u8, date_time[0..10], '-');
        const year = date_parts.next() orelse date_time[0..4];
        const month = date_parts.next() orelse date_time[5..7];
        const day = date_parts.next() orelse date_time[8..10];

        try result.appendSlice(allocator, year);
        try result.appendSlice(allocator, "/");

        // Pad month and day if needed
        if (month.len == 1) try result.append(allocator, '0');
        try result.appendSlice(allocator, month);
        try result.appendSlice(allocator, "/");

        if (day.len == 1) try result.append(allocator, '0');
        try result.appendSlice(allocator, day);
        try result.appendSlice(allocator, "/");
    }

    const basename = if (std.mem.endsWith(u8, filename, ".markdown"))
        filename[0 .. filename.len - 9]
    else
        filename;

    try result.appendSlice(allocator, basename);
    try result.appendSlice(allocator, ".html");

    return result.toOwnedSlice(allocator);
}
