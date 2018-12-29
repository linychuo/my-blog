use std::fs::{self, File};
use std::io;
use std::path::PathBuf;

use comrak::ComrakOptions;
use handlebars::Handlebars;
use serde_json::json;

use crate::post::{Header, Post};

#[derive(Debug)]
pub struct Blogger {
    dest_dir: PathBuf,
    post_dir: PathBuf,
    hbs: Handlebars,
    comrak_options: ComrakOptions,
}

impl Blogger {
    pub fn new(dest_dir: PathBuf, post_dir: PathBuf, template_dir: PathBuf) -> Blogger {
        let mut hbs = Handlebars::new();
        hbs.set_strict_mode(true);
        hbs.register_templates_directory(".hbs", template_dir)
            .expect("register handlebars failed!");
        // create dest dir
        fs::create_dir_all(&dest_dir).expect("create root folder failed!");

        Blogger {
            dest_dir,
            post_dir,
            hbs,
            comrak_options: ComrakOptions {
                ext_header_ids: Some(String::new()),
                ..ComrakOptions::default()
            },
        }
    }

    pub fn render_posts(&self, exclude: Vec<&str>) -> io::Result<()> {
        let all_posts = self.load_posts(exclude)?;
        self.render_other("index", json!({"parent": "layout", "posts": all_posts}));
        for item in all_posts {
            item.render(&self.hbs);
        }

        Ok(())
    }

    pub fn render(&self, file_path: &str) {
        let f_path = PathBuf::from(file_path);
        let (_, contents) = self.parse_content(&f_path);
        self.render_other("about", json!({"parent": "layout", "contents": contents}));
    }

    pub fn copy_static_files(&self, src_dir: PathBuf, dest_dir: PathBuf) -> io::Result<()> {
        for entry in fs::read_dir(src_dir)? {
            let entry_path = entry?.path();
            let entry_path_name = entry_path.file_name().unwrap().to_str().unwrap();
            if entry_path.is_dir() {
                let new_dir = dest_dir.join(entry_path_name);
                fs::create_dir_all(&new_dir)?;
                self.copy_static_files(entry_path, new_dir)?;
            } else {
                if !dest_dir.exists() {
                    fs::create_dir_all(&dest_dir)?;
                }
                let new_file_path = dest_dir.join(entry_path_name);
                fs::copy(&entry_path, &new_file_path)?;
            }
        }

        Ok(())
    }

    fn load_posts(&self, exclude: Vec<&str>) -> io::Result<Vec<Post>> {
        let mut all_posts: Vec<Post> = vec![];
        for entry in fs::read_dir(&self.post_dir)? {
            let entry_path = entry?.path();
            if entry_path.is_file() {
                let file_name = entry_path.file_name().unwrap();
                if !exclude.contains(&file_name.to_str().unwrap()) {
                    let (header, contents) = self.parse_content(&entry_path);
                    let file_stem = entry_path.file_stem().unwrap();
                    all_posts.push(Post::new(
                        self.dest_dir.to_str().unwrap(),
                        header,
                        file_stem.to_str().unwrap(),
                        contents,
                    ));
                }
            }
        }

        Ok(all_posts)
    }

    fn parse_content(&self, entry_path: &PathBuf) -> (Header, String) {
        let contents = fs::read_to_string(entry_path).unwrap();
        if contents.starts_with("---") {
            let end_of_yaml = contents[4..].find("---").unwrap() + 4;
            let header = serde_yaml::from_str(&contents[..end_of_yaml]).unwrap();
            let contents =
                comrak::markdown_to_html(&contents[end_of_yaml + 5..], &self.comrak_options);
            (header, contents)
        } else {
            (
                Header::default(),
                comrak::markdown_to_html(&contents, &self.comrak_options),
            )
        }
    }

    fn render_other(&self, file_name: &str, data: serde_json::Value) {
        self.dest_dir.join(file_name).set_extension("html");
        let mut n_f = PathBuf::from(&self.dest_dir.join(file_name));
        n_f.set_extension("html");

        let file = File::create(n_f).expect("create file failed!");
        self.hbs
            .render_to_write(file_name, &data, file)
            .expect("render failed!");
    }
}
