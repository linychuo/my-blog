# My personal blog

[![travis](https://travis-ci.org/linychuo/my-blog.svg?branch=master)](https://travis-ci.org/linychuo/my-blog)

- pure static blog using rust
- please visit site [Yongchao.Li](https://yongchao.li), welcome push a [issue](https://github.com/linychuo/my-blog/issues) if you found any problem, Thanks!


## Overview
This project was built rust language, rust has lots of features. no gc, no runtime, safety and so on. all of content was placed directory of posts, they were written by markdown. and template engine using handlerbars for rust.

## Code structure
- src
    - main.rs
        <br/>programming entrance, it parses **[config.toml](./config.toml)** and generate html files, copy static files, this configuration file has five constants
        - posts_dir: path name for original content of each post
        - static_files_dir: path name for static files
        - templates_dir: path name for template files
        - build_dir: path name for final building
        - excludes: excludes file list while program starts to generating html files
    - blogger.rs
    - post.rs
- post **all of the original posts**
- static **all of the resources, it includes css, js, images**
- templates **kinds of template file**
    - about.hbs
    - footer.hbs
    - index.hbs
    - layout.hbs
    - nav.hbs
    - post.hbs
