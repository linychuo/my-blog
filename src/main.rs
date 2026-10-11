use std::path::Path;

use anyhow::Result;

use my_blog::blogger::Blogger;
use my_blog::static_files::copy_static_files;

const POSTS_DIR: &str = "./posts";
const STATIC_DIR: &str = "./static";
const TEMPLATES_DIR: &str = "./templates";
const BUILD_DIR: &str = "./build";

fn main() -> Result<()> {
    let blog = Blogger::new(Path::new(BUILD_DIR), Path::new(POSTS_DIR), Path::new(TEMPLATES_DIR))?;
    blog.render_posts(&["about".to_string()])?;

    blog.render("about")?;
    copy_static_files(Path::new(STATIC_DIR), Path::new(BUILD_DIR))?;

    Ok(())
}
