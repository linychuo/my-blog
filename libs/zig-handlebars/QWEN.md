# Project Context: zig-handlebars

## Project Overview

**zig-handlebars** is a lightweight Handlebars-style template engine implemented in pure Zig. It provides simple template rendering capabilities with variable substitution, HTML escaping for security, partial templates, and template inheritance support.

### Purpose
- Render Handlebars-style templates with `{{variable}}` syntax
- Support unescaped HTML output with `{{{html}}}` syntax
- Provide partial template inclusion with `{{> partial}}`
- Enable template inheritance with `{{> page}}` syntax
- Provide HTML escaping by default for XSS protection
- Dependency-free, pure Zig solution

### Main Technologies
- **Language**: Zig (minimum version 0.15.0)
- **Template Syntax**: Handlebars-inspired (`{{}}`, `{{{}}}`, `{{> partial}}`)
- **Dependencies**: None (pure Zig, uses only std library)

## Project Structure

```
zig-handlebars/
├── build.zig              # Build configuration (Zig build system)
├── build.zig.zon          # Package manifest (name, version, paths)
├── README.md              # User-facing documentation
├── QWEN.md                # Development context (this file)
├── src/
│   ├── root.zig           # Main library module exports
│   ├── engine.zig         # TemplateEngine implementation
│   ├── context.zig        # Context implementation
│   ├── partials.zig       # PartialsManager implementation
│   ├── html_escape.zig    # HTML escaping utilities
│   ├── error.zig          # Error type definitions
│   └── test_partial.zig   # Example application
└── templates/
    └── partials/          # Template partials directory
        └── test.hbs       # Example partial template
```

## Building and Running

### Prerequisites
- Zig compiler version 0.15.0 or higher

### Build Commands

| Command | Description |
|---------|-------------|
| `zig build` | Build the library |
| `zig build test` | Run unit tests |
| `zig build run` | Run the example application |

### Running Tests
```bash
zig build test
```

### Using as a Dependency

Add to your `build.zig.zon`:
```zig
.{
    .dependencies = .{
        .zig_handlebars = .{
            .path = "libs/zig-handlebars",
        },
    },
}
```

Import in your Zig code:
```zig
const handlebars = @import("zig-handlebars");
```

## Source Files Description

### `src/root.zig`
Main module entry point that exports the public API:
- `TemplateEngine` - Core template rendering engine
- `Context` - Template variable container
- `TemplateError` - Error union type
- `PartialsManager` - Partial template manager
- `escapeHtml` - HTML escaping function

### `src/engine.zig`
TemplateEngine implementation with:
- Template loading and rendering
- Variable substitution with HTML escaping
- Unescaped HTML support (`{{{}}}`)
- Partial template support (`{{>}}`)
- Template inheritance (`{{> page}}`)

**Key Methods:**
- `init(allocator, templates_dir)` - Initialize engine
- `deinit()` - Free resources
- `enablePartials(partials_dir)` - Enable partial support
- `setPageContent(content)` - Set child template content
- `setEscapeEnabled(enabled)` - Toggle HTML escaping
- `render(name, context)` - Render template file
- `renderString(template, context)` - Render template string

### `src/context.zig`
Context struct for storing template variables with proper memory ownership.

**Key Methods:**
- `init(allocator)` - Create new context
- `deinit()` - Free all resources
- `set(key, value)` - Set variable (copies both)
- `get(key)` - Get variable value
- `has(key)` - Check if key exists
- `getOrError(key)` - Get or return error

### `src/partials.zig`
PartialsManager for loading and caching partial templates.

**Key Methods:**
- `init(allocator, fs_dir, partials_dir)` - Initialize manager
- `deinit()` - Free cached partials
- `loadPartial(name)` - Load partial by name
- `renderPartial(name, context, render_fn)` - Render partial with context
- `cacheCount()` - Get cache size (for testing)

### `src/html_escape.zig`
HTML escaping utilities for XSS protection.

**Functions:**
- `escapeHtml(allocator, input)` - Escape HTML special characters
  - `&` → `&amp;`
  - `<` → `&lt;`
  - `>` → `&gt;`
  - `"` → `&quot;`
  - `'` → `&#x27;`

### `src/error.zig`
Error type definitions:
```zig
pub const TemplateError = error{
    TemplateNotFound,
    InvalidSyntax,
    ContextKeyMissing,
    FileReadFailed,
    WriteFailed,
    OutOfMemory,
};
```

### `src/test_partial.zig`
Example application demonstrating all features:
- Variable substitution
- HTML escaping
- Unescaped HTML
- Partials
- Template inheritance
- XSS protection

## Template Syntax

### Variable Replacement
```handlebars
<h1>{{title}}</h1>
<p>{{content}}</p>
```
Variables are automatically HTML-escaped for security.

### Unescaped HTML
```handlebars
<div>{{{html_content}}}</div>
```
Triple braces insert raw HTML without escaping.

### Partials
```handlebars
{{> header}}
{{> footer}}
```
Includes partial templates from `templates/partials/`.

### Template Inheritance
```handlebars
{{> page}}
```
Inserts content set via `setPageContent()`.

## Usage Example

```zig
const std = @import("std");
const handlebars = @import("zig-handlebars");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Initialize engine
    var engine = handlebars.TemplateEngine.init(allocator, "templates");
    defer engine.deinit();

    // Enable partials
    engine.enablePartials("templates/partials");

    // Create context
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

## Testing Practices

- Tests use Zig's built-in `test` blocks
- Located alongside implementation in each module
- Run with `zig build test`
- Use `std.testing` utilities for assertions
- Memory leaks detected automatically with `std.testing.allocator`

## Development Notes

- **No external dependencies** - Uses only Zig standard library
- **Memory management** - Context and PartialsManager own their data
- **Arena allocator recommended** - For managing temporary allocations
- **Template files** - Convention is to use `.hbs` extension
- **Partials location** - Stored in `templates/partials/` subdirectory
- **HTML escaping** - Enabled by default for security

## Current Status

**Stable** - Core functionality implemented:
- [x] Variable substitution `{{var}}`
- [x] HTML escaping (default enabled)
- [x] Unescaped HTML `{{{html}}}`
- [x] Partials support `{{> partial}}`
- [x] Template inheritance (`{{> page}}` tag)
- [x] Unit tests (20+ tests)
- [x] Example application
- [ ] Advanced helpers (loops, conditionals) - not yet implemented
- [ ] Block helpers - not yet implemented

## Integration with hello-zig

This library is used by the parent `hello-zig` project for rendering blog post templates. The blog generator uses zig-handlebars to:
1. Load post templates from the `templates/` directory
2. Inject post metadata (title, date, tags) into templates
3. Render markdown content as HTML within template layouts

## API Changes (v0.1.0)

Recent updates:
- Simplified `init()` to 2 parameters (removed `fs_dir`, uses `cwd()` by default)
- Added `initWithDir()` for custom filesystem directory
- Added `enablePartials()` for partial template support
- Added `setEscapeEnabled()` for controlling HTML escaping
- Added `TemplateError` error union type
- Context now owns its data (copies keys and values)
- PartialsManager caches loaded partials
