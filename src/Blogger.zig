const std = @import("std");
const Allocator = std.mem.Allocator;
const TemplateEngine = @import("zig-handlebars").TemplateEngine;
const Post = @import("Post.zig").Post;
const FileSystem = @import("FileSystem.zig");
const index_gen = @import("generators/index.zig");
const post_gen = @import("generators/post.zig");
const about_gen = @import("generators/about.zig");
const tag_gen = @import("generators/tag.zig");
const sortPostsByDateDesc = @import("Post.zig").sortPostsByDateDesc;

pub const Blogger = struct {
    dest_dir: []const u8,
    posts_dir: []const u8,
    allocator: Allocator,
    template_engine: TemplateEngine,

    pub fn new(allocator: Allocator, posts_dir: []const u8, dest_dir: []const u8) Blogger {
        const engine = TemplateEngine.init(allocator, "templates");
        return .{
            .allocator = allocator,
            .posts_dir = posts_dir,
            .dest_dir = dest_dir,
            .template_engine = engine,
        };
    }

    pub fn generate(self: *Blogger) !void {
        std.debug.print("Generating blog...\n  Posts directory: {s}\n  Output directory: {s}\n", .{ self.posts_dir, self.dest_dir });
        try std.fs.cwd().makePath(self.dest_dir);

        try FileSystem.copyStaticFiles(self.allocator, "static", self.dest_dir);

        var posts = std.ArrayList(Post){};
        defer {
            for (posts.items) |*post| post.deinit(self.allocator);
            posts.deinit(self.allocator);
        }

        try FileSystem.loadPosts(self.allocator, self.posts_dir, &posts);
        std.mem.sort(Post, posts.items, {}, sortPostsByDateDesc);

        for (posts.items) |post| try post_gen.generatePostPage(self.allocator, &self.template_engine, self.dest_dir, post);
        try index_gen.generateIndex(self.allocator, &self.template_engine, self.dest_dir, posts.items);
        try about_gen.generateAbout(self.allocator, &self.template_engine, self.dest_dir, self.posts_dir);
        try tag_gen.generateTagPages(self.allocator, &self.template_engine, self.dest_dir, posts.items);

        std.debug.print("Blog generation complete!\n", .{});
    }
};
