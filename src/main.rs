use crate::blogger::Blogger;
use std::path::PathBuf;
use structopt::StructOpt;

mod blogger;
mod post;

#[derive(Debug, StructOpt)]
struct Cli {
	#[structopt(default_value = "./posts")]
	posts_dir: String,
	#[structopt(default_value = "./static")]
	static_files_dir: String,
	#[structopt(default_value = "./templates")]
	templates_dir: String,
	#[structopt(default_value = "./build")]
	build_dir: String,
	#[structopt(default_value = "about")]
	excludes: Vec<String>,
}

fn main() {
	let args = Cli::from_args();
	let blog = Blogger::new(&args.build_dir, &args.posts_dir, &args.templates_dir);

	blog.render_posts(&args.excludes)
		.expect("render all posts failed!");
	for it in args.excludes {
		blog.render(it.as_str()).unwrap();
	}

	Blogger::copy_static_files(
		PathBuf::from(&args.static_files_dir),
		PathBuf::from(&args.build_dir),
	);
}
