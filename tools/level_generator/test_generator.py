import random
import unittest
import json
from pathlib import Path

from crossword import Placement, can_place, search, validate
from dictionary import normalize
from generator import possible_words
from preview import grid
from scoring import metrics, score


class DictionaryTests(unittest.TestCase):
    def test_multiset_and_length(self):
        words = ["КАРТА", "ТАРА", "КАРАТ", "КАРАТА", "АРКА", "РАК"]
        self.assertEqual(possible_words("ААКРТ", words), ["КАРТА", "ТАРА", "КАРАТ", "АРКА", "РАК"])

    def test_normalization(self):
        self.assertEqual(normalize(" ёлка "), "ЕЛКА")
        self.assertIsNone(normalize("А-Б"))
        self.assertIsNone(normalize("КОТ2"))
        self.assertEqual(normalize("ЙОД"), "ЙОД")


class CrosswordTests(unittest.TestCase):
    def test_crossing_and_side_contact(self):
        placed = [Placement("КОТ", 0, 0, "across")]
        self.assertTrue(can_place(placed, Placement("ТОК", 0, 2, "down")))
        self.assertFalse(can_place(placed, Placement("РОТ", 1, 0, "across")))
        self.assertFalse(can_place(placed, Placement("КОТ", 0, 0, "down")))
        self.assertTrue(validate(placed + [Placement("ТОК", 0, 2, "down")]))

    def test_seed_and_geometry_are_reproducible(self):
        words = ["КОТ", "ТОК", "РОК", "КРОТ", "РОТ", "КОРА", "РАК"]
        a = search(words, "КРОТ", random.Random(42), 3, 5, 8, score)
        b = search(words, "КРОТ", random.Random(42), 3, 5, 8, score)
        self.assertEqual(a, b)
        self.assertTrue(validate(a))
        m = metrics(a)
        self.assertGreater(m["crossings"], 0)
        self.assertLessEqual(max(m["width"], m["height"]), 8)


class GeneratedOutputTests(unittest.TestCase):
    def test_candidates_are_valid(self):
        path = Path(__file__).resolve().parent / "output" / "candidates.json"
        if not path.exists():
            self.skipTest("run generator.py first")
        data = json.loads(path.read_text(encoding="utf-8"))
        self.assertEqual(len(data["candidates"]), 10)
        for candidate in data["candidates"]:
            placements = [Placement(**p) for p in candidate["placements"]]
            self.assertEqual(min(p.row for p in placements), 0)
            self.assertEqual(min(p.col for p in placements), 0)
            self.assertTrue(validate(placements))
            self.assertEqual([p.word for p in placements], candidate["used"])
            self.assertTrue(set(candidate["used"]) <= set(candidate["possible"]))
            self.assertEqual(possible_words("".join(candidate["letters"]), candidate["possible"]), candidate["possible"])
            self.assertEqual([[letter for letter, _ in row] for row in grid(placements)], candidate["grid"])
            self.assertEqual(score(placements), candidate["score"])


if __name__ == "__main__":
    unittest.main()
