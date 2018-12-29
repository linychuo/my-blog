use std::io;
use std::path::PathBuf;

mod blogger;
mod post;

fn main() -> io::Result<()> {
    let blog = blogger::Blogger::new(
        PathBuf::from("./build"),
        PathBuf::from("./_posts"),
        PathBuf::from("./templates"),
    );

    blog.render_posts(vec!["about.markdown"])?;
    blog.render("./_posts/about.markdown");

    blog.copy_static_files(PathBuf::from("static/imgs"), PathBuf::from("build/imgs"))?;
    blog.copy_static_files(
        PathBuf::from("static/styles"),
        PathBuf::from("build/styles"),
    )?;

    Ok(())
}
