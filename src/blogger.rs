use std::ffi::OsStr;
use std::fs::{self, File};
use std::io;
use std::path::{Path, PathBuf};

use crate::post::Post;
use crate::{DEFAULT_HTML_EXT, DEFAULT_POST_EXT};
use comrak::ComrakOptions;
use handlebars::{Handlebars, RenderError};
use serde_derive::Serialize;
use serde_json::{json, Value};
use std::collections::HashMap;

#[derive(Debug)]
pub struct Blogger {
    dest_dir: PathBuf,
    posts_dir: PathBuf,
    hbs: Handlebars,
    comrak_options: ComrakOptions,
}

#[derive(Debug, Serialize)]
pub struct TagPost {
    pub title: String,
    pub url: String,
    pub created_date_time: String,
}

type Tags = HashMap<String, Vec<TagPost>>;

fn has_extension(path: &Path, ext: &str) -> bool {
    path.extension()
        .and_then(OsStr::to_str)
        .map_or(false, |e| e == ext)
}

fn contains_string(vec: &[String], s: &str) -> bool {
    vec.iter().any(|item| item == s)
}

impl Blogger {
    pub fn new(dest_dir: &Path, posts_dir: &Path, template_dir: &Path) -> Blogger {
        let mut hbs = Handlebars::new();
        hbs.set_strict_mode(true);
        hbs.register_templates_directory(".hbs", Path::new(template_dir))
            .expect("register dir of templates failed");
        fs::create_dir_all(&dest_dir).expect("create dest dir failed");

        Blogger {
            dest_dir: dest_dir.to_path_buf(),
            posts_dir: posts_dir.to_path_buf(),
            hbs,
            comrak_options: ComrakOptions {
                ..ComrakOptions::default()
            },
        }
    }

    pub fn render_posts(&self, exclude: &[String]) -> Result<(), RenderError> {
        let (mut all_posts, tags) = self.load_posts(exclude)?;
        all_posts.sort_by_key(|post| post.header.date_time.to_string());
        all_posts.reverse();
        self.render_other("index", &json!({"parent": "layout", "posts": all_posts}))?;

        for item in all_posts {
            item.render(&self.dest_dir, &self.hbs)?;
        }

        let tags_dir = self.dest_dir.join("tags");
        if !tags_dir.exists() {
            fs::create_dir(tags_dir)?;
        }
        for (k, v) in tags {
            self.render_tags(
                format!("tags/{}", k),
                "tags",
                &json!({"parent": "layout", "tag":k, "posts": v}),
            )?;
        }

        Ok(())
    }

    pub fn render(&self, file_path: &str) -> Result<(), RenderError> {
        let new_path = Path::new(file_path);
        let dest_file_name = match new_path.file_stem() {
            Some(v) => v.to_str().unwrap(),
            _ => "",
        };
        let mut path = self.posts_dir.join(file_path);
        path.set_extension(DEFAULT_POST_EXT);
        let contents = self.parse_content(&path);
        self.render_other(
            dest_file_name,
            &json!({"parent": "layout", "contents": contents}),
        )?;

        Ok(())
    }

    pub fn copy_static_files(src_dir: PathBuf, dest_dir: PathBuf) {
        for entry in fs::read_dir(src_dir).unwrap() {
            let entry_path = entry.unwrap().path();
            let entry_path_name = entry_path.file_name().unwrap();
            if entry_path.is_dir() {
                let new_dir = dest_dir.join(entry_path_name);
                Blogger::copy_static_files(entry_path, new_dir);
            } else {
                if !dest_dir.exists() {
                    fs::create_dir_all(&dest_dir).unwrap();
                }
                let new_file_path = dest_dir.join(entry_path_name);
                fs::copy(&entry_path, &new_file_path).unwrap();
            }
        }
    }

    fn load_posts(&self, excludes: &[String]) -> io::Result<(Vec<Post>, Tags)> {
        let mut all_posts: Vec<Post> = vec![];
        let mut tags: Tags = HashMap::new();
        for entry in fs::read_dir(&self.posts_dir)? {
            let entry_path = entry?.path();
            if !&entry_path.is_file() {
                continue;
            }

            if !has_extension(&entry_path, DEFAULT_POST_EXT) {
                continue;
            }

            let entry_name = match entry_path.file_stem().and_then(OsStr::to_str) {
                Some(name) => name,
                None => continue,
            };

            if contains_string(excludes, entry_name) {
                continue;
            }

            if let Some(post) = Post::of(&entry_path.as_path(), entry_name, &self.comrak_options) {
                for tag in &post.tags {
                    tags.entry(tag.to_string())
                        .or_insert_with(|| vec![])
                        .push(TagPost {
                            title: post.header.title.to_string(),
                            created_date_time: post.header.date_time.to_string(),
                            url: format!("/{}/{}.{}", post.dir, post.file_name, DEFAULT_HTML_EXT),
                        });
                }
                all_posts.push(post);
            }
        }

        Ok((all_posts, tags))
    }

    fn parse_content(&self, entry_path: &Path) -> String {
        let contents = fs::read_to_string(entry_path).unwrap();
        return comrak::markdown_to_html(&contents, &self.comrak_options);
    }

    fn render_other(&self, template_name: &str, data: &Value) -> Result<(), RenderError> {
        let mut n_f = self.dest_dir.join(template_name);
        n_f.set_extension(DEFAULT_HTML_EXT);

        let file = File::create(n_f)?;
        self.hbs.render_to_write(template_name, data, file)?;

        Ok(())
    }

    fn render_tags(
        &self,
        parent_path: String,
        template_name: &str,
        data: &Value,
    ) -> Result<(), RenderError> {
        let mut n_f = self.dest_dir.join(parent_path);
        n_f.set_extension(DEFAULT_HTML_EXT);

        let file = File::create(n_f)?;
        self.hbs.render_to_write(template_name, data, file)?;

        Ok(())
    }
}
