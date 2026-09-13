<!-- SEMBLE_START -->
## Semble Code Search

A `semble` MCP server is available with two tools:
- `semble_search` - search the codebase with a natural-language or code query.
- `semble_find_related` - find code similar to a known location.

Use `semble_search` to find where something is implemented instead of using Grep or Glob to discover files. After semble returns the file and line, navigate there directly and read that file. Do not grep for the same content again.

Pass `content="docs"` to the MCP search tool for documentation and prose, `content="config"` for config files, or `content="all"` for everything.

### Workflow

1. Call `semble_search` with a query describing what the code does or its name. The tool returns results with 10 lines of context each (function/class signature plus first body lines, enough to confirm the location).
2. Navigate directly to the top result's file and line. Read only the function or class at that location.
3. Make the edit. Do not re-search or grep for the same content.
4. Set the MCP search tool's `content` field to `docs`, `config`, or `all` when searching beyond code.
5. Optionally use `semble_find_related` with a promising result's `file_path` and `line` to discover related implementations.
6. Use Grep only when you need every occurrence of a literal string across the whole repo (for example, all callers of a renamed function).
<!-- SEMBLE_END -->
