<!-- SEMBLE_START -->
## Semble Code Search

A `semble` MCP server is available with two tools:
- `mcp__semble__search` - search the codebase with a natural-language or code query.
- `mcp__semble__find_related` - find code similar to a known location.

Use `mcp__semble__search` to find where something is implemented instead of using Grep or Glob to discover files. After semble returns the file and line, navigate there directly and read that file. Do not grep for the same content again.

Pass `content="docs"` to the MCP search tool for documentation and prose, `content="config"` for config files, or `content="all"` for everything. On the CLI, use `--content docs`, `--content config`, or `--content all` instead.

For CLI fallback or sub-agents without MCP access, use:

```bash
semble search "authentication flow" ./my-project --max-snippet-lines 10
semble search "deployment guide" ./my-project --content docs
semble search "database host port" ./my-project --content config
semble find-related src/auth.py 42 ./my-project
semble search "save model to disk" ./my-project --top-k 10
```

The index is built on first run and cached automatically. No standalone Semble installation is managed. For every CLI example above, replace `semble` with `uvx --from 'semble[mcp]==0.5.6' semble`, matching the direct pinned MCP command. Mise supplies uv/uvx; launch OpenCode from a mise-enabled shell. Do not run `semble install` or install another copy.

### Workflow

1. Call `mcp__semble__search` with a query describing what the code does or its name. The tool returns results with 10 lines of context each (function/class signature plus first body lines, enough to confirm the location).
2. Navigate directly to the top result's file and line. Read only the function or class at that location.
3. Make the edit. Do not re-search or grep for the same content.
4. Set the MCP search tool's `content` field to `docs`, `config`, or `all` when searching beyond code.
5. Optionally use `mcp__semble__find_related` with a promising result's `file_path` and `line` to discover related implementations.
6. Use Grep only when you need every occurrence of a literal string across the whole repo (for example, all callers of a renamed function).
<!-- SEMBLE_END -->
