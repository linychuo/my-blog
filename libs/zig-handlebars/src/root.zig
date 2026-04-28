//! Zig Handlebars - A simple Handlebars-style template engine for Zig
//!
//! Features:
//! - Simple `{{variable}}` syntax for variable replacement
//! - `{{{html}}}` syntax for unescaped HTML
//! - `{{> partial}}` syntax for including partial templates
//! - HTML escaping by default for security
//! - Template inheritance support
//! - No external dependencies

// Export public API
const std = @import("std");
pub const TemplateEngine = @import("engine.zig").TemplateEngine;
pub const Context = @import("context.zig").Context;
pub const TemplateError = @import("error.zig").TemplateError;
pub const PartialsManager = @import("partials.zig").PartialsManager;
pub const Loader = @import("loader.zig").Loader;
pub const Renderer = @import("renderer.zig").Renderer;
pub const escapeHtml = @import("html_escape.zig").escapeHtml;
pub const parseTag = @import("tag_parser.zig").parseTag;
pub const ParsedTag = @import("tag_parser.zig").ParsedTag;

test {
    std.testing.refAllDecls(@import("error.zig"));
    std.testing.refAllDecls(@import("html_escape.zig"));
    std.testing.refAllDecls(@import("context.zig"));
    std.testing.refAllDecls(@import("partials.zig"));
    std.testing.refAllDecls(@import("loader.zig"));
    std.testing.refAllDecls(@import("tag_parser.zig"));
    std.testing.refAllDecls(@import("renderer.zig"));
    std.testing.refAllDecls(@import("engine.zig"));
}
