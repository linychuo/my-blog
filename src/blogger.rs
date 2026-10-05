use std::ffi::OsStr;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};

use crate::post::Post;
use crate::{DEFAULT_HTML_EXT, DEFAULT_POST_EXT};
use comrak::ComrakOptions;
use serde_derive::Serialize;
use serde_json::{json, Value};
use std::collections::HashMap;
use tera::{Context, Tera};

#[derive(Debug)]
pub struct Blogger<'a> {
    dest_dir: PathBuf,
    posts_dir: PathBuf,
    tera: Tera,
    comrak_options: ComrakOptions<'a>,
}

#[derive(Debug, Serialize)]
pub struct TagPost {
    pub title: String,
    pub url: String,
    pub created_date_time: String,
}

type Tags = HashMap<String, Vec<TagPost>>;

fn has_extension(path: &Path, ext: &str) -> bool {
    path.extension().and_then(OsStr::to_str) == Some(ext)
}

fn contains(vec: &[String], s: &str) -> bool {
    vec.iter().any(|item| item == s)
}

impl Blogger<'_> {
    pub fn new(dest_dir: &Path, posts_dir: &Path, template_dir: &Path) -> Blogger<'static> {
        let mut tera = Tera::default();
        tera.autoescape_on(vec![]);

        // Load all templates manually to ensure correct order
        let mut entries: Vec<_> = std::fs::read_dir(template_dir)
            .expect("failed to read template dir")
            .filter_map(|e| e.ok())
            .map(|e| e.path())
            .filter(|p| p.extension().and_then(|s| s.to_str()) == Some("tera"))
            .collect();
        entries.sort();

        // Load layout first
        for entry in &entries {
            if entry.file_stem().and_then(|s| s.to_str()) == Some("layout") {
                let content = std::fs::read_to_string(entry).expect("failed to read layout");
                tera.add_raw_template("layout", &content).expect("failed to add layout");
                break;
            }
        }

        // Load other templates
        for entry in entries {
            let name = entry.file_stem().and_then(|s| s.to_str()).unwrap_or("");
            if name != "layout" && !name.is_empty() {
                let content = std::fs::read_to_string(&entry).expect("failed to read template");
                tera.add_raw_template(name, &content).expect("failed to add template");
            }
        }
        fs::create_dir_all(dest_dir).expect("create dest dir failed");

        let mut comrak_options = ComrakOptions::default();
        comrak_options.extension.table = true;

        Blogger {
            dest_dir: dest_dir.to_path_buf(),
            posts_dir: posts_dir.to_path_buf(),
            tera,
            comrak_options,
        }
    }

    pub fn render_posts(&self, exclude: &[String]) -> Result<(), tera::Error> {
        let (mut all_posts, tags) = self.load_posts(exclude)?;
        all_posts.sort_by_key(|post| post.header.date_time.to_string());
        all_posts.reverse();
        self.render_template("index", &json!({"posts": all_posts}))?;

        for item in all_posts {
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

    pub fn render(&self, file_path: &str) -> Result<(), tera::Error> {
        let new_path = Path::new(file_path);
        let dest_file_name = new_path.file_stem().and_then(OsStr::to_str).unwrap_or("");
        let mut path = self.posts_dir.join(file_path);
        path.set_extension(DEFAULT_POST_EXT);
        let contents = self.parse_content(&path)?;
        self.render_template(
            dest_file_name,
            &json!({"contents": contents}),
        )?;

        Ok(())
    }

    pub fn copy_static_files(src_dir: PathBuf, dest_dir: PathBuf) -> io::Result<()> {
        for entry in fs::read_dir(src_dir)? {
            let entry = entry?;
            let entry_path = entry.path();
            let entry_path_name = match entry_path.file_name() {
                Some(name) => name,
                None => continue,
            };
            if entry_path.is_dir() {
                let new_dir = dest_dir.join(entry_path_name);
                Blogger::copy_static_files(entry_path, new_dir)?;
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
                _ => continue,
            };

            if contains(excludes, entry_name) {
                continue;
            }

            if let Some(post) = Post::of(entry_path.as_path(), entry_name, &self.comrak_options) {
                for tag in &post.tags {
                    tags.entry(tag.to_string()).or_default().push(TagPost {
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

    fn parse_content(&self, entry_path: &Path) -> io::Result<String> {
        let contents = fs::read_to_string(entry_path)?;
        Ok(comrak::markdown_to_html(&contents, &self.comrak_options))
    }

    fn render_template(&self, template_name: &str, data: &Value) -> Result<(), tera::Error> {
        let mut dest_file = self.dest_dir.join(template_name);
        if template_name == "tags" {
            dest_file = self.dest_dir.join(format!(
                "tags/{}",
                data["tag"].as_str().unwrap_or("")
            ));
        }
        dest_file.set_extension(DEFAULT_HTML_EXT);

        let context = Context::from_serialize(data)?;
        let rendered = self.tera.render(template_name, &context)?;
        fs::write(dest_file, rendered)?;

        Ok(())
    }
}
