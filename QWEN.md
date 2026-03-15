# Project Context: hello-zig

## Project Overview

**hello-zig** is a static blog generator tool written in the [Zig](https://ziglang.org/) programming language. It converts Markdown blog posts to HTML with modern styling, theme switching, tag navigation, and mathematical formula rendering.

### Purpose
- Parse markdown blog posts from the `posts/` directory
- Generate static HTML output with date-based URL structure
- Support tag-based navigation (each tag has its own page)
- Render mathematical formulas using KaTeX
- Provide theme switching (dark/light mode)

### Main Technologies
- **Language**: Zig 0.15.2
- **Markdown Parser**: Custom implementation in `libs/zig-markdown/`
- **Template Engine**: Custom Handlebars-style engine in `libs/zig-handlebars/`
- **Math Rendering**: KaTeX 0.12.0 for LaTeX formulas
- **Syntax Highlighting**: highlight.js 11.9.0
- **Styling**: CSS with CSS variables for theme support
- **Fonts**: Inter (body), JetBrains Mono (code)

## Project Structure

```
hello-zig/
├── build.zig              # Build configuration (Zig build system)
├── build.zig.zon          # Package manifest (dependencies, version)
├── src/
│   ├── main.zig           # Application entry point
│   └── Blogger.zig        # Core blog generation logic
├── templates/
│   ├── layout.hbs         # Main layout template
│   ├── index.hbs          # Homepage template
│   ├── post.hbs           # Article page template
│   ├── about.hbs          # About page template
│   └── tag.hbs            # Tag page template
├── static/
│   ├── style.css          # Main stylesheet
│   └── imgs/              # Static images
├── libs/
│   ├── zig-markdown/      # Markdown to HTML converter
│   └── zig-handlebars/    # Template engine
├── posts/                 # Source markdown blog posts
└── zig-out/               # Build output directory
```

## Building and Running

### Prerequisites
- Zig compiler version 0.15.2 or higher

### Build Commands

| Command | Description |
|---------|-------------|
| `zig build` | Build the project (default step) |
| `zig build run` | Build and run in Debug mode |
| `zig build -Doptimize=ReleaseFast run` | Build and run in Release mode |
| `zig build test` | Run all tests |
| `zig build --help` | Show all available build options |

### Running the Application
```bash
zig build run
# Or with custom paths:
zig build run -- --posts ./my-posts --output ./public
```

### CLI Options
```
-p, --posts <dir>    Posts source directory (default: posts)
-o, --output <dir>   Output directory (default: zig-out/blog)
-h, --help           Show help message
```

## Source Files Description

### `src/main.zig`
- Application entry point with `main()` function
- Parses command line arguments (--posts, --output, --help)
- Creates Blogger instance and calls generate()

### `src/Blogger.zig`
- Core module containing the `Blogger` struct and `Post` struct
- **Post struct**: Parses markdown frontmatter (title, date_time, tags)
- **Blogger fields**:
  - `dest_dir`: Output directory for generated content
  - `posts_dir`: Source directory for markdown posts
  - `template_engine`: Handlebars-style template engine
- **Blogger methods**:
  - `new()`: Constructor
  - `generate()`: Main entry point for site generation
  - `loadPosts()`: Load and parse markdown posts
  - `generatePostPage()`: Generate individual post HTML
  - `generateIndex()`: Generate homepage with post list
  - `generateAbout()`: Generate about.html from about.markdown
  - `generateTagPages()`: Generate tag pages with post lists
  - `copyStaticFiles()`: Copy static assets to output

### `libs/zig-markdown/`
- Custom Markdown to HTML converter
- **Supported features**:
  - Headers (h1-h6) with inline formatting
  - Ordered and unordered lists
  - Code blocks with syntax highlighting
  - Tables with proper styling
  - Blockquotes with line breaks
  - Inline code, bold, italic, strikethrough
  - Links and images
  - Math blocks (`$$...$$`) for LaTeX formulas
  - Line breaks (`\` at end of line)

### `libs/zig-handlebars/`
- Custom Handlebars-style template engine
- **Features**:
  - Variable substitution: `{{variable}}`
  - Unescaped HTML: `{{{html}}}`
  - Inline blocks: `{{#*inline "name"}}...{{/inline}}`
  - Template inheritance: `{{~> (parent)~}}`
  - Partial templates: `{{~> partial}}`

## Blog Post Format

Posts in `posts/` use markdown with YAML-like frontmatter:

```markdown
---
title: "Post Title"
date_time: YYYY-MM-DD HH:MM:SS
tags: tag1 tag2
---

Post content here...
```

### Supported Markdown Syntax
- `#` to `######` - Headers
- `**text**` - Bold
- `*text*` - Italic
- `~~text~~` - Strikethrough
- `` `code` `` - Inline code
- ` ```language ` - Code blocks
- `| col | col |` - Tables
- `> quote` - Blockquotes
- `$$...$$` - Math formulas (LaTeX)
- `\` at line end - Line break

## Output Structure

Generated site in `zig-out/blog/`:

```
zig-out/blog/
├── index.html           # Homepage with post list
├── about.html           # About page
├── style.css            # Stylesheet
├── imgs/                # Copied images
├── tags/
│   ├── tag1.html        # Tag page
│   └── tag2.html
└── YYYY/
    └── MM/
        └── DD/
            └── post-name.html  # Date-based post URLs
```

## Features

### Core Features
- ✅ Markdown to HTML conversion
- ✅ Date-based URL structure (`/YYYY/MM/DD/slug.html`)
- ✅ Tag pages (each tag has its own page listing related posts)
- ✅ About page generation
- ✅ Static file copying

### Styling & UX
- ✅ Dark/Light theme switching with auto-detect
- ✅ Theme preference persistence (localStorage)
- ✅ Back-to-top button
- ✅ Responsive design (mobile-friendly)
- ✅ Card-based post list with hover animations
- ✅ Professional typography with CSS variables

### Advanced Features
- ✅ Syntax highlighting (highlight.js)
- ✅ Mathematical formula rendering (KaTeX)
- ✅ Table styling
- ✅ Tag navigation

## Development Notes

- Uses Zig's built-in build system (no external build tools)
- Package name: `hello_zig`
- Output binary name: `hello_zig`
- Debug mode has GeneralPurposeAllocator that reports memory leaks
- Release mode recommended for production builds

## Current Status

**Feature Complete** - Core blogging functionality is fully implemented.

### Completed
- [x] Project scaffolding
- [x] Build configuration
- [x] Markdown parsing (full CommonMark + extensions)
- [x] HTML generation
- [x] Post metadata extraction
- [x] Template engine
- [x] Tag system with tag pages
- [x] Theme switching
- [x] Responsive design
- [x] Math formula rendering (KaTeX)
- [x] Syntax highlighting
- [x] Date-based URLs
- [x] About page generation

### Potential Future Enhancements
- [ ] Pagination for large post lists
- [ ] RSS/Atom feed generation
- [ ] Search functionality
- [ ] Sitemap.xml generation
- [ ] SEO meta tags
- [ ] Reading time estimation
- [ ] Related posts section
- [ ] Comments integration
