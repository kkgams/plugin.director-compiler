#!/usr/bin/env python3
"""Repair routes in a Pages build made from the immutable v0.1.0 docs.

The wiki routes [[Director Compiler]] and [[Director Language]] to slug-named
Markdown files, while v0.1.0 shipped index.md and language.md. Its language
frontmatter also lacks the status required by the pinned wiki application.
This changes only the generated Pages site, never the published source tag.
"""
from pathlib import Path
import sys


def repair(site: Path):
    content = site / 'content'
    config = (content / '_config.md').read_text()
    sidebar = (content / '_sidebar.md').read_text()
    overview = (content / 'index.md').read_bytes()
    language = (content / 'language.md').read_text()

    if 'home: index\n' not in config:
        raise ValueError('Expected v0.1.0 wiki home: index')
    if '[[Director Compiler|Overview]]' not in sidebar or '[[Director Language|Language and implementation status]]' not in sidebar:
        raise ValueError('Expected v0.1.0 sidebar routes')
    if not overview.startswith(b'---\ntitle: Director Compiler\n') or b'\nstatus: in-progress\n' not in overview:
        raise ValueError('Expected v0.1.0 overview frontmatter')
    prefix = '---\ntitle: Director language\n---\n'
    if not language.startswith(prefix):
        raise ValueError('Expected v0.1.0 language frontmatter without status')
    if not language[len(prefix):].startswith('\n# Director language overview\n'):
        raise ValueError('Expected released Director language content')
    aliases = [content / 'director-compiler.md', content / 'director-language.md']
    if any(path.exists() for path in aliases):
        raise FileExistsError('Refusing to replace a generated wiki alias')

    repaired_language = language.replace(prefix, '---\ntitle: Director language\nstatus: in-progress\n---\n', 1)
    (content / 'language.md').write_text(repaired_language)
    aliases[0].write_bytes(overview)
    aliases[1].write_text(repaired_language)
    for path in [content / 'index.md', content / 'language.md', *aliases]:
        if not path.is_file() or not path.stat().st_size:
            raise ValueError(f'Empty wiki route: {path}')


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit('Usage: repair-v0.1.0-wiki.py SITE_DIRECTORY')
    repair(Path(sys.argv[1]))
