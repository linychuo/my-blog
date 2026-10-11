use std::fs;
use std::path::Path;

use comrak::ComrakOptions;
use serde_derive::{Deserialize, Serialize};
use serde_json::json;
use tera::{Context, Tera};

use anyhow::Result;
use anyhow::Context as _;

use crate::DEFAULT_HTML_EXT;

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

fn build_dir(date_time: &str) -> Result<String> {
    let date = date_time
        .split_whitespace()
        .next()
        .context("missing date in header")?;
    let v: Vec<&str> = date.split('-').collect();
    if v.len() >= 3 {
        Ok(format!("{}/{}/{}", v[0], v[1], v[2]))
    } else {
        anyhow::bail!("invalid date format: {}", date_time)
    }
}

fn build_tags(tags: &str) -> Vec<String> {
    tags.split_whitespace().map(|x| x.to_string()).collect()
}

fn parse_content(file_path: &Path, comrak_options: &ComrakOptions) -> Result<(Header, String)> {
    let contents = fs::read_to_string(file_path)
        .with_context(|| format!("failed to read {}", file_path.display()))?;
    if !contents.starts_with(YAML_DELIMITER) {
        anyhow::bail!("missing YAML header in {}", file_path.display());
    }

    let after_first = &contents[YAML_DELIMITER.len()..];
    let end_of_yaml = after_first
        .find(YAML_DELIMITER)
        .context("missing closing YAML delimiter")?;
    let header_str = &contents[YAML_DELIMITER.len()..YAML_DELIMITER.len() + end_of_yaml];
    let header = serde_yaml::from_str(header_str)
        .context("failed to parse YAML header")?;

    let md_start = YAML_DELIMITER.len() + end_of_yaml + YAML_DELIMITER.len();
    let md = contents[md_start..].trim_start();
    let html = comrak::markdown_to_html(md, comrak_options);
    Ok((header, html))
}

impl Post {
    pub fn of(file_path: &Path, file_name: &str, comrak_options: &ComrakOptions) -> Result<Post> {
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

    pub fn render(&self, parent_dir: &Path, tera: &Tera) -> Result<()> {
        let html = self.to_html(tera)?;
        let file_dir = parent_dir.join(&self.dir);
        fs::create_dir_all(&file_dir)
            .with_context(|| format!("failed to create {}", file_dir.display()))?;
        let mut f = file_dir.join(&self.file_name);
        f.set_extension(DEFAULT_HTML_EXT);
        fs::write(f, html)?;
        Ok(())
    }

    fn to_html(&self, tera: &Tera) -> Result<String> {
        let context = Context::from_serialize(json!({ "post": self }))
            .context("failed to build template context")?;
        tera.render("post", &context)
            .with_context(|| format!("failed to render post template for {}", self.file_name))
    }
}
