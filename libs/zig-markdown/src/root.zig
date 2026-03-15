//! Zig Markdown - A pure Zig Markdown to HTML converter
//!
//! ## Features
//! - Headers (h1-h6)
//! - Paragraphs
//! - Unordered lists (-, *, +)
//! - Ordered lists (1., 2., ...)
//! - Code blocks with syntax highlighting (```)
//! - Inline code (`code`)
//! - Bold (**text** or __text__)
//! - Italic (*text*)
//! - Strikethrough (~~text~~)
//! - Links ([text](url))
//! - Images (![alt](url))
//! - Blockquotes (> text)
//! - Horizontal rules (---, ***, ___)
//! - Tables (| col | col |)
//! - Math blocks ($$...$$)
//!
//! ## Example
//! ```zig
//! const markdown = @import("zig-markdown");
//!
//! const html = try markdown.toHtml(allocator, "# Hello\n\n**World**");
//! defer allocator.free(html);
//! ```

const markdown_impl = @import("markdown.zig");

pub const toHtml = markdown_impl.toHtml;

// Export submodules for advanced usage
pub const parser = @import("parser.zig");
pub const inline_processing = @import("inline.zig");
pub const blocks = @import("blocks/root.zig");
pub const html_writer = @import("html_writer.zig");
