use crate::blogger::Blogger;
use serde_derive::Deserialize;
use std::fs;
use std::path::PathBuf;
use toml;

mod blogger;
mod post;

#[derive(Deserialize, Debug)]
struct Config {
    posts_dir: String,
    static_files_dir: String,
    templates_dir: String,
    build_dir: String,
    excludes: Vec<String>,
}

fn main() {
    let config_content = fs::read_to_string("config.toml").unwrap();
    let config: Config = toml::from_str(config_content.as_str()).unwrap();
    dbg!(&config);

    let blog = Blogger::new(&config.build_dir, &config.posts_dir, &config.templates_dir);

    blog.render_posts(&config.excludes)
        .expect("render all posts failed!");
    for it in config.excludes {
        blog.render(it.as_str()).expect("render about file failed!");
    }

    Blogger::copy_static_files(
        PathBuf::from(&config.static_files_dir),
        PathBuf::from(&config.build_dir),
    );
}
