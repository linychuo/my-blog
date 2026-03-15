# Zig Markdown

A pure Zig Markdown to HTML converter. No external dependencies.

## Features

- **Headers**: h1-h6 (`#`, `##`, `###`, `####`, `#####`, `######`)
- **Paragraphs**: Automatic paragraph detection
- **Lists**: Unordered (`-`, `*`, `+`) and ordered (`1.`, `2.`, ...)
- **Code blocks**: With syntax highlighting support (```language)
- **Inline code**: `` `code` ``
- **Bold**: `**text**` or `__text__`
- **Italic**: `*text*`
- **Strikethrough**: `~~text~~`
- **Links**: `[text](url)`
- **Images**: `![alt](url)`
- **Blockquotes**: `> text`
- **Horizontal rules**: `---`, `***`, `___`

## Installation

Add to your `build.zig.zon`:

```zig
.{
    .dependencies = .{
        .zig_markdown = .{
            .path = "libs/zig-markdown", // For local development
            // Or use a URL for published versions:
            // .url = "https://github.com/yourname/zig-markdown/archive/refs/tags/v0.1.0.tar.gz",
            // .hash = "1234567890abcdef...",
        },
    },
}
```

## Usage

```zig
const std = @import("std");
const markdown = @import("zig-markdown");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const md = "# Hello World\n\nThis is **bold** text.";
    const html = try markdown.toHtml(allocator, md);
    defer allocator.free(html);

    std.debug.print("{s}\n", .{html});
    // Output: <h1>Hello World</h1>\n<p>This is <strong>bold</strong> text.</p>\n
}
```

## API

### `toHtml(allocator: Allocator, markdown: []const u8) ![]const u8`

Convert markdown text to HTML.

**Parameters:**
- `allocator` - Memory allocator for the result
- `markdown` - The markdown text to convert

**Returns:**
- An owned slice of HTML text (caller must free with `allocator.free()`)

**Example:**
```zig
const html = try markdown.toHtml(allocator, "# Hello\n\n**World**");
defer allocator.free(html);
```

## Development

### Running Tests

```bash
zig build test
```

### Building

```bash
zig build
```

## License

MIT License - See LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
