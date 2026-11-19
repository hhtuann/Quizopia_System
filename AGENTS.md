# Quizopia System — Agent Instructions

All project agent instructions live in THIS file. `CLAUDE.md` just references it.

> **Optional tooling — read this first:** the section below (inside the
> `gitnexus:start/end` markers) is auto-managed by the GitNexus code-intelligence
> tool. GitNexus is an OPTIONAL local aid, not a build prerequisite. On a fresh
> clone without `.gitnexus/`, the MCP tools, or `.claude/skills/`, simply fall
> back to standard practice: IDE go-to-definition/find-usages and text search
> replace the graph queries, and you skip the GitNexus-specific rules. The
> project's own quality bar (tests, review, docs) always applies regardless.

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **Quizopia-System** (11188 symbols, 31791 relationships, 573 execution flows).

> Index stale? Run `node .gitnexus/run.cjs analyze --index-only` from the project root — it auto-selects an available runner. No `.gitnexus/run.cjs` yet? Bootstrap with `npx`, `bunx`, or `pnpm dlx` — e.g. `bunx gitnexus@latest analyze` (npm 11 npx crash; #1939).

## Always Do (when GitNexus is installed)

- **Run impact before editing.** Use `impact({target: "symbolName", direction: "upstream"})` or `node .gitnexus/run.cjs impact "symbolName" --direction upstream --repo .`; report callers, processes, and risk. Graph analysis beats plain grep when available.
- **Analyze graph changes before committing.** Use `detect_changes({scope: "all"})` (MCP) or `node .gitnexus/run.cjs detect-changes --scope all --repo .` (CLI fallback). `partial: true` or `truncated: true` is not a clean check — a zero means unseen, not unaffected; re-run it. For regression review: `detect_changes({scope: "compare", base_ref: "main"})` or `node .gitnexus/run.cjs detect-changes --scope compare --base-ref "main" --repo .`.
- Warn on HIGH/CRITICAL `risk` pre-edit; never use `riskSharedAxes` to waive a HIGH/CRITICAL `risk` warning. Compare File/symbol: MCP File omits axes; Graph-RAG expands File.
- **Treat `risk: UNKNOWN` as unresolved, not as low.** An empty caller set is not evidence the symbol is unused — it can also mean the callers are not resolvable by the index (plain-object property access, dynamic dispatch, cross-language calls). `impact` pairs `UNKNOWN` with a `riskNote` saying so. Confirm with a text search before treating the symbol as safe to change or delete; do not proceed on the strength of a zero.
- Use `query({search_query: "concept"})` for concepts/flows, `context({name: "symbolName"})` for a named symbol, or `impact` for blast radius, on read-only callers, dependencies, imports, or execution flow. Graph first; text search only for empty/`UNKNOWN`/literals.
- For security review, `explain({target: "fileOrSymbol"})` lists taint findings (source→sink flows; needs `analyze --pdg`).

## Never Do (when GitNexus is installed)

- Do not edit a function, class, or method before MCP/CLI impact analysis — IDE references + text search are the fallback, not a substitute, when the tools ARE present.
- Never ignore HIGH or CRITICAL risk warnings from impact analysis, and never read `UNKNOWN` as an all-clear — it means the walk could not answer, which is the one verdict that requires confirming by other means.
- Never rename symbols with find-and-replace — use `rename` which understands the call graph.
- Do not commit before MCP/CLI graph change analysis.

## Resources

| Resource | Use for |
| --- | --- |
| `gitnexus://repo/Quizopia-System/context` | Codebase overview, check index freshness |
| `gitnexus://repo/Quizopia-System/clusters` | All functional areas |
| `gitnexus://repo/Quizopia-System/processes` | All execution flows |
| `gitnexus://repo/Quizopia-System/process/{name}` | Step-by-step execution trace |

## CLI skills (only when `.claude/skills/` is present locally)

| Task | Read this skill file |
| --- | --- |
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
