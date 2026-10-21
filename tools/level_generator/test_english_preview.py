"""Validate saved English experiment without running a new search."""

from collections import Counter
from html.parser import HTMLParser
import json
import unittest

from crossword import Placement, validate
from experiment_english import DICTIONARY, OUTPUT, difficulty, read_words
from scoring import metrics


class PreviewMarkup(HTMLParser):
    def __init__(self):
        super().__init__()
        self.sections = self.buttons = self.cells = 0

    def handle_starttag(self, tag, attributes):
        attrs = dict(attributes)
        self.sections += tag == "section"
        self.buttons += tag == "button" and "data-word" in attrs
        self.cells += tag == "div" and "cell" in attrs.get("class", "").split()


class EnglishPreviewTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.levels = json.loads((OUTPUT / "levels_en_preview.json").read_text(encoding="utf-8"))
        cls.game = read_words(DICTIONARY / "game_words_en.txt")
        cls.recognition = read_words(DICTIONARY / "recognition_words_en.txt")
        cls.excluded = read_words(DICTIONARY / "exclude_en.txt")

    def test_dictionary_geometry_and_multiplicity(self):
        self.assertEqual([level["id"] for level in self.levels], list(range(1, 21)))
        signatures = set()
        for level in self.levels:
            signature = "".join(sorted(level["letters"]))
            self.assertNotIn(signature, signatures)
            signatures.add(signature)
            placed = [Placement(w["text"], w["row"], w["col"], w["direction"]) for w in level["words"]]
            self.assertTrue(validate(placed), level["id"])
            self.assertTrue(all(p.row >= 0 and p.col >= 0 for p in placed))
            for word in (p.word for p in placed):
                self.assertRegex(word, r"^[A-Z]{3,7}$")
                self.assertIn(word, self.game)
                self.assertIn(word, self.recognition)
                self.assertNotIn(word, self.excluded)
                self.assertFalse(Counter(word) - Counter(signature))
            for index, p in enumerate(placed):
                for other in placed[index + 1:]:
                    self.assertLessEqual(len(set(p.cells()) & set(other.cells())), 1)
            m = metrics(placed)
            self.assertEqual((m["width"], m["height"], m["crossings"]),
                             tuple(level["preview"][key] for key in ("width", "height", "crossings")))
            self.assertEqual(difficulty(signature, placed), level["preview"]["difficultyScore"])

    def test_gradual_progression(self):
        for index, level in enumerate(self.levels):
            self.assertIn(len(level["letters"]), (3 + index // 5, 4 + index // 5))
        for previous, current in zip(self.levels, self.levels[1:]):
            a, b = previous["preview"], current["preview"]
            self.assertGreaterEqual(b["difficultyScore"], a["difficultyScore"])
            self.assertLessEqual(b["difficultyScore"] - a["difficultyScore"], 14)
            self.assertIn(b["wordCount"] - a["wordCount"], (0, 1))
            for dimension in ("width", "height"):
                self.assertLessEqual(abs(b[dimension] - a[dimension]), 2)

    def test_html_has_every_grid_and_word_control(self):
        parser = PreviewMarkup()
        parser.feed((OUTPUT / "preview_en.html").read_text(encoding="utf-8"))
        self.assertEqual(parser.sections, 20)
        self.assertEqual(parser.buttons, sum(len(level["words"]) for level in self.levels))
        self.assertEqual(parser.cells, sum(level["preview"]["width"] * level["preview"]["height"] for level in self.levels))


if __name__ == "__main__":
    unittest.main()
