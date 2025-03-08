use std::fs::{self, File};
use std::path::Path;

use comrak::ComrakOptions;
use handlebars::{Handlebars, RenderError};
use serde_derive::{Deserialize, Serialize};
use serde_json::json;

use crate::DEFAULT_HTML_EXT;

#[derive(Debug, Serialize)]
pub struct Post {
    pub dir: String,
    pub file_name: String,
    pub header: Header,
    contents: String,
    pub tags: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Header {
    pub title: String,
    pub date_time: String,
    tags: String,
}

type ParseResult<'a, T> = std::result::Result<T, ParseContentError<'a>>;

#[derive(Debug)]
struct ParseContentError<'a> {
    file_path: &'a Path,
}

fn build_dir(date_time: &str) -> String {
    let date = date_time.split_whitespace().next().unwrap();
    let v: Vec<&str> = date.split('-').collect();
    format!("{}/{}/{}", v[0], v[1], v[2])
}

fn build_tags(tags: &str) -> Vec<String> {
    return tags.split_whitespace().map(|x| x.to_string()).collect();
}

fn parse_content<'a>(
    file_path: &'a Path,
    comrak_options: &ComrakOptions,
) -> ParseResult<'a, (Header, String)> {
    let contents = fs::read_to_string(file_path).unwrap();
    if contents.starts_with("---") {
        let end_of_yaml = contents[4..].find("---").unwrap() + 4;
        let header = serde_yaml::from_str(&contents[..end_of_yaml]).unwrap();
        let contents = comrak::markdown_to_html(&contents[end_of_yaml + 5..], &comrak_options);
        Ok((header, contents))
    } else {
        Err(ParseContentError { file_path })
    }
}

impl Post {
    pub fn of(file_path: &Path, file_name: &str, comrak_options: &ComrakOptions) -> Option<Post> {
        let result = parse_content(file_path, comrak_options);
        match result {
            Ok((header, contents)) => {
                return Some(Post {
                    dir: build_dir(&header.date_time),
                    tags: build_tags(&header.tags),
                    file_name: file_name.to_string(),
                    header,
                    contents,
                });
            }
            Err(e) => {
                eprintln!("Error parsing content for: {}", e.file_path.display());
                return None;
            }
        }
    }

    pub fn render(&self, parent_dir: &Path, hbs: &Handlebars) -> Result<(), RenderError> {
        let file_dir = parent_dir.join(&self.dir);
        fs::create_dir_all(&file_dir).unwrap();

        let mut f = file_dir.join(&self.file_name);
        f.set_extension(DEFAULT_HTML_EXT);
        let file = File::create(f).unwrap();
        hbs.render_to_write(
            "post",
            &json!({
                "parent": "layout",
                "post": self}),
            file,
        )?;

        Ok(())
    }
}
