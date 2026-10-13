#!/usr/bin/env python3
"""Builds docs/privacy/trackly-privacy-policy.html from the Markdown policy.

The Markdown file is the source; run this after editing it so the HTML copy
that gets uploaded to the website matches:

    python3 tool/build_policy_html.py

Handles only what the policy uses: headings, paragraphs, bullet lists, links
and bold text. Standard library only.
"""
import html
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "docs/privacy/trackly-privacy-policy.md"
TARGET = ROOT / "docs/privacy/trackly-privacy-policy.html"

PAGE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Trackly Privacy Policy</title>
<style>
  body {{ font: 16px/1.6 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; color: #1c2230; background: #faf8f4; margin: 0; }}
  main {{ max-width: 720px; margin: 0 auto; padding: 32px 20px 64px; }}
  h1 {{ font-size: 1.9rem; margin: 0 0 .5rem; }}
  h2 {{ font-size: 1.2rem; margin: 2rem 0 .5rem; }}
  a {{ color: #8a5a00; }}
  @media (prefers-color-scheme: dark) {{ body {{ color: #e8ebf2; background: #0b1220; }} a {{ color: #e0b55a; }} }}
</style>
</head>
<body>
<main>
{body}
</main>
</body>
</html>
"""


def inline(text: str) -> str:
    text = html.escape(text, quote=False)
    text = re.sub(r"\[([^\]]+)\]\((https?://[^)]+)\)", r'<a href="\2">\1</a>', text)
    return re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", text)


def convert(markdown: str) -> str:
    out: list[str] = []
    paragraph: list[str] = []
    in_list = False

    def flush_paragraph() -> None:
        if paragraph:
            out.append("<p>" + "<br>\n".join(inline(line) for line in paragraph) + "</p>")
            paragraph.clear()

    def close_list() -> None:
        nonlocal in_list
        if in_list:
            out.append("</ul>")
            in_list = False

    for line in markdown.split("\n"):
        if line.startswith("# "):
            flush_paragraph(); close_list()
            out.append("<h1>" + inline(line[2:]) + "</h1>")
        elif line.startswith("## "):
            flush_paragraph(); close_list()
            out.append("<h2>" + inline(line[3:]) + "</h2>")
        elif line.startswith("- "):
            flush_paragraph()
            if not in_list:
                out.append("<ul>")
                in_list = True
            out.append("<li>" + inline(line[2:]) + "</li>")
        elif not line.strip():
            flush_paragraph(); close_list()
        else:
            close_list()
            paragraph.append(line)
    flush_paragraph(); close_list()
    return "\n".join(out)


if __name__ == "__main__":
    TARGET.write_text(PAGE.format(body=convert(SOURCE.read_text())))
    print(f"wrote {TARGET.relative_to(ROOT)}")
