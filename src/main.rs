use crate::blogger::Blogger;
use std::path::PathBuf;
use structopt::StructOpt;

mod blogger;
mod post;

#[derive(Debug, StructOpt)]
struct Cli {
    #[structopt(default_value = "./posts")]
    posts_dir: PathBuf,
    #[structopt(default_value = "./static")]
    static_files_dir: PathBuf,
    #[structopt(default_value = "./templates")]
    templates_dir: PathBuf,
    #[structopt(default_value = "./build")]
    build_dir: PathBuf,
    #[structopt(default_value = "about")]
    excludes: Vec<String>,
}

fn main() {
    let args = Cli::from_args();
    let blog = Blogger::new(&args.build_dir, &args.posts_dir, &args.templates_dir);

    if let Err(e) = blog.render_posts(&args.excludes) {
        eprintln!("Failed to render all posts: {}", e);
        std::process::exit(1);
    }

    for it in &args.excludes {
        if let Err(e) = blog.render(it) {
            eprintln!("Failed to render post '{}': {}", it, e);
            std::process::exit(1);
        }
    }

    Blogger::copy_static_files(args.static_files_dir, args.build_dir);
}
