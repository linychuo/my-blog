use std::fs;
use std::fs::File;
use std::io;
use std::path::Path;

use comrak::ComrakOptions;
use handlebars::Handlebars;
use serde_derive::{Deserialize, Serialize};
use serde_json::json;

#[derive(Default, Serialize, Deserialize)]
struct Post {
	title: String,
	created_date_time: String,
	dir: String,
	file_name: String,
	contents: String,
}

#[derive(Debug, Default, Serialize, Deserialize)]
struct Header {
	title: String,
	date_time: String,
}

impl Post {
	fn render(&self, parent_dir: &str, hbs: &Handlebars, data: serde_json::Value) {
		let file = File::create(format!("{}{}/{}.html", &parent_dir, self.dir, self.file_name))
			.expect("create file failed!");
		hbs.render_to_write("post", &data, file).expect("render post failed!");
	}
}

/*
1. iter each post
2. parse content from markdown to html
3. create html file after creating outer directory
4. copy static files into directory
*/
fn main() -> io::Result<()> {
	let mut hbs = Handlebars::new();
	hbs.set_strict_mode(true);
	hbs.register_templates_directory(".hbs", "templates")
		.expect("register handlebars failed!");

	let root_dir = "./build";
	fs::create_dir_all(&root_dir).expect("create root folder failed!");

	let all_posts = load_posts("_posts").expect("read all posts failed!");
	render_other(&root_dir, "index", &hbs,
				 json!({"parent": "layout", "posts": all_posts}));

	for item in &all_posts {
		fs::create_dir_all(format!("{}{}", &root_dir, item.dir)).expect("create sub folder failed!");
		item.render(&root_dir, &hbs, json!({
				"parent": "layout",
				"post": item,
			}));
	}

	let about_path = Path::new("./_posts/about.markdown");
	let options = ComrakOptions {
		ext_header_ids: Some(String::new()),
		..ComrakOptions::default()
	};
	let (_, contents) = parse_content(&about_path, &options);
	render_other(&root_dir, "about", &hbs,
				 json!({"parent": "layout", "contents": contents}));

	copy_static_files(Path::new("static"), Path::new("build"))?;
	Ok(())
}

fn load_posts(dir: &str) -> io::Result<Vec<Post>> {
	let options = ComrakOptions {
		ext_header_ids: Some(String::new()),
		..ComrakOptions::default()
	};
	let mut all_posts: Vec<Post> = vec![];
	let exclude_file = ["about.markdown"];

	for entry in fs::read_dir(dir)? {
		let entry_path = entry?.path();
		if entry_path.is_file() {
			let file_name = entry_path.file_name().unwrap();
			if !exclude_file.contains(&file_name.to_str().unwrap()) {
				let (header, contents) = parse_content(entry_path.as_path(),
													   &options);

				let mut split = header.date_time.split_whitespace();
				let date = split.next().unwrap();
				let v: Vec<&str> = date.split('-').collect();

				let file_stem = entry_path.file_stem().unwrap();
				all_posts.push(Post {
					file_name: file_stem.to_str().unwrap().to_string(),
					contents,
					title: header.title,
					created_date_time: header.date_time.to_string(),
					dir: format!("/{}/{}/{}", v[0], v[1], v[2]),
				});
			}
		}
	}

	Ok(all_posts)
}


fn parse_content(entry_path: &Path, options: &ComrakOptions) -> (Header, String) {
	let contents = fs::read_to_string(&entry_path).unwrap();
	if contents.starts_with("---") {
		let end_of_yaml = contents[4..].find("---").unwrap() + 4;
		let header = serde_yaml::from_str(&contents[..end_of_yaml]).unwrap();
		let contents = comrak::markdown_to_html(&contents[end_of_yaml + 5..],
												&options);
		(header, contents)
	} else {
		(Header::default(), comrak::markdown_to_html(&contents, &options))
	}
}

fn render_other(parent_dir: &str, file_name: &str, hbs: &Handlebars, data: serde_json::Value) {
	let file = File::create(format!("{}/{}.html", parent_dir, file_name))
		.expect("create file failed!");
	hbs.render_to_write(file_name, &data, file).expect("render failed!");
}

fn copy_static_files(src_dir: &Path, dest_dir: &Path) -> io::Result<()> {
	for entry in fs::read_dir(src_dir)? {
		let entry_path = entry?.path();
		if entry_path.is_dir() {
			fs::create_dir_all(dest_dir.join(&entry_path))?;
			copy_static_files(entry_path.as_path(), dest_dir);
		} else {
			fs::copy(&entry_path, dest_dir.join(src_dir).join(&entry_path))?;
		}
	}

	Ok(())
}
