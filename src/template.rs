use std::fs;
use std::path::Path;

use serde_json::Value;
use tera::{Context, Tera};

use crate::DEFAULT_HTML_EXT;
use crate::error::BlogError;

pub fn load_templates(template_dir: &Path) -> Result<Tera, BlogError> {
    let mut tera = Tera::default();
    tera.autoescape_on(vec![]);

    let templates = read_template_files(template_dir)?;
    // Sort: templates without extends first
    let mut templates = templates;
    templates.sort_by_key(|(_, c)| c.contains("{% extends"));

    for (name, content) in templates {
        tera.add_raw_template(&name, &content)
            .map_err(|e| BlogError::Tera(e))?;
    }

    Ok(tera)
}

fn read_template_files(template_dir: &Path) -> Result<Vec<(String, String)>, BlogError> {
    let mut result = Vec::new();
    for entry in fs::read_dir(template_dir)? {
        let entry = entry?;
        let path = entry.path();
        if path.extension().and_then(|s| s.to_str()) != Some("tera") {
            continue;
        }
        let name = path
            .file_stem()
            .and_then(|s| s.to_str())
            .ok_or_else(|| BlogError::MissingHeader(path.display().to_string()))?
            .to_string();
        let content = fs::read_to_string(&path)?;
        result.push((name, content));
    }
    Ok(result)
}

pub fn render_template(
    tera: &Tera,
    dest_dir: &Path,
    template_name: &str,
    data: &Value,
) -> Result<(), BlogError> {
    let mut dest_file = dest_dir.join(template_name);
    if template_name == "tags" {
        let tag = data["tag"].as_str().unwrap_or("");
        // 只允许字母，数字，下划线，连字符
        let safe_tag = if tag
            .chars()
            .all(|c| c.is_alphanumeric() || c == '_' || c == '-')
        {
            tag
        } else {
            "unknown"
        };

        dest_file = dest_dir.join(format!("tags/{}", safe_tag));
    }
    dest_file.set_extension(DEFAULT_HTML_EXT);

    let context = Context::from_serialize(data)?;
    let rendered = tera.render(template_name, &context)?;
    fs::write(dest_file, rendered)?;

    Ok(())
}
