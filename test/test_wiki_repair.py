#!/usr/bin/env python3
"""A frozen v0.1.0 tag needs generated-site aliases, not a moved release tag."""
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/repair-v0.1.0-wiki.py'


class WikiRepairTests(unittest.TestCase):
    def site(self, root):
        site = Path(root) / 'site'
        content = site / 'content'
        content.mkdir(parents=True)
        (content / '_config.md').write_text('---\nhome: index\n---\n')
        (content / '_sidebar.md').write_text(
            '- [[Director Compiler|Overview]]\n- [[Director Language|Language and implementation status]]\n'
        )
        (content / 'index.md').write_text('---\ntitle: Director Compiler\nstatus: in-progress\n---\n\n# Overview\n')
        (content / 'language.md').write_text('---\ntitle: Director language\n---\n\n# Director language overview\n')
        return site

    def run_repair(self, site):
        return subprocess.run([sys.executable, str(SCRIPT), str(site)], capture_output=True, text=True)

    def test_repair_matches_wiki_routes_and_required_frontmatter(self):
        with tempfile.TemporaryDirectory() as temp:
            site = self.site(temp)
            result = self.run_repair(site)
            self.assertEqual(result.returncode, 0, result.stderr)
            content = site / 'content'
            self.assertEqual((content / 'director-compiler.md').read_bytes(), (content / 'index.md').read_bytes())
            self.assertEqual((content / 'director-language.md').read_bytes(), (content / 'language.md').read_bytes())
            self.assertIn('status: in-progress\n', (content / 'director-language.md').read_text())
            self.assertIn('# Director language overview\n', (content / 'director-language.md').read_text())

    def test_repair_rejects_unexpected_site_instead_of_silently_patching(self):
        with tempfile.TemporaryDirectory() as temp:
            site = self.site(temp)
            (site / 'content/language.md').write_text('---\ntitle: Other\n---\n')
            self.assertNotEqual(self.run_repair(site).returncode, 0)
            self.assertFalse((site / 'content/director-language.md').exists())
        with tempfile.TemporaryDirectory() as temp:
            site = self.site(temp)
            (site / 'content/director-language.md').write_text('stale alias')
            self.assertNotEqual(self.run_repair(site).returncode, 0)


if __name__ == '__main__':
    unittest.main()
