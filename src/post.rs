use std::fs;
use std::path::Path;

use comrak::ComrakOptions;
use serde_derive::{Deserialize, Serialize};
use serde_json::json;
use tera::{Context, Tera};

use crate::DEFAULT_HTML_EXT;
use crate::error::BlogError;

const YAML_DELIMITER: &str = "---";

#[derive(Debug, Serialize)]
pub struct Post {
    pub dir: String,
    pub file_name: String,
    pub header: Header,
    pub contents: String,
    pub tags: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Header {
    pub title: String,
    pub date_time: String,
    tags: String,
}

pub fn build_comrak_options() -> ComrakOptions<'static> {
    let mut options = ComrakOptions::default();
    options.extension.table = true;
    options
}

fn build_dir(date_time: &str) -> Result<String, BlogError> {
    let date = date_time
        .split_whitespace()
        .next()
        .ok_or_else(|| BlogError::MissingHeader(date_time.to_string()))?;
    let v: Vec<&str> = date.split('-').collect();
    if v.len() >= 3 {
        Ok(format!("{}/{}/{}", v[0], v[1], v[2]))
    } else {
        Err(BlogError::MissingHeader(date_time.to_string()))
    }
}

fn build_tags(tags: &str) -> Vec<String> {
    tags.split_whitespace().map(|x| x.to_string()).collect()
}

fn parse_content(file_path: &Path, comrak_options: &ComrakOptions) -> Result<(Header, String), BlogError> {
    let contents = fs::read_to_string(file_path)?;
    if !contents.starts_with(YAML_DELIMITER) {
        return Err(BlogError::MissingHeader(file_path.display().to_string()));
    }

    let after_first = &contents[YAML_DELIMITER.len()..];
    let end_of_yaml = after_first
        .find(YAML_DELIMITER)
        .ok_or_else(|| BlogError::MissingHeader(file_path.display().to_string()))?;
    let header_str = &contents[YAML_DELIMITER.len()..YAML_DELIMITER.len() + end_of_yaml];
    let header = serde_yaml::from_str(header_str)?;

    let md_start = YAML_DELIMITER.len() + end_of_yaml + YAML_DELIMITER.len();
    let md = contents[md_start..].trim_start();
    let html = comrak::markdown_to_html(md, comrak_options);
    Ok((header, html))
}

impl Post {
    pub fn of(file_path: &Path, file_name: &str, comrak_options: &ComrakOptions) -> Result<Post, BlogError> {
        let (header, contents) = parse_content(file_path, comrak_options)?;
        let dir = build_dir(&header.date_time)?;
        Ok(Post {
            dir,
            tags: build_tags(&header.tags),
            file_name: file_name.to_string(),
            header,
            contents,
        })
    }

    pub fn render(&self, parent_dir: &Path, tera: &Tera) -> Result<(), BlogError> {
        let html = self.to_html(tera)?;
        let file_dir = parent_dir.join(&self.dir);
        fs::create_dir_all(&file_dir)?;
        let mut f = file_dir.join(&self.file_name);
        f.set_extension(DEFAULT_HTML_EXT);
        fs::write(f, html)?;
        Ok(())
    }

    fn to_html(&self, tera: &Tera) -> Result<String, BlogError> {
        let context = Context::from_serialize(json!({ "post": self }))?;
        Ok(tera.render("post", &context)?)
    }
}
