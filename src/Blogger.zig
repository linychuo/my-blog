const std = @import("std");
const Allocator = std.mem.Allocator;
const markdown = @import("zig-markdown");
const TemplateEngine = @import("zig-handlebars").TemplateEngine;
const Context = @import("zig-handlebars").Context;

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

        const content_start = content_offset_for_line(content, frontmatter_end);
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

    fn content_offset_for_line(content: []const u8, line_num: usize) usize {
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

pub const Blogger = struct {
    dest_dir: []const u8,
    posts_dir: []const u8,
    allocator: Allocator,
    template_engine: TemplateEngine,

    pub fn new(allocator: Allocator, posts_dir: []const u8, dest_dir: []const u8) Blogger {
        // Get the directory where the executable is located

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

        // Copy static files
        try self.copyStaticFiles();

        var posts = std.ArrayList(Post){};
        defer {
            for (posts.items) |*post| post.deinit(self.allocator);
            posts.deinit(self.allocator);
        }

        try self.loadPosts(&posts);
        std.mem.sort(Post, posts.items, {}, sortPostsByDateDesc);

        for (posts.items) |post| try self.generatePostPage(post);
        try self.generateIndex(posts.items);
        try self.generateAbout();
        try self.generateTagPages(posts.items);

        std.debug.print("Blog generation complete!\n", .{});
    }

    fn copyStaticFiles(self: *Blogger) !void {
        const static_dir = "static";

        // Check if static directory exists
        var dir = std.fs.cwd().openDir(static_dir, .{ .iterate = true }) catch {
            std.debug.print("  Warning: static directory not found, skipping static files\n", .{});
            return;
        };
        defer dir.close();

        // Create output directory
        try std.fs.cwd().makePath(self.dest_dir);

        var walker = try dir.walk(self.allocator);
        defer walker.deinit();

        while (try walker.next()) |entry| {
            if (entry.kind == .file) {
                const dest_path = try std.fs.path.join(self.allocator, &.{ self.dest_dir, entry.path });
                defer self.allocator.free(dest_path);

                // Create parent directories if needed
                const dest_dir_path = std.fs.path.dirname(dest_path);
                if (dest_dir_path) |dir_path| {
                    try std.fs.cwd().makePath(dir_path);
                }

                // Copy file content
                var src_file = try dir.openFile(entry.path, .{});
                defer src_file.close();

                const dest_file = try std.fs.cwd().createFile(dest_path, .{});
                defer dest_file.close();

                const content = try src_file.readToEndAlloc(self.allocator, 1024 * 1024);
                defer self.allocator.free(content);

                try dest_file.writeAll(content);

                std.debug.print("  Copied: {s}\n", .{entry.path});
            }
        }
    }

    fn loadPosts(self: *Blogger, posts: *std.ArrayList(Post)) !void {
        var dir = try std.fs.cwd().openDir(self.posts_dir, .{ .iterate = true });
        defer dir.close();
        var walker = try dir.walk(self.allocator);
        defer walker.deinit();

        while (try walker.next()) |entry| {
            if (entry.kind == .file and std.mem.endsWith(u8, entry.path, ".markdown")) {
                // Skip about.markdown - it will be handled separately
                if (std.mem.eql(u8, std.fs.path.basename(entry.path), "about.markdown")) {
                    continue;
                }

                const file = try dir.openFile(entry.path, .{});
                defer file.close();
                const content = try file.readToEndAlloc(self.allocator, 1024 * 1024);
                defer self.allocator.free(content);

                const post = Post.parse(self.allocator, content, std.fs.path.basename(entry.path)) catch |err| {
                    std.debug.print("  Skipped ({s}): {s}\n", .{ @errorName(err), entry.path });
                    continue;
                };
                try posts.append(self.allocator, post);
                std.debug.print("  Loaded: {s}\n", .{entry.path});
            }
        }
    }

    fn generatePostPage(self: *Blogger, post: Post) !void {
        const html_content = try markdown.toHtml(self.allocator, post.content);
        defer self.allocator.free(html_content);

        var ctx = Context.init(self.allocator);
        defer ctx.deinit();

        try ctx.set("title", post.title);
        try ctx.set("date_time", post.date_time);
        try ctx.set("content", html_content);

        const tags_html = try buildTagsHtml(self.allocator, post.tags);
        defer self.allocator.free(tags_html);
        try ctx.set("tags", tags_html);

        // Render post.hbs to get page content
        const page_html = try self.template_engine.render("post.hbs", &ctx);
        defer self.allocator.free(page_html);

        // Set page title and content, then render layout
        var full_title = std.ArrayList(u8){};
        defer full_title.deinit(self.allocator);
        try full_title.appendSlice(self.allocator, post.title);
        try full_title.appendSlice(self.allocator, " - ");
        try ctx.set("page_title", full_title.items);

        const year = getCurrentYear();
        try ctx.set("year", year);

        self.template_engine.setPageContent(page_html);
        const html = try self.template_engine.render("layout.hbs", &ctx);
        defer self.allocator.free(html);

        // Generate output path with date-based directory structure
        try self.writeHtmlFileWithDate(post.filename, post.date_time, html);
    }

    fn writeHtmlFileWithDate(self: *Blogger, markdown_filename: []const u8, date_time: []const u8, html: []const u8) !void {
        const post_path = try buildPostPath(self.allocator, markdown_filename, date_time);
        defer self.allocator.free(post_path);

        var output_path = std.ArrayList(u8){};
        defer output_path.deinit(self.allocator);
        try output_path.appendSlice(self.allocator, self.dest_dir);
        try output_path.appendSlice(self.allocator, "/");
        try output_path.appendSlice(self.allocator, post_path);

        const dir_path = std.fs.path.dirname(output_path.items);
        if (dir_path) |dp| {
            try std.fs.cwd().makePath(dp);
        }

        const file = try std.fs.cwd().createFile(output_path.items, .{});
        defer file.close();
        try file.writeAll(html);
    }

    fn generateIndex(self: *Blogger, posts: []const Post) !void {
        var posts_html = std.ArrayList(u8){};
        defer posts_html.deinit(self.allocator);

        for (posts) |post| {
            const post_path = try buildPostPath(self.allocator, post.filename, post.date_time);
            defer self.allocator.free(post_path);

            const tags_html = try buildTagsHtml(self.allocator, post.tags);
            defer self.allocator.free(tags_html);

            try posts_html.appendSlice(self.allocator, "<li class=\"post-item\"><div class=\"post-title\"><a href=\"/");
            try posts_html.appendSlice(self.allocator, post_path);
            try posts_html.appendSlice(self.allocator, "\">");
            try posts_html.appendSlice(self.allocator, post.title);
            try posts_html.appendSlice(self.allocator, "</a></div><div class=\"post-meta\"><time class=\"post-date\" datetime=\"");
            try posts_html.appendSlice(self.allocator, post.date_time);
            try posts_html.appendSlice(self.allocator, "\">");
            try posts_html.appendSlice(self.allocator, post.date_time);
            try posts_html.appendSlice(self.allocator, "</time>");
            try posts_html.appendSlice(self.allocator, tags_html);
            try posts_html.appendSlice(self.allocator, "</div></li>\n");
        }

        var ctx = Context.init(self.allocator);
        defer ctx.deinit();
        try ctx.set("subtitle", "Software development, technology, and more");
        try ctx.set("posts", posts_html.items);

        const page_html = try self.template_engine.render("index.hbs", &ctx);
        defer self.allocator.free(page_html);

        try ctx.set("page_title", "");
        try ctx.set("year", getCurrentYear());

        self.template_engine.setPageContent(page_html);
        const html = try self.template_engine.render("layout.hbs", &ctx);
        defer self.allocator.free(html);

        const output_path = try std.fs.path.join(self.allocator, &.{ self.dest_dir, "index.html" });
        defer self.allocator.free(output_path);

        const file = try std.fs.cwd().createFile(output_path, .{});
        defer file.close();
        try file.writeAll(html);

        std.debug.print("  Generated: index.html\n", .{});
    }

    fn generateAbout(self: *Blogger) !void {
        // Try to load about.markdown
        const about_path = try std.fs.path.join(self.allocator, &.{ self.posts_dir, "about.markdown" });
        defer self.allocator.free(about_path);

        const file = std.fs.cwd().openFile(about_path, .{}) catch {
            std.debug.print("  Skipped: about.markdown not found\n", .{});
            return;
        };
        defer file.close();

        const content = try file.readToEndAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(content);

        // Convert markdown to HTML (about.markdown has no frontmatter)
        const html_content = try markdown.toHtml(self.allocator, content);
        defer self.allocator.free(html_content);

        // Create context
        var ctx = Context.init(self.allocator);
        defer ctx.deinit();

        try ctx.set("title", "About");
        try ctx.set("content", html_content);
        try ctx.set("page_title", "");
        try ctx.set("year", getCurrentYear());
        try ctx.set("tags", "");

        // Render about.hbs to get page content
        const page_html = try self.template_engine.render("about.hbs", &ctx);
        defer self.allocator.free(page_html);

        // Set page content and render layout
        self.template_engine.setPageContent(page_html);
        const html = try self.template_engine.render("layout.hbs", &ctx);
        defer self.allocator.free(html);

        // Write about.html to dest_dir root
        const output_path = try std.fs.path.join(self.allocator, &.{ self.dest_dir, "about.html" });
        defer self.allocator.free(output_path);

        const out_file = try std.fs.cwd().createFile(output_path, .{});
        defer out_file.close();
        try out_file.writeAll(html);

        std.debug.print("  Generated: about.html\n", .{});
    }

    fn generateTagPages(self: *Blogger, posts: []const Post) !void {
        // Collect all unique tags and their posts
        var tag_map = std.StringHashMap(std.ArrayListUnmanaged(Post)).init(self.allocator);
        defer {
            var it = tag_map.iterator();
            while (it.next()) |entry| {
                self.allocator.free(entry.key_ptr.*);
                entry.value_ptr.deinit(self.allocator);
            }
            tag_map.deinit();
        }

        // Build tag -> posts mapping
        for (posts) |post| {
            var tag_iter = std.mem.tokenizeScalar(u8, post.tags, ' ');
            while (tag_iter.next()) |tag| {
                const tag_copy = try self.allocator.dupe(u8, tag);
                errdefer self.allocator.free(tag_copy);
                const gop = try tag_map.getOrPut(tag_copy);
                if (!gop.found_existing) {
                    gop.value_ptr.* = .{};
                }
                try gop.value_ptr.append(self.allocator, post);
            }
        }

        // Generate a page for each tag
        var it = tag_map.iterator();
        while (it.next()) |entry| {
            const tag_name = entry.key_ptr.*;
            const tag_posts = entry.value_ptr;

            // Build posts HTML for this tag
            var posts_html = std.ArrayList(u8){};
            defer posts_html.deinit(self.allocator);

            for (tag_posts.items) |post| {
                const post_path = try buildPostPath(self.allocator, post.filename, post.date_time);
                defer self.allocator.free(post_path);

                const tags_html = try buildTagsHtml(self.allocator, post.tags);
                defer self.allocator.free(tags_html);

                try posts_html.appendSlice(self.allocator, "<li class=\"post-item\"><div class=\"post-title\"><a href=\"/");
                try posts_html.appendSlice(self.allocator, post_path);
                try posts_html.appendSlice(self.allocator, "\">");
                try posts_html.appendSlice(self.allocator, post.title);
                try posts_html.appendSlice(self.allocator, "</a></div><div class=\"post-meta\"><time class=\"post-date\" datetime=\"");
                try posts_html.appendSlice(self.allocator, post.date_time);
                try posts_html.appendSlice(self.allocator, "\">");
                try posts_html.appendSlice(self.allocator, post.date_time);
                try posts_html.appendSlice(self.allocator, "</time>");
                try posts_html.appendSlice(self.allocator, tags_html);
                try posts_html.appendSlice(self.allocator, "</div></li>\n");
            }

            var ctx = Context.init(self.allocator);
            defer ctx.deinit();

            var post_count_buf: [16]u8 = undefined;
            const post_count_str = std.fmt.bufPrint(&post_count_buf, "{d}", .{tag_posts.items.len}) catch "0";

            var page_title_buf: [256]u8 = undefined;
            const page_title_str = std.fmt.bufPrint(&page_title_buf, "Posts tagged with \"{s}\" - ", .{tag_name}) catch "";

            try ctx.set("tag_name", tag_name);
            try ctx.set("post_count", post_count_str);
            try ctx.set("posts", posts_html.items);
            try ctx.set("page_title", page_title_str);
            try ctx.set("year", getCurrentYear());

            // Render tag.hbs to get page content
            const page_html = try self.template_engine.render("tag.hbs", &ctx);
            defer self.allocator.free(page_html);

            // Set page content and render layout
            self.template_engine.setPageContent(page_html);
            const html = try self.template_engine.render("layout.hbs", &ctx);
            defer self.allocator.free(html);

            // Write tag page to tags/ directory
            var output_filename = std.ArrayList(u8){};
            defer output_filename.deinit(self.allocator);
            try output_filename.appendSlice(self.allocator, self.dest_dir);
            try output_filename.appendSlice(self.allocator, "/tags/");
            try output_filename.appendSlice(self.allocator, tag_name);
            try output_filename.appendSlice(self.allocator, ".html");

            const dir_path = std.fs.path.dirname(output_filename.items);
            if (dir_path) |dp| {
                try std.fs.cwd().makePath(dp);
            }

            const file = try std.fs.cwd().createFile(output_filename.items, .{});
            defer file.close();
            try file.writeAll(html);

            std.debug.print("  Generated: tags/{s}.html\n", .{tag_name});
        }
    }
};

fn sortPostsByDateDesc(_: void, a: Post, b: Post) bool {
    return std.mem.order(u8, a.date_time, b.date_time).compare(.gt);
}

fn getCurrentYear() []const u8 {
    const timestamp = std.time.timestamp();
    var buf: [5]u8 = undefined;
    const year: i64 = 1970 + @divFloor(timestamp, 31536000);
    return std.fmt.bufPrint(&buf, "{d}", .{year}) catch "2026";
}

fn buildPostPath(allocator: Allocator, filename: []const u8, date_time: []const u8) ![]const u8 {
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

fn buildTagsHtml(allocator: Allocator, tags: []const u8) ![]const u8 {
    var html = std.ArrayList(u8){};
    errdefer html.deinit(allocator);

    var tag_iter = std.mem.tokenizeScalar(u8, tags, ' ');
    while (tag_iter.next()) |tag| {
        try html.appendSlice(allocator, "<a href=\"/tags/");
        try html.appendSlice(allocator, tag);
        try html.appendSlice(allocator, ".html\" class=\"article-tag\">");
        try html.appendSlice(allocator, tag);
        try html.appendSlice(allocator, "</a>");
    }

    return html.toOwnedSlice(allocator);
}
