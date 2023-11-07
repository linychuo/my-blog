# my personal blog generator

- pure static blog using rust
- please visit site [Yongchao.Li](https://yongchao.li), welcome push a [issue](https://github.com/linychuo/my-blog/issues) if you found any problem, Thanks!


## Overview
This project was built with Rust language, rust has lots of features. no garbage collection(GC), no runtime overhead, and ensures safety, among other features. all content is placed in the 'post' directory, they were written by markdown. and the template engine uses Handlerbars for Rust. any person could fork this project and build their own blog site.

## Code structure
- src
    - [main.rs](./src/main.rs)
    <br/>main entry point of the program, it parses params from command line and generates HTML files, copy static files, this comnand line must be contained five constants
        - posts_dir: path name for original content of each post
        - static_files_dir: path name for static files
        - templates_dir: path name for template files
        - build_dir: path name for final building
        - excludes: excludes file list while program starts generating html files
    - [blogger.rs](./src/blogger.rs)
    <br/>it representes a blogger object, it has a few methods, render all posts, index page and copy static files
    - [post.rs](./src/post.rs)
    <br/>it was represented a article object and behaviors
- posts **contains all the original posts**
- static **includes all static resources, it includes css, js, images**
- templates **kinds of template file**
    - [about.hbs](./templates/about.hbs)
    - [footer.hbs](./templates/footer.hbs)
    - [index.hbs](./templates/index.hbs)
    - [layout.hbs](./templates/layout.hbs)
    - [nav.hbs](./templates/nav.hbs)
    - [post.hbs](./templates/post.hbs)
