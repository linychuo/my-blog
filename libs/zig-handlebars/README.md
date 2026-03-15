# Zig Handlebars

A simple Handlebars-style template engine for Zig.

## Features

- Simple `{{variable}}` syntax for variable replacement
- `{{{html}}}` syntax for unescaped HTML (for inserting pre-rendered content)
- `{{> partial}}` syntax for including partial templates
- `{{> page}}` syntax for template inheritance
- HTML escaping by default for XSS protection
- No external dependencies
- Pure Zig implementation
- Lightweight and fast

## Installation

### Local Development

Add to your `build.zig.zon`:

```zig
.{
    .name = .your_project,
    .version = "0.1.0",
    .dependencies = .{
        .zig_handlebars = .{
            .path = "libs/zig-handlebars",
        },
    },
}
```

### From Git Repository

```zig
.{
    .dependencies = .{
        .zig_handlebars = .{
            .url = "https://github.com/yourname/zig-handlebars/archive/refs/tags/v0.1.0.tar.gz",
            .hash = "1234567890abcdef...",
        },
    },
}
```

## Usage

### Basic Example

```zig
const std = @import("std");
const handlebars = @import("zig-handlebars");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Initialize the template engine
    var engine = handlebars.TemplateEngine.init(allocator, "templates");
    defer engine.deinit();

    // Create context with variables
    var ctx = handlebars.Context.init(allocator);
    defer ctx.deinit();

    try ctx.set("title", "Hello World");
    try ctx.set("content", "<p>Some content</p>");

    // Render template
    const html = try engine.render("template.hbs", &ctx);
    defer allocator.free(html);

    std.debug.print("{s}\n", .{html});
}
```

### Template Syntax

#### Variable Replacement

```handlebars
<h1>{{title}}</h1>
<p>{{content}}</p>
```

Variables are **automatically escaped** for HTML safety (`<` becomes `&lt;`, etc.).

#### Unescaped HTML

```handlebars
<div>{{{html_content}}}</div>
```

Use triple braces to insert pre-rendered HTML without escaping.

#### Partials

```handlebars
<header>{{> header}}</header>
<footer>{{> footer}}</footer>
```

Include partial templates from the `templates/partials/` directory.

#### Template Inheritance

```handlebars
// Layout template
<html>
<body>
    <header>My Site</header>
    <main>{{> page}}</main>
    <footer>Copyright</footer>
</body>
</html>

// Child template
engine.setPageContent("<h1>My Page</h1><p>Content here</p>");
```

### Template File Example

**templates/post.hbs**:
```handlebars
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>{{title}}</title>
</head>
<body>
    <article>
        <h1>{{title}}</h1>
        <time>{{date_time}}</time>
        <div class="content">
            {{{content}}}
        </div>
    </article>
</body>
</html>
```

## API Reference

### `TemplateEngine`

#### `init(allocator: Allocator, templates_dir: []const u8) TemplateEngine`

Initialize the template engine.

**Parameters:**
- `allocator` - Memory allocator
- `templates_dir` - Directory containing `.hbs` template files

#### `deinit() void`

Free all resources.

#### `enablePartials(partials_dir: []const u8) void`

Enable partial template support.

**Parameters:**
- `partials_dir` - Directory containing partial templates (e.g., `"templates/partials"`)

#### `setPageContent(content: []const u8) void`

Set the page content for template inheritance.

#### `setEscapeEnabled(enabled: bool) void`

Enable or disable HTML escaping for variables (default: `true`).

#### `render(name: []const u8, context: *const Context) ![]const u8`

Render a template file.

**Parameters:**
- `name` - Template filename (e.g., `"post.hbs"`)
- `context` - Context data for variable replacement

**Returns:**
- Rendered output as owned string (caller must free)

#### `renderString(template: []const u8, context: *const Context) ![]const u8`

Render a template string directly.

**Parameters:**
- `template` - Template string content
- `context` - Context data for variable replacement

**Returns:**
- Rendered output as owned string (caller must free)

### `Context`

#### `init(allocator: Allocator) Context`

Create a new context.

#### `deinit() void`

Free all resources.

#### `set(key: []const u8, value: []const u8) !void`

Set a variable in the context. Both key and value are copied.

#### `get(key: []const u8) ?[]const u8`

Get a variable from the context.

#### `has(key: []const u8) bool`

Check if a key exists in the context.

### `TemplateError`

Error union type for template operations:
- `TemplateNotFound` - Template file doesn't exist
- `InvalidSyntax` - Invalid template syntax
- `ContextKeyMissing` - Required context key is missing
- `FileReadFailed` - Failed to read template file
- `OutOfMemory` - Memory allocation failed

## Running Tests

```bash
cd libs/zig-handlebars
zig build test
```

## Running Example

```bash
zig build run
```

## Security Notes

- Variables are HTML-escaped by default to prevent XSS attacks
- Use `{{{var}}}` (triple braces) only when you trust the content
- Use `setEscapeEnabled(false)` with caution

## Project Structure

```
zig-handlebars/
├── src/
│   ├── root.zig           # Main module exports
│   ├── engine.zig         # TemplateEngine implementation
│   ├── context.zig        # Context implementation
│   ├── partials.zig       # PartialsManager implementation
│   ├── html_escape.zig    # HTML escaping utilities
│   ├── error.zig          # Error types
│   └── test_partial.zig   # Example application
├── templates/
│   └── partials/          # Partial templates
├── build.zig              # Build configuration
└── README.md              # This file
```

## License

MIT License - See LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
