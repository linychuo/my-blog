use std::env;
use std::path::PathBuf;

use my_blog::blogger::Blogger;
use my_blog::static_files::copy_static_files;

struct Config {
    posts_dir: PathBuf,
    static_dir: PathBuf,
    templates_dir: PathBuf,
    build_dir: PathBuf,
    excludes: Vec<String>,
}

impl Config {
    fn from_env() -> Self {
        let dir = |var, default| {
            env::var(var).map(PathBuf::from).unwrap_or_else(|_| PathBuf::from(default))
        };
        Config {
            posts_dir: dir("POSTS_DIR", "./posts"),
            static_dir: dir("STATIC_DIR", "./static"),
            templates_dir: dir("TEMPLATES_DIR", "./templates"),
            build_dir: dir("BUILD_DIR", "./build"),
            excludes: env::var("EXCLUDES")
                .unwrap_or_else(|_| "about".to_string())
                .split(',')
                .map(|s| s.trim().to_string())
                .filter(|s| !s.is_empty())
                .collect(),
        }
    }
}

fn main() {
    let config = Config::from_env();
    let blog = match Blogger::new(&config.build_dir, &config.posts_dir, &config.templates_dir) {
        Ok(b) => b,
        Err(e) => {
            eprintln!("Failed to initialize blogger: {}", e);
            std::process::exit(1);
        }
    };

    if let Err(e) = blog.render_posts(&config.excludes) {
        eprintln!("Failed to render all posts: {}", e);
        std::process::exit(1);
    }

    for it in &config.excludes {
        if let Err(e) = blog.render(it) {
            eprintln!("Failed to render '{}': {}", it, e);
            std::process::exit(1);
        }
    }

    if let Err(e) = copy_static_files(&config.static_dir, &config.build_dir) {
        eprintln!("Failed to copy static files: {}", e);
        std::process::exit(1);
    }
}
