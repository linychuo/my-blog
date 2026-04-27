const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn buildPostPath(allocator: Allocator, filename: []const u8, date_time: []const u8) ![]const u8 {
    var result = std.ArrayList(u8){};
    errdefer result.deinit(allocator);

    if (date_time.len >= 8) {
        try result.appendSlice(allocator, date_time[0..4]);
        try result.appendSlice(allocator, "/");

        var pos: usize = 5;
        while (pos < date_time.len and date_time[pos] != '-') : (pos += 1) {}
        const month = date_time[5..pos];
        if (month.len == 1) try result.appendSlice(allocator, "0");
        try result.appendSlice(allocator, month);
        try result.appendSlice(allocator, "/");

        pos += 1;
        var day_end = pos;
        while (day_end < date_time.len and date_time[day_end] != ' ' and date_time[day_end] != '-') : (day_end += 1) {}
        const day = date_time[pos..day_end];
        if (day.len == 1) try result.appendSlice(allocator, "0");
        try result.appendSlice(allocator, day);
        try result.appendSlice(allocator, "/");
    }

    if (std.mem.endsWith(u8, filename, ".markdown")) {
        try result.appendSlice(allocator, filename[0 .. filename.len - 9]);
    } else {
        try result.appendSlice(allocator, filename);
    }
    try result.appendSlice(allocator, ".html");

    return result.toOwnedSlice(allocator);
}
