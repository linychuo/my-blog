use std::fs;
use std::path::Path;

use anyhow::{Context, Result};

pub fn copy_static_files(src_dir: &Path, dest_dir: &Path) -> Result<()> {
    for entry in fs::read_dir(src_dir)
        .with_context(|| format!("failed to read {}", src_dir.display()))?
    {
        let entry = entry?;
        let entry_path = entry.path();
        let entry_path_name = match entry_path.file_name() {
            Some(name) => name,
            None => continue,
        };
        if entry_path.is_dir() {
            let new_dir = dest_dir.join(entry_path_name);
            copy_static_files(&entry_path, &new_dir)?;
        } else {
            if !dest_dir.exists() {
                fs::create_dir_all(dest_dir)
                    .with_context(|| format!("failed to create {}", dest_dir.display()))?;
            }
            let new_file_path = dest_dir.join(entry_path_name);
            fs::copy(&entry_path, &new_file_path)
                .with_context(|| format!("failed to copy {} to {}", entry_path.display(), new_file_path.display()))?;
        }
    }
    Ok(())
}
