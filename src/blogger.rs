use std::ffi::OsStr;
use std::fs;
use std::path::{Path, PathBuf};
use std::rc::Rc;
use std::collections::HashMap;

use comrak::ComrakOptions;
use serde_json::json;
use tera::Tera;

use crate::DEFAULT_POST_EXT;
use crate::error::BlogError;
use crate::post::{self, Post};
use crate::template;

#[derive(Debug)]
pub struct Blogger {
    dest_dir: PathBuf,
    posts_dir: PathBuf,
    tera: Tera,
    comrak_options: ComrakOptions<'static>,
}

type Tags = HashMap<String, Vec<Rc<Post>>>;

impl Blogger {
    pub fn new(dest_dir: &Path, posts_dir: &Path, template_dir: &Path) -> Result<Blogger, BlogError> {
        fs::create_dir_all(dest_dir).expect("create dest dir failed");

        Ok(Blogger {
            dest_dir: dest_dir.to_path_buf(),
            posts_dir: posts_dir.to_path_buf(),
            tera: template::load_templates(template_dir)?,
            comrak_options: post::build_comrak_options(),
        })
    }

    pub fn render_posts(&self, exclude: &[String]) -> Result<(), BlogError> {
        let (mut all_posts, tags) = self.load_posts(exclude)?;
        all_posts.sort_by(|a, b| b.header.date_time.cmp(&a.header.date_time));
        self.render_template("index", &json!({"posts": all_posts}))?;

        for item in &all_posts {
            item.render(&self.dest_dir, &self.tera)?;
        }

        let tags_dir = self.dest_dir.join("tags");
        if !tags_dir.exists() {
            fs::create_dir(tags_dir)?;
        }

        for (k, v) in tags {
            self.render_template("tags", &json!({"tag": k, "posts": v}))?;
        }

        Ok(())
    }

    pub fn render(&self, file_path: &str) -> Result<(), BlogError> {
        let new_path = Path::new(file_path);
        let dest_file_name = new_path.file_stem().and_then(OsStr::to_str).unwrap_or("");
        let mut path = self.posts_dir.join(file_path);
        path.set_extension(DEFAULT_POST_EXT);
        let contents = self.render_markdown(&path)?;
        self.render_template(dest_file_name, &json!({"contents": contents}))?;

        Ok(())
    }

    fn load_posts(&self, excludes: &[String]) -> Result<(Vec<Rc<Post>>, Tags), BlogError> {
        let mut all_posts: Vec<Rc<Post>> = vec![];
        for entry in fs::read_dir(&self.posts_dir)? {
            let entry_path = entry?.path();
            if !&entry_path.is_file() {
                continue;
            }

            if entry_path.extension().and_then(|s| s.to_str()) != Some(DEFAULT_POST_EXT) {
                continue;
            }

            let entry_name = match entry_path.file_stem().and_then(OsStr::to_str) {
                Some(name) => name,
                _ => continue,
            };

            if excludes.iter().any(|e| e == entry_name) {
                continue;
            }

            match Post::of(entry_path.as_path(), entry_name, &self.comrak_options) {
                Ok(post) => {
                    all_posts.push(Rc::new(post));
                }
                Err(e) => {
                    eprintln!("Warning: skipping '{}': {}", entry_path.display(), e);
                }
            }
        }

        let mut tags: Tags = HashMap::new();
        for post in &all_posts {
            for tag in &post.tags {
                tags.entry(tag.to_string()).or_default().push(post.clone());
            }
        }

        Ok((all_posts, tags))
    }

    fn render_markdown(&self, entry_path: &Path) -> Result<String, BlogError> {
        let contents = fs::read_to_string(entry_path)?;
        Ok(comrak::markdown_to_html(&contents, &self.comrak_options))
    }

    fn render_template(&self, template_name: &str, data: &serde_json::Value) -> Result<(), BlogError> {
        template::render_template(&self.tera, &self.dest_dir, template_name, data)
    }
}
