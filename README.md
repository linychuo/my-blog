# my-blog

A static blog generator written in Rust. Visit the live site at [Yongchao.Li](https://yongchao.li).

## Features

- Markdown posts with YAML front matter
- Tera templates with inheritance
- Tag pages with automatic indexing
- Static file copying
- Zero runtime dependencies — single binary output

## Quick Start

```bash
# Build
cargo build --release

# Run with default directories
./target/release/my-blog

# Run with custom configuration
POSTS_DIR=./posts STATIC_DIR=./static TEMPLATES_DIR=./templates BUILD_DIR=build ./target/release/my-blog
```

## Configuration

All configuration is via environment variables, with sensible defaults:

| Variable | Default | Description |
|---|---|---|
| `POSTS_DIR` | `./posts` | Directory containing markdown posts |
| `STATIC_DIR` | `./static` | Static assets (CSS, JS, images) |
| `TEMPLATES_DIR` | `./templates` | Tera template files |
| `BUILD_DIR` | `./build` | Output directory for generated HTML |
| `EXCLUDES` | `about` | Comma-separated list of posts to render as standalone pages |

## Post Format

Posts are markdown files with YAML front matter delimited by `---`:

```markdown
---
title: My Post Title
date_time: 2024-01-15 10:30:00
tags: rust programming
---

Content goes here...
```

The `date_time` field is used for sorting and URL generation (`/YYYY/MM/DD/filename.html`).

## Project Structure

```
src/
├── lib.rs          # Crate root, public constants
├── main.rs         # Entry point, configuration loading
├── error.rs        # Error type and trait implementations
├── post.rs         # Post parsing, Markdown rendering
├── template.rs     # Template loading and rendering
├── blogger.rs      # Core orchestration
└── static_files.rs # Static file copying

posts/              # Markdown source files
templates/          # Tera template files
static/             # Static assets
build/              # Generated output
```

## Dependencies

- [comrak](https://github.com/kivikakk/comrak) — CommonMark markdown rendering
- [tera](https://github.com/Keats/tera) — Template engine
- [serde](https://serde.rs/) + serde_yaml / serde_json — Serialization

## License

Feel free to fork and build your own blog. Issues and contributions are welcome at the [issue tracker](https://github.com/linychuo/my-blog/issues).
