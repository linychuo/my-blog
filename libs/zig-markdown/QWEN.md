# Project Context: zig-markdown

## Project Overview

**zig-markdown** is a pure Zig Markdown to HTML converter library with no external dependencies. It provides a simple API for converting Markdown text to HTML with support for a wide range of Markdown features including syntax-highlighted code blocks, tables, math formulas, and UTF-8 text.

### Purpose
- Convert Markdown text to semantic HTML
- Support common Markdown syntax (headers, lists, code, links, images)
- Handle UTF-8 content (e.g., Chinese, Japanese, Korean characters)
- Render mathematical formulas using LaTeX syntax (`$$...$$`)
- Parse and render Markdown tables

### Main Technologies
- **Language**: Zig 0.15.2
- **Dependencies**: None (pure Zig implementation)
- **Package Name**: `zig_markdown`
- **Version**: 0.1.0

## Project Structure

```
zig-markdown/
├── build.zig              # Build configuration (Zig build system)
├── build.zig.zon          # Package manifest (name, version, paths)
├── README.md              # User-facing documentation
├── QWEN.md                # AI context file (this file)
└── src/
    ├── root.zig           # Library entry point, exports public API and submodules
    ├── markdown.zig       # Main toHtml() function with refactored parsing logic
    ├── parser.zig         # Parser state management and helper functions
    ├── html_writer.zig    # HTML writer wrapper for convenient output
    ├── inline.zig         # Inline element processing (bold, italic, links, etc.)
    ├── blocks/
    │   ├── root.zig       # Blocks module export
    │   └── table.zig      # Table parsing and rendering
    ├── test_comprehensive.zig  # Comprehensive test suite (20+ tests)
    └── test_inline.zig    # Inline processing tests
```

## Building and Running

### Prerequisites
- Zig compiler version 0.15.2 or higher

### Build Commands

| Command | Description |
|---------|-------------|
| `zig build` | Build the library |
| `zig build test` | Run all unit tests |
| `zig build --help` | Show available build options |

### Testing
```bash
zig build test
```

## API Reference

### `toHtml(allocator: Allocator, markdown: []const u8) ![]const u8`

Convert Markdown text to HTML.

**Parameters:**
- `allocator` - Memory allocator for the result (caller owns the returned slice)
- `markdown` - The Markdown text to convert

**Returns:**
- An owned slice of HTML text (must be freed with `allocator.free()`)

**Example:**
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
}
```

### Submodules (Advanced Usage)

```zig
const markdown = @import("zig-markdown");

// Access parser state
const ParserState = markdown.parser.ParserState;

// Access inline processing
const processInline = markdown.inline_processing.processInline;

// Access table handling
const table = markdown.blocks.table;

// Access HTML writer
const HtmlWriter = markdown.html_writer.HtmlWriter;
```

## Supported Markdown Features

### Block Elements
| Feature | Syntax | Output |
|---------|--------|--------|
| Headers | `#` to `######` | `<h1>` to `<h6>` |
| Paragraphs | Blank line separation | `<p>` |
| Unordered lists | `- `, `* `, `+ ` | `<ul><li>` |
| Ordered lists | `1. `, `2. `, etc. | `<ol><li>` |
| Code blocks | ` ```language ` | `<pre><code class="language-...">` |
| Blockquotes | `> text` | `<blockquote>` |
| Horizontal rules | `---`, `***`, `___` | `<hr>` |
| Tables | `\| col \| col \|` | `<table><thead><tbody>` |
| Math blocks | `$$...$$` | `<pre class="math-block">` |

### Inline Elements
| Feature | Syntax | Output |
|---------|--------|--------|
| Bold | `**text**` or `__text__` | `<strong>` |
| Italic | `*text*` | `<em>` |
| Strikethrough | `~~text~~` | `<del>` |
| Inline code | `` `code` `` | `<code>` |
| Links | `[text](url)` | `<a href="...">` |
| Images | `![alt](url)` | `<img src="..." alt="...">` |

### Special Features
- **Line breaks**: Backslash `\` at end of line renders as `<br>`
- **UTF-8 support**: Full support for multibyte characters (Chinese, Japanese, etc.)
- **Syntax highlighting**: Language class added to code blocks (e.g., `language-zig`)
- **Math formulas**: LaTeX math in `$$...$$` blocks for KaTeX rendering

## Architecture

### Modular Design

The library uses a modular architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                        root.zig                              │
│  (Public API: toHtml, submodules)                            │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐    ┌─────────────────┐   ┌──────────────┐
│  markdown.zig │    │   parser.zig    │   │ inline.zig   │
│  (Main loop)  │    │  (State mgmt)   │   │ (Processing) │
└───────────────┘    └─────────────────┘   └──────────────┘
        │                     │                     │
        │                     ▼                     │
        │            ┌─────────────────┐            │
        │            │ html_writer.zig │            │
        │            │  (Output util)  │            │
        │            └─────────────────┘            │
        │                                          │
        ▼                                          ▼
┌─────────────────┐                       ┌─────────────────┐
│  blocks/table   │                       │  test files     │
│  (Table parse)  │                       │  (20+ tests)    │
└─────────────────┘                       └─────────────────┘
```

### Key Components

**`parser.zig` - ParserState**
```zig
pub const ParserState = struct {
    in_paragraph: bool = false,
    in_code_block: bool = false,
    in_math_block: bool = false,
    in_list: bool = false,
    in_ordered_list: bool = false,
    in_table: bool = false,
    list_item_open: bool = false,

    code_buffer: std.ArrayList(u8) = .{},
    code_language: std.ArrayList(u8) = .{},
    math_buffer: std.ArrayList(u8) = .{},
    
    pub fn deinit(self: *ParserState, allocator: Allocator) void
    pub fn resetBuffers(self: *ParserState) void
    pub fn appendToBuffer(buffer: *std.ArrayList(u8), allocator: Allocator, content: []const u8) !void
};
```

**`parser.zig` - Helper Functions**
- `closeLists()` - Close open list tags
- `closeParagraphAndLists()` - Close paragraph and lists (extracted common pattern)
- `closeTable()` - Close table if open
- `closeAll()` - Close all open tags at end of parsing
- `renderHeader()` - Render header with given level

**`html_writer.zig` - HtmlWriter**
```zig
pub const HtmlWriter = struct {
    result: *std.ArrayList(u8),
    
    pub fn init(result: *std.ArrayList(u8)) HtmlWriter
    pub fn write(self: *HtmlWriter, allocator: Allocator, text: []const u8) !void
    pub fn writeEscaped(self: *HtmlWriter, allocator: Allocator, text: []const u8) !void
};
```

**`inline.zig` - processInline()**
- Handles bold, italic, strikethrough, inline code, links, images
- UTF-8 safe processing
- Pre-allocates capacity for performance
- Returns owned slice (caller frees)

**`inline.zig` - processLineBreaks()**
- Converts trailing `\` to `<br>`
- Returns original slice if no change, new allocation if changed
- Caller must free only if result differs from input

## Development Conventions

### Code Style
- **Documentation**: Use Zig doc comments (`//!` for module-level, `///` for declarations)
- **Naming**: `snake_case` for functions and variables, `PascalCase` for types
- **Error handling**: Use Zig error unions (`!T`) and `errdefer` for cleanup
- **Memory management**: All ArrayList methods require explicit allocator parameter

### Testing Practices
- Tests use `std.testing.allocator` for memory allocation
- Comprehensive test suite in `test_comprehensive.zig` (20+ tests)
- Inline processing tests in `test_inline.zig`
- Run tests with `zig build test`

### Test Coverage
- ✅ Basic formatting (bold, italic, strikethrough)
- ✅ Headers (all 6 levels)
- ✅ Code blocks (with language)
- ✅ Math blocks (single and multiline)
- ✅ Tables (with formatting)
- ✅ Lists (ordered, unordered, nested)
- ✅ Links and images
- ✅ Blockquotes and horizontal rules
- ✅ UTF-8 (Chinese, Japanese, emoji)
- ✅ Edge cases (empty input, whitespace only)

## Usage in Other Projects

Add to your `build.zig.zon`:

```zig
.{
    .dependencies = .{
        .zig_markdown = .{
            .path = "libs/zig-markdown",
        },
    },
}
```

Then import in your Zig code:

```zig
const markdown = @import("zig-markdown");
const html = try markdown.toHtml(allocator, markdown_text);
defer allocator.free(html);
```

## Implementation Details

### Parser State Machine
The `toHtml` function uses `ParserState` to track context:
- State flags for paragraph, code block, math block, lists, table
- Buffers for code content, math content, language identifier
- Proper cleanup with `defer state.deinit(allocator)`

### Error Handling
- All errors are properly propagated
- `errdefer` ensures cleanup on error
- Caller owns all returned slices

### Memory Management
- `ParserState` manages internal buffers with automatic initialization
- `HtmlWriter` wraps `ArrayList` for convenient output
- Pre-allocation with `ensureUnusedCapacity` for performance
- All ArrayList methods require explicit allocator parameter

### Performance Optimizations (Zig 0.15.2)
- **Pre-allocation**: `ensureUnusedCapacity(allocator, text.len)` reduces reallocations
- **Capacity initialization**: `initCapacity(allocator, 0)` for empty lists
- **Helper methods**: `appendToBuffer` reduces code duplication

### Zig 0.15.2 Compatibility Notes

#### ArrayList API Changes
In Zig 0.15.2, `ArrayList` is defined as `std.ArrayList(T)` which returns `array_list.Aligned(T, null)`. This type requires explicit allocator for all operations:

```zig
// ✅ Correct for Zig 0.15.2
var list = try std.ArrayList(u8).initCapacity(allocator, 0);
try list.append(allocator, item);
try list.appendSlice(allocator, items);
try list.ensureUnusedCapacity(allocator, size);
list.deinit(allocator);
return list.toOwnedSlice(allocator);
```

#### ArrayList Initialization
```zig
// ✅ Correct - use initCapacity
var result = try std.ArrayList(u8).initCapacity(allocator, 0);
errdefer result.deinit(allocator);

// ❌ Incorrect - no .init() method
var result = std.ArrayList(u8).init(allocator);  // Error!

// ❌ Incorrect - struct init doesn't work
var result = std.ArrayList(u8){ .allocator = allocator };  // Error!
```

#### ArrayList Methods Require Allocator
All mutating methods require explicit allocator parameter:
```zig
try list.append(allocator, item);
try list.appendSlice(allocator, items);
try list.ensureUnusedCapacity(allocator, size);
try list.print(allocator, "{d}", .{value});
list.deinit(allocator);
return list.toOwnedSlice(allocator);
```

#### Inline For Loop with Continue
In Zig 0.15.2, `continue` cannot be used directly inside `inline for` when there's runtime control flow:

```zig
// ❌ Incorrect - comptime continue in runtime block
inline for (items) |item| {
    if (runtime_condition) {
        continue;  // Error!
    }
}

// ✅ Correct - use flag
{
    var matched = false;
    inline for (items) |item| {
        if (!matched and runtime_condition) {
            // process
            matched = true;
        }
    }
    if (matched) continue;
}
```

#### Memory Management Pattern
When a function may return either the input or a new allocation:
```zig
const processed = try processInline(allocator, text);
const result = try processLineBreaks(allocator, processed);
try writer.write(allocator, result);
// Free original
allocator.free(processed);
// Free new allocation if different
if (result.ptr != processed.ptr) allocator.free(result);
```

## License

MIT License (as indicated in README.md)
