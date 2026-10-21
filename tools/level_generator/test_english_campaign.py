"""Read-only checks for generated and bundled English campaigns."""
from hashlib import sha256
import json
import unittest

from english_campaign_generator import APPROVED, OUTPUT, DICTIONARY, ROOT, gameplay, read_words, validate_campaign


class EnglishCampaignTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.levels = json.loads((OUTPUT / "campaign_levels_en.json").read_text(encoding="utf-8"))
        cls.approved = json.loads(APPROVED.read_text(encoding="utf-8"))

    def test_every_level_and_progression(self):
        validate_campaign(self.levels, self.approved,
                          read_words(DICTIONARY / "game_words_en.txt"),
                          read_words(DICTIONARY / "recognition_words_en.txt"),
                          read_words(DICTIONARY / "exclude_en.txt"))

    def test_approved_file_and_russian_resources_unchanged(self):
        self.assertEqual(sha256(APPROVED.read_bytes()).hexdigest(),
                         "4bd37cedd983692935ed0a7375e75f437e39ea6551f725aecd3db3546884c093")
        assets = ROOT.parents[1] / "assets"
        for filename, expected in {
            "levels.json": "4a6087c9abbb7eadb6c4868d36e98dbad47fbf7467ca420ab0f3baf21812f9cb",
            "game_words.txt": "d12374aef9739ce01d70b0c63393430915dd52c58c49ad42c8f93e0800fede6d",
        }.items():
            self.assertEqual(sha256((assets / filename).read_bytes()).hexdigest(), expected)
        canonical = lambda data: json.dumps([gameplay(level) for level in data], separators=(",", ":"))
        self.assertEqual(canonical(self.levels[:20]), canonical(self.approved))

    def test_production_is_the_validated_campaign(self):
        production = json.loads((ROOT.parents[1] / "assets" / "levels_en.json").read_text(encoding="utf-8"))
        self.assertEqual(production, self.levels)


if __name__ == "__main__":
    unittest.main()
