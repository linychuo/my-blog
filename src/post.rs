use std::fs::{self, File};
use std::path::PathBuf;

use handlebars::Handlebars;
use serde_derive::{Deserialize, Serialize};
use serde_json::json;

#[derive(Debug, Serialize, Deserialize)]
pub struct Post {
    title: String,
    created_date_time: String,
    parent_dir: String,
    dir: String,
    file_name: String,
    contents: String,
}

#[derive(Debug, Default, Serialize, Deserialize)]
pub struct Header {
    title: String,
    date_time: String,
}

impl Post {
    pub fn new(parent_dir: &str, header: Header, file_name: &str, contents: String) -> Post {
        let mut split = header.date_time.split_whitespace();
        let date = split.next().unwrap();
        let v: Vec<&str> = date.split('-').collect();

        Post {
            title: header.title,
            created_date_time: header.date_time.to_string(),
            parent_dir: parent_dir.to_string(),
            dir: format!("/{}/{}/{}", v[0], v[1], v[2]),
            file_name: file_name.to_string(),
            contents,
        }
    }

    pub fn render(&self, hbs: &Handlebars) {
        let full_path = format!("{}{}", self.parent_dir, self.dir);
        fs::create_dir_all(&full_path).expect("create sub folder failed!");

        let mut new_f = PathBuf::from(full_path).join(&self.file_name);
        new_f.set_extension("html");
        let file = File::create(new_f).expect("create file failed!");
        hbs.render_to_write(
            "post",
            &json!({
                "parent": "layout",
                "post": self}),
            file,
        )
        .expect("render post failed!");
    }
}
