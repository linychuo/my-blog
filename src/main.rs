use std::env;
use std::path::PathBuf;

use anyhow::Result;

use my_blog::blogger::Blogger;
use my_blog::static_files::copy_static_files;

fn env_dir(var: &str, default: &str) -> PathBuf {
    env::var(var).map(PathBuf::from).unwrap_or_else(|_| PathBuf::from(default))
}

fn main() -> Result<()> {
    let posts_dir = env_dir("POSTS_DIR", "./posts");
    let static_dir = env_dir("STATIC_DIR", "./static");
    let templates_dir = env_dir("TEMPLATES_DIR", "./templates");
    let build_dir = env_dir("BUILD_DIR", "./build");
    let excludes: Vec<String> = env::var("EXCLUDES")
        .unwrap_or_else(|_| "about".to_string())
        .split(',')
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect();

    let blog = Blogger::new(&build_dir, &posts_dir, &templates_dir)?;
    blog.render_posts(&excludes)?;

    for it in &excludes {
        blog.render(it)?;
    }

    copy_static_files(&static_dir, &build_dir)?;

    Ok(())
}
