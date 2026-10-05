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
pub enum BlogError {
    Io(io::Error),
    Tera(tera::Error),
    Yaml(serde_yaml::Error),
    MissingHeader(String),
}

impl std::fmt::Display for BlogError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            BlogError::Io(e) => write!(f, "IO error: {}", e),
            BlogError::Tera(e) => write!(f, "Template error: {}", e),
            BlogError::Yaml(e) => write!(f, "YAML error: {}", e),
            BlogError::MissingHeader(path) => write!(f, "Missing header in: {}", path),
        }
    }
}

impl std::error::Error for BlogError {}

impl From<io::Error> for BlogError {
    fn from(e: io::Error) -> Self {
        BlogError::Io(e)
    }
}

impl From<tera::Error> for BlogError {
    fn from(e: tera::Error) -> Self {
        BlogError::Tera(e)
    }
}

impl From<serde_yaml::Error> for BlogError {
    fn from(e: serde_yaml::Error) -> Self {
        BlogError::Yaml(e)
    }
}

#[derive(Debug)]
pub struct Blogger {
    dest_dir: PathBuf,
    posts_dir: PathBuf,
    tera: Tera,
    comrak_options: ComrakOptions<'static>,
}

#[derive(Debug, Serialize)]
pub struct TagPost {
    pub title: String,
    pub url: String,
    pub created_date_time: String,
}

type Tags = HashMap<String, Vec<TagPost>>;

impl Blogger {
    pub fn new(dest_dir: &Path, posts_dir: &Path, template_dir: &Path) -> Blogger {
        fs::create_dir_all(dest_dir).expect("create dest dir failed");

        Blogger {
            dest_dir: dest_dir.to_path_buf(),
            posts_dir: posts_dir.to_path_buf(),
            tera: load_templates(template_dir),
            comrak_options: build_comrak_options(),
        }
    }

    pub fn render_posts(&self, exclude: &[String]) -> Result<(), BlogError> {
        let (mut all_posts, tags) = self.load_posts(exclude)?;
        all_posts.sort_by(|a, b| b.header.date_time.cmp(&a.header.date_time));
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

    pub fn render(&self, file_path: &str) -> Result<(), BlogError> {
        let new_path = Path::new(file_path);
        let dest_file_name = new_path.file_stem().and_then(OsStr::to_str).unwrap_or("");
        let mut path = self.posts_dir.join(file_path);
        path.set_extension(DEFAULT_POST_EXT);
        let contents = self.render_markdown(&path)?;
        self.render_template(dest_file_name, &json!({"contents": contents}))?;

        Ok(())
    }

    fn load_posts(&self, excludes: &[String]) -> Result<(Vec<Post>, Tags), BlogError> {
        let mut all_posts: Vec<Post> = vec![];
        let mut tags: Tags = HashMap::new();
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
                    for tag in &post.tags {
                        tags.entry(tag.to_string()).or_default().push(TagPost {
                            title: post.header.title.to_string(),
                            created_date_time: post.header.date_time.to_string(),
                            url: format!("/{}/{}.{}", post.dir, post.file_name, DEFAULT_HTML_EXT),
                        });
                    }
                    all_posts.push(post);
                }
                Err(e) => {
                    eprintln!("Warning: skipping '{}': {}", entry_path.display(), e);
                }
            }
        }

        Ok((all_posts, tags))
    }

    fn render_markdown(&self, entry_path: &Path) -> Result<String, BlogError> {
        let contents = fs::read_to_string(entry_path)?;
        Ok(comrak::markdown_to_html(&contents, &self.comrak_options))
    }

    fn render_template(&self, template_name: &str, data: &Value) -> Result<(), BlogError> {
        let mut dest_file = self.dest_dir.join(template_name);
        if template_name == "tags" {
            let tag = data["tag"].as_str().unwrap_or("");
            // 只允许字母，数字，下划线，连字符
            let safe_tag = if tag
                .chars()
                .all(|c| c.is_alphanumeric() || c == '_' || c == '-')
            {
                tag
            } else {
                "unknown"
            };

            dest_file = self.dest_dir.join(format!("tags/{}", safe_tag));
        }
        dest_file.set_extension(DEFAULT_HTML_EXT);

        let context = Context::from_serialize(data)?;
        let rendered = self.tera.render(template_name, &context)?;
        fs::write(dest_file, rendered)?;

        Ok(())
    }
}

fn load_templates(template_dir: &Path) -> Tera {
    let mut tera = Tera::default();
    tera.autoescape_on(vec![]);

    let mut templates = read_template_files(template_dir);
    // Sort: templates without extends first
    templates.sort_by_key(|(_, c)| c.contains("{% extends"));

    for (name, content) in templates {
        tera.add_raw_template(&name, &content).expect("failed to add template");
    }

    tera
}

fn read_template_files(template_dir: &Path) -> Vec<(String, String)> {
    std::fs::read_dir(template_dir)
        .expect("failed to read template dir")
        .filter_map(|e| e.ok())
        .map(|e| e.path())
        .filter(|p| p.extension().and_then(|s| s.to_str()) == Some("tera"))
        .filter_map(|p| {
            let name = p.file_stem()?.to_str()?.to_string();
            let content = std::fs::read_to_string(&p).ok()?;
            Some((name, content))
        })
        .collect()
}

fn build_comrak_options() -> ComrakOptions<'static> {
    let mut options = ComrakOptions::default();
    options.extension.table = true;
    options
}

pub fn copy_static_files(src_dir: PathBuf, dest_dir: PathBuf) -> Result<(), BlogError> {
    for entry in fs::read_dir(src_dir)? {
        let entry = entry?;
        let entry_path = entry.path();
        let entry_path_name = match entry_path.file_name() {
            Some(name) => name,
            None => continue,
        };
        if entry_path.is_dir() {
            let new_dir = dest_dir.join(entry_path_name);
            copy_static_files(entry_path, new_dir)?;
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
