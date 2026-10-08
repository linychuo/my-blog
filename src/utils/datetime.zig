const std = @import("std");

pub fn getCurrentYear() [5]u8 {
    const timestamp = std.time.timestamp();
    var buf: [5]u8 = undefined;
    const year: i64 = 1970 + @divFloor(timestamp, 31536000);
    _ = std.fmt.bufPrint(&buf, "{d}", .{year}) catch unreachable;
    return buf;
}
