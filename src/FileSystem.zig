const std = @import("std");
const Allocator = std.mem.Allocator;
const Post = @import("Post.zig").Post;

pub fn copyStaticFiles(allocator: Allocator, static_dir: []const u8, dest_dir: []const u8) !void {
    var dir = std.fs.cwd().openDir(static_dir, .{ .iterate = true }) catch {
        std.debug.print("  Warning: static directory not found, skipping static files\n", .{});
        return;
    };
    defer dir.close();

    try std.fs.cwd().makePath(dest_dir);

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind == .file) {
            const dest_path = try std.fs.path.join(allocator, &.{ dest_dir, entry.path });
            defer allocator.free(dest_path);

            const dest_dir_path = std.fs.path.dirname(dest_path);
            if (dest_dir_path) |dir_path| {
                try std.fs.cwd().makePath(dir_path);
            }

            var src_file = try dir.openFile(entry.path, .{});
            defer src_file.close();

            const dest_file = try std.fs.cwd().createFile(dest_path, .{});
            defer dest_file.close();

            const content = try src_file.readToEndAlloc(allocator, 1024 * 1024);
            defer allocator.free(content);

            try dest_file.writeAll(content);

            std.debug.print("  Copied: {s}\n", .{entry.path});
        }
    }
}

pub fn loadPosts(allocator: Allocator, posts_dir: []const u8, posts: *std.ArrayList(Post)) !void {
    var dir = try std.fs.cwd().openDir(posts_dir, .{ .iterate = true });
    defer dir.close();
    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind == .file and std.mem.endsWith(u8, entry.path, ".markdown")) {
            const basename = std.fs.path.basename(entry.path);
            if (std.mem.eql(u8, basename, "about.markdown")) {
                continue;
            }

            const file = try dir.openFile(entry.path, .{});
            defer file.close();
            const content = try file.readToEndAlloc(allocator, 1024 * 1024);
            defer allocator.free(content);

            const post = Post.parse(allocator, content, basename) catch |err| {
                std.debug.print("  Skipped ({s}): {s}\n", .{ @errorName(err), entry.path });
                continue;
            };
            try posts.append(allocator, post);
            std.debug.print("  Loaded: {s}\n", .{entry.path});
        }
    }
}

pub fn writeHtmlFile(allocator: Allocator, dest_dir: []const u8, relative_path: []const u8, html: []const u8) !void {
    const output_path = try std.fs.path.join(allocator, &.{ dest_dir, relative_path });
    defer allocator.free(output_path);

    const dir_path = std.fs.path.dirname(output_path);
    if (dir_path) |dp| {
        try std.fs.cwd().makePath(dp);
    }

    const file = try std.fs.cwd().createFile(output_path, .{});
    defer file.close();
    try file.writeAll(html);
}
