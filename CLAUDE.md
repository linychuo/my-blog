# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

- `zig build` - Build the project
- `zig build run` - Build and run in Debug mode
- `zig build -Doptimize=ReleaseFast run` - Build and run in Release mode
- `zig build test` - Run all tests

CLI options: `-p/--posts <dir>` (posts source, default: `posts`), `-o/--output <dir>` (output directory, default: `build`)

## Architecture

**my-blog** is a static blog generator written in Zig. It reads Markdown posts from `posts/`, parses frontmatter (title, date_time, tags), converts to HTML using a custom markdown parser, and renders through a custom Handlebars-style template engine.

### Key Modules

- `src/main.zig` - Entry point; parses CLI args and invokes Blogger
- `src/Blogger.zig` - Orchestration: coordinates generators, manages post loading and sorting
- `src/Post.zig` - Post data structure with frontmatter parsing
- `src/FileSystem.zig` - File operations: static copy, post loading, HTML writing
- `src/generators/` - Page generators
  - `index.zig` - Homepage generation
  - `post.zig` - Individual post page generation
  - `about.zig` - About page generation
  - `tag.zig` - Tag listing pages generation
- `src/utils/` - Shared utilities
  - `path.zig` - URL path building from date/filename
  - `html.zig` - HTML snippet builders (tags, post items)
  - `datetime.zig` - Date/time utilities (current year)

### zig-markdown (`libs/zig-markdown/src/`)

Custom Markdown-to-HTML converter with block processor architecture.

**Core:**
- `markdown.zig` - Main entry, processes lines sequentially using ParserState
- `parser.zig` - ParserState (all block state) + helper functions (closeParagraphAndLists, closeLists, etc.)
- `inline.zig` - Inline element processing (bold, italic, code, links, images)
- `html_writer.zig` - HTML output wrapper

**Block Processors (`blocks/`):**
- `header.zig` - H1-H6 detection and rendering
- `hr.zig` - Horizontal rule (---, ***, ___)
- `code_block.zig` - Fenced code blocks (```)
- `list.zig` - Ordered/unordered lists, list items
- `blockquote.zig` - Blockquotes (> quote)
- `paragraph.zig` - Paragraphs with inline processing
- `math_block.zig` - Math blocks ($$...$$)
- `table.zig` - Tables (| col | col |)

### zig-handlebars (`libs/zig-handlebars/src/`)

Custom Handlebars-style template engine.

- `loader.zig` - Template file loading from filesystem
- `tag_parser.zig` - Handlebars tag parsing ({{variable}}, {{{unescaped}}}, {{> partial}}, {{~> partial}})
- `renderer.zig` - Template rendering (tag parsing + variable rendering with HTML escaping)
- `engine.zig` - Orchestration: loads template, renders, processes partials recursively
- `partials.zig` - Partial template caching and loading
- `context.zig` - Template variable storage
- `html_escape.zig` - HTML entity escaping
- `error.zig` - Error types

**Template Inheritance:**
Templates use inline partials with `{{#*inline "name"}}...{{/inline}}` and `{{~> (parent)}}` for inheritance. The `~` prefix on partials (`{{~> partial}}`) suppresses leading/trailing whitespace.

### Data Flow

1. `main.zig` parses `--posts` and `--output` paths
2. `FileSystem.loadPosts()` reads all `.markdown` files from `posts/`, extracts frontmatter
3. `Blogger.generate()` orchestrates:
   - Copies static files via `FileSystem.copyStaticFiles()`
   - Generates post pages via `generators/post.zig`
   - Generates index via `generators/index.zig`
   - Generates about page via `generators/about.zig`
   - Generates tag pages via `generators/tag.zig`

### Post Format

```markdown
---
title: "Post Title"
date_time: YYYY-MM-DD HH:MM:SS
tags: tag1 tag2
---

Post content with **markdown** support, $$math blocks$$, and ```code blocks```.
```

### Supported Markdown Syntax

- `#` to `######` - Headers
- `**text**` - Bold, `*text*` - Italic, `~~text~~` - Strikethrough
- `` `code` `` - Inline code, ` ```language ` - Code blocks
- `| col | col |` - Tables, `> quote` - Blockquotes
- `$$...$$` - Math formulas (LaTeX), `\` at line end - Line break

### Dependencies

Uses Zig 0.15.2 with two local dependencies defined in `build.zig.zon`:
- `zig_markdown` (local path: `libs/zig-markdown/`)
- `zig_handlebars` (local path: `libs/zig-handlebars/`)

### Output Structure

Generated site in `build/` (or `--output` directory):
```
build/
├── index.html           # Homepage with post list
├── about.html          # About page
├── style.css           # Stylesheet
├── imgs/               # Copied images
├── tags/
│   └── tag.html        # Tag page
└── YYYY/MM/DD/
    └── post-name.html  # Date-based post URLs
```
