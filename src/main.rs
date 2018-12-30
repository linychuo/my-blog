use std::path::PathBuf;

mod blogger;
mod post;

fn main() {
    let blog = blogger::Blogger::new(
        PathBuf::from("./build"),
        PathBuf::from("./_posts"),
        PathBuf::from("./templates"),
    );

    blog.render_posts(vec!["about.markdown"])
        .expect("render all posts failed!");
    blog.render("./_posts/about.markdown")
        .expect("render about file failed!");

    blog.copy_static_files(PathBuf::from("static/imgs"), PathBuf::from("build/imgs"));
    blog.copy_static_files(
        PathBuf::from("static/styles"),
        PathBuf::from("build/styles"),
    );
}
