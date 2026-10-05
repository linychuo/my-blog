use std::env;
use std::path::PathBuf;

use crate::blogger::Blogger;

mod blogger;
mod post;

pub const DEFAULT_POST_EXT: &str = "markdown";
pub const DEFAULT_HTML_EXT: &str = "html";

fn main() {
    let posts_dir = env::var("POSTS_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from("./posts"));
    let static_files_dir = env::var("STATIC_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from("./static"));
    let templates_dir = env::var("TEMPLATES_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from("./templates"));
    let build_dir = env::var("BUILD_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from("./build"));
    let excludes: Vec<String> = env::var("EXCLUDES")
        .unwrap_or_else(|_| "about".to_string())
        .split(',')
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect();

    let blog = Blogger::new(&build_dir, &posts_dir, &templates_dir);

    if let Err(e) = blog.render_posts(&excludes) {
        eprintln!("Failed to render all posts: {}", e);
        std::process::exit(1);
    }

    for it in &excludes {
        if let Err(e) = blog.render(it) {
            eprintln!("Failed to render post '{}': {}", it, e);
            std::process::exit(1);
        }
    }

    if let Err(e) = Blogger::copy_static_files(static_files_dir, build_dir) {
        eprintln!("Failed to copy static files: {}", e);
        std::process::exit(1);
    }
}
