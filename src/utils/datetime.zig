const std = @import("std");

pub fn getCurrentYear() []const u8 {
    const timestamp = std.time.timestamp();
    var buf: [5]u8 = undefined;
    const year: i64 = 1970 + @divFloor(timestamp, 31536000);
    return std.fmt.bufPrint(&buf, "{d}", .{year}) catch "2026";
}
