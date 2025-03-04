use std::fs::{self, File};
use std::path::Path;

use comrak::ComrakOptions;
use handlebars::{Handlebars, RenderError};
use serde_derive::{Deserialize, Serialize};
use serde_json::json;

#[derive(Debug, Default, Serialize, Deserialize)]
pub struct Post {
    pub dir: String,
    pub file_name: String,
    pub header: Header,
    contents: String,
    pub tags: Vec<String>,
}

#[derive(Debug, Default, Serialize, Deserialize)]
pub struct Header {
    pub title: String,
    pub date_time: String,
    tags: String,
}

fn generate_url(date_time: &String) -> String {
    let date = date_time.split_whitespace().next().unwrap();
    let v: Vec<&str> = date.split('-').collect();
    format!("{}/{}/{}", v[0], v[1], v[2])
}

fn build_tags(tags: &String) -> Vec<String> {
    return tags.split_whitespace().map(|x| x.to_string()).collect()
}

fn parse_content(entry_path: &Path, comrak_options: &ComrakOptions) -> (Header, String) {
    let contents = fs::read_to_string(entry_path).unwrap();
    if contents.starts_with("---") {
        let end_of_yaml = contents[4..].find("---").unwrap() + 4;
        let header = serde_yaml::from_str(&contents[..end_of_yaml]).unwrap();
        let contents = comrak::markdown_to_html(&contents[end_of_yaml + 5..], &self.comrak_options);
        (header, contents)
    } else {
        (
            Header::default(),
            comrak::markdown_to_html(&contents, &self.comrak_options),
        )
    }
}

impl Post {
    pub fn new(file_path: &Path, file_name: String, comrak_options: &ComrakOptions) -> Post {
        let (header, contents) = parse_content(file_path, comrak_options);
        return Post {
            dir: generate_url(&header.date_time),
            tags: build_tags(&header.tags),
            file_name,
            header,
            contents,
        }
    }

    pub fn render(&self, parent_dir: &Path, hbs: &Handlebars) -> Result<(), RenderError> {
        let file_dir = parent_dir.join(&self.dir);
        fs::create_dir_all(&file_dir).unwrap();

        let mut f = file_dir.join(&self.file_name);
        f.set_extension("html");
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
