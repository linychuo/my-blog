use crate::blogger::Blogger;
use std::path::PathBuf;

mod blogger;
mod post;

fn main() {
    let blog = Blogger::new(
        PathBuf::from("./build"),
        PathBuf::from("./_posts"),
        PathBuf::from("./templates"),
    );

    blog.render_posts(vec!["about.markdown"])
        .expect("render all posts failed!");
    blog.render("about", "./_posts/about.markdown")
        .expect("render about file failed!");

    Blogger::copy_static_files(PathBuf::from("static/imgs"), PathBuf::from("build/imgs"));
    Blogger::copy_static_files(
        PathBuf::from("static/styles"),
        PathBuf::from("build/styles"),
    );
}
