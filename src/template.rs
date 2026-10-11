use std::fs;
use std::path::Path;

use anyhow::Result;
use anyhow::Context as _;
use serde_json::Value;
use tera::Tera;

use crate::DEFAULT_HTML_EXT;

pub fn load_templates(template_dir: &Path) -> Result<Tera> {
    let mut tera = Tera::default();
    tera.autoescape_on(vec![]);

    let mut templates = read_template_files(template_dir)?;
    // Sort: templates without extends first
    templates.sort_by_key(|(_, c)| c.contains("{% extends"));

    for (name, content) in templates {
        tera.add_raw_template(&name, &content)
            .with_context(|| format!("failed to add template '{}'", name))?;
    }

    Ok(tera)
}

fn read_template_files(template_dir: &Path) -> Result<Vec<(String, String)>> {
    let mut result = Vec::new();
    for entry in fs::read_dir(template_dir)
        .with_context(|| format!("failed to read template dir {}", template_dir.display()))?
    {
        let entry = entry?;
        let path = entry.path();
        if path.extension().and_then(|s| s.to_str()) != Some("tera") {
            continue;
        }
        let name = path
            .file_stem()
            .and_then(|s| s.to_str())
            .with_context(|| format!("invalid template file name: {}", path.display()))?
            .to_string();
        let content = fs::read_to_string(&path)
            .with_context(|| format!("failed to read template {}", path.display()))?;
        result.push((name, content));
    }
    Ok(result)
}

pub fn render_template(
    tera: &Tera,
    dest_dir: &Path,
    template_name: &str,
    data: &Value,
) -> Result<()> {
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

    let context = tera::Context::from_serialize(data)
        .with_context(|| format!("failed to build context for template '{}'", template_name))?;
    let rendered = tera.render(template_name, &context)
        .with_context(|| format!("failed to render template '{}'", template_name))?;
    fs::write(&dest_file, rendered)
        .with_context(|| format!("failed to write {}", dest_file.display()))?;

    Ok(())
}
