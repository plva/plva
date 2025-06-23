#!/usr/bin/env python3
"""
Generate a markdown table summarising the owner's public repositories.

Columns: repo name → link, primary language, star count, last push (UTC).
"""
from __future__ import annotations

import datetime as dt
import os
import textwrap
from pathlib import Path

import requests

GH_API = "https://api.github.com/graphql"
OWNER   = os.environ["GH_OWNER"]          # e.g. "your-handle"
TOKEN   = os.environ["GH_TOKEN"]          # PAT with `repo:read`

QUERY = """
query($owner:String!) {
  user(login:$owner) {
    repositories(first:100, privacy:PUBLIC, ownerAffiliations:OWNER, isFork:false) {
      nodes {
        name
        description
        stargazerCount
        primaryLanguage { name }
        pushedAt
        url
      }
    }
  }
}
"""

def fetch_repos() -> list[dict]:
    hdrs = {"Authorization": f"Bearer {TOKEN}"}
    resp = requests.post(GH_API, json={"query": QUERY, "variables": {"owner": OWNER}}, headers=hdrs, timeout=15)
    resp.raise_for_status()
    return resp.json()["data"]["user"]["repositories"]["nodes"]

def render_table(repos: list[dict]) -> str:
    lines = ["| Repository | Lang | ★ | Last push |", "|-----------|------|---|-----------|"]
    for r in sorted(repos, key=lambda n: n["pushedAt"], reverse=True):
        pushed = dt.datetime.fromisoformat(r["pushedAt"].rstrip("Z")).strftime("%Y-%m-%d")
        lines.append(f"| [{r['name']}]({r['url']}) | {r['primaryLanguage']['name'] if r['primaryLanguage'] else ''} | {r['stargazerCount']} | {pushed} |")
    return "\n".join(lines)

def main() -> None:
    repos = fetch_repos()
    snippet = render_table(repos)
    readme = Path("README.md").read_text(encoding="utf-8")
    new = readme.split("<!-- AUTO-GENERATED-REPO-OVERVIEW:START -->")[0] + \
          "<!-- AUTO-GENERATED-REPO-OVERVIEW:START -->\n" + \
          snippet + "\n<!-- AUTO-GENERATED-REPO-OVERVIEW:END -->" + \
          readme.split("<!-- AUTO-GENERATED-REPO-OVERVIEW:END -->")[1]
    Path("README.md").write_text(new, encoding="utf-8")

if __name__ == "__main__":
    main()

