//! Error types for zig-handlebars

pub const TemplateError = error{
    /// Template file not found
    TemplateNotFound,
    /// Invalid template syntax
    InvalidSyntax,
    /// Required context key is missing
    ContextKeyMissing,
    /// Failed to read template file
    FileReadFailed,
    /// Failed to write output
    WriteFailed,
    /// Out of memory
    OutOfMemory,
};
