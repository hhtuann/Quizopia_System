#!/usr/bin/env python3
"""Build the Quizopia System documentation site.

Usage: build-docs-site.py <repo_root> <output_dir>

The site is intentionally tiny and deterministic:
  1. Everything under <repo_root>/website is copied verbatim (the curated hub).
  2. An all-docs.html index is generated from the checkout, listing every
     Markdown document found across the parent repository and both submodules,
     each linked to its canonical GitHub blob rendering at the EXACT commit
     integrated by the parent (submodules are read at their pinned SHAs).

Only file NAMES and git metadata are read — document CONTENT is never parsed
or copied, so a stray non-UTF-8 byte in a child document (the historical
Jekyll failure) can never break this build. The workflow validates encodings
separately and reports them precisely.

Exit status: 0 on success; 1 on usage or git errors (reported to stderr).
"""

from __future__ import annotations

import html
import shutil
import subprocess
import sys
import urllib.parse
from pathlib import Path


def run_git(cwd: str, *args: str) -> str:
    # -c core.quotePath=false keeps non-ASCII filenames literal (git would
    # otherwise emit quoted "\346..." forms that corrupt paths and links).
    result = subprocess.run(
        ["git", "-c", "core.quotePath=false", *args],
        cwd=cwd, capture_output=True, text=True, check=False
    )
    if result.returncode != 0:
        sys.stderr.write(f"git {' '.join(args)} in {cwd}: {result.stderr.strip()}\n")
        sys.exit(1)
    return result.stdout.strip()


def github_blob_base(remote_url: str, commit: str) -> str:
    """Normalize any supported remote URL to an https blob base for a commit."""
    url = remote_url.strip().rstrip("/")
    if url.startswith("git@"):
        # git@github.com:owner/repo.git -> github.com/owner/repo
        url = url.split("@", 1)[1].replace(":", "/")
    if url.endswith(".git"):
        url = url[: -len(".git")]
    if url.startswith("http://"):
        url = "https://" + url[len("http://") :]
    if not url.startswith("https://"):
        url = "https://" + url
    return f"{url}/blob/{commit}"


def submodule_paths(repo_root: Path) -> list[str]:
    """Submodule paths declared in .gitmodules (nothing hardcoded)."""
    listing = run_git(str(repo_root), "config", "-f", ".gitmodules", "--get-regexp", r"^submodule\..*\.path$")
    return [line.split(" ", 1)[1] for line in listing.splitlines() if " " in line]


def collect_documents(repo_root: Path) -> list[dict]:
    """Every tracked Markdown file in the parent and each submodule.

    Returns [{repo, path (repo-relative), url, title}], sorted by repo then
    path. Untracked/ignored files are excluded (git ls-files), matching what
    CI actually integrates. A submodule declared in .gitmodules but not
    checked out produces a stderr warning (its section is skipped) instead
    of a silently incomplete index.
    """
    docs: list[dict] = []

    repos: list[tuple[str, Path]] = [("Quizopia_System", repo_root)]
    for name in submodule_paths(repo_root):
        child = repo_root / name
        if (child / ".git").exists():
            repos.append((name, child))
        else:
            sys.stderr.write(
                f"warning: submodule '{name}' is declared but not checked out — "
                f"its documents are excluded from the index\n"
            )

    for repo_name, repo_path in repos:
        commit = run_git(str(repo_path), "rev-parse", "HEAD")
        remote = run_git(str(repo_path), "remote", "get-url", "origin")
        blob_base = github_blob_base(remote, commit)
        listing = run_git(str(repo_path), "ls-files", "*.md", "*.markdown")
        for rel in sorted(listing.splitlines()):
            if not rel:
                continue
            docs.append(
                {
                    "repo": repo_name,
                    "path": rel,
                    # Percent-encode per segment so spaces/#/? in names stay one link.
                    "url": f"{blob_base}/{urllib.parse.quote(rel, safe='/')}",
                    # Pretty title: last path segment, extension stripped.
                    "title": Path(rel).stem,
                }
            )
    return docs


PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Quizopia System — full document index</title>
<style>
  body {{ margin: 0; font-family: "Segoe UI", system-ui, sans-serif; line-height: 1.6;
         color: #0f172a; background: #fafafa; }}
  main {{ max-width: 60rem; margin: 0 auto; padding: 2.5rem 1.25rem 4rem; }}
  h1 {{ font-size: 1.6rem; letter-spacing: -0.02em; }}
  p.note {{ color: #64748b; }}
  h2 {{ font-size: 1rem; text-transform: uppercase; letter-spacing: .08em; color: #64748b;
        margin: 2rem 0 .5rem; }}
  ul {{ list-style: none; padding: 0; margin: 0; }}
  li {{ padding: .3rem 0 .3rem 0; }}
  a {{ color: #0052ff; text-decoration: none; }}
  a:hover {{ text-decoration: underline; }}
  .path {{ color: #64748b; font-family: ui-monospace, monospace; font-size: .8rem; }}
  footer {{ color: #64748b; font-size: .8rem; margin-top: 3rem; border-top: 1px solid #e2e8f0; padding-top: 1rem; }}
  @media (prefers-color-scheme: dark) {{
    body {{ background: #0b1120; color: #e2e8f0; }}
    h2 {{ color: #94a3b8; }} a {{ color: #4d7cff; }}
    footer {{ border-color: #1e293b; }}
  }}
</style>
</head>
<body>
<main>
  <h1>Full document index</h1>
  <p class="note">{count} Markdown documents across {repos} — linked to their canonical GitHub
  renderings at the exact integrated commits. Generated automatically on every Pages deployment;
  never edited by hand.</p>
  {sections}
  <footer>Generated by <code>scripts/build-docs-site.py</code> from the checked-out tree
  (parent + submodules at their pinned commits).</footer>
</main>
</body>
</html>
"""

SECTION = """<h2>{repo} <span class="path">{extra}</span></h2>
<ul>{items}</ul>"""

ITEM = """<li><a href="{url}">{title}</a> <span class="path">{path}</span></li>"""


def render_page(docs: list[dict]) -> str:
    repo_order = []
    by_repo: dict[str, list[dict]] = {}
    for doc in docs:
        if doc["repo"] not in by_repo:
            repo_order.append(doc["repo"])
            by_repo[doc["repo"]] = []
        by_repo[doc["repo"]].append(doc)

    sections = []
    for repo in repo_order:
        items = "\n".join(
            ITEM.format(
                url=html.escape(d["url"]),
                title=html.escape(d["title"]),
                path=html.escape(d["path"]),
            )
            for d in by_repo[repo]
        )
        sections.append(
            SECTION.format(
                repo=html.escape(repo),
                extra=f"{len(by_repo[repo])} documents",
                items=items,
            )
        )
    return PAGE.format(
        count=len(docs),
        repos=len(repo_order),
        sections="\n".join(sections),
    )


def main() -> int:
    if len(sys.argv) != 3:
        sys.stderr.write(__doc__)
        return 1
    repo_root = Path(sys.argv[1]).resolve()
    out_dir = Path(sys.argv[2]).resolve()
    if not (repo_root / ".git").exists():
        sys.stderr.write(f"{repo_root} is not a git repository\n")
        return 1

    docs = collect_documents(repo_root)
    if not docs:
        sys.stderr.write("no Markdown documents found — refusing to publish an empty index\n")
        return 1

    hub = repo_root / "website"
    if not hub.is_dir():
        sys.stderr.write(f"{hub} does not exist — nothing to publish\n")
        return 1
    # 1. Curated hub copied verbatim — INCLUDING subdirectories (assets etc.).
    shutil.copytree(hub, out_dir, dirs_exist_ok=True)
    # 2. Generated full index (overwrite any stale copy from website/).
    (out_dir / "all-docs.html").write_text(render_page(docs), encoding="utf-8")

    print(f"site: {out_dir}")
    print(f"documents indexed: {len(docs)}")
    for repo in dict.fromkeys(d["repo"] for d in docs):
        print(f"  {repo}: {sum(1 for d in docs if d['repo'] == repo)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
