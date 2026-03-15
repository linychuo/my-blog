const std = @import("std");
const markdown = @import("zig-markdown");
const Blogger = @import("Blogger.zig").Blogger;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse command line arguments
    var args = std.process.args();
    _ = args.skip(); // Skip program name

    var posts_dir: []const u8 = "posts";
    var dest_dir: []const u8 = "zig-out/blog";

    // Parse optional arguments: --posts <dir> --output <dir>
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--posts") or std.mem.eql(u8, arg, "-p")) {
            posts_dir = args.next() orelse {
                std.debug.print("Error: --posts requires a directory argument\n", .{});
                std.process.exit(1);
            };
        } else if (std.mem.eql(u8, arg, "--output") or std.mem.eql(u8, arg, "-o")) {
            dest_dir = args.next() orelse {
                std.debug.print("Error: --output requires a directory argument\n", .{});
                std.process.exit(1);
            };
        } else if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            printHelp();
            return;
        }
    }

    // Create blogger and generate site
    var blogger = Blogger.new(allocator, posts_dir, dest_dir);
    try blogger.generate();
}

fn printHelp() void {
    std.debug.print(
        \\hello-zig - A static blog generator written in Zig
        \\
        \\Usage: hello-zig [OPTIONS]
        \\
        \\Options:
        \\  -p, --posts <dir>    Posts source directory (default: posts)
        \\  -o, --output <dir>   Output directory (default: zig-out/blog)
        \\  -h, --help           Show this help message
        \\
        \\Example:
        \\  hello-zig --posts ./blog-posts --output ./public
        \\
    ,
        .{},
    );
}
