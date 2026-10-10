use std::io;

#[derive(Debug)]
pub enum BlogError {
    Io(io::Error),
    Tera(tera::Error),
    Yaml(serde_yaml::Error),
    MissingHeader(String),
}

impl std::fmt::Display for BlogError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            BlogError::Io(e) => write!(f, "IO error: {}", e),
            BlogError::Tera(e) => write!(f, "Template error: {}", e),
            BlogError::Yaml(e) => write!(f, "YAML error: {}", e),
            BlogError::MissingHeader(path) => write!(f, "Missing header in: {}", path),
        }
    }
}

impl std::error::Error for BlogError {}

impl From<io::Error> for BlogError {
    fn from(e: io::Error) -> Self {
        BlogError::Io(e)
    }
}

impl From<tera::Error> for BlogError {
    fn from(e: tera::Error) -> Self {
        BlogError::Tera(e)
    }
}

impl From<serde_yaml::Error> for BlogError {
    fn from(e: serde_yaml::Error) -> Self {
        BlogError::Yaml(e)
    }
}
