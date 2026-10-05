import json
from pathlib import Path
import unittest

from crossword import Placement, validate
from experiment_6_7 import geometry_score
from generator import possible_words
from scoring import metrics


OUTPUT = Path(__file__).resolve().parent / "experiment_6_7_output"


class ExperimentTests(unittest.TestCase):
    def test_saved_search_and_preview(self):
        selected = json.loads((OUTPUT / "candidates.json").read_text(encoding="utf-8"))["candidates"]
        archive = json.loads((OUTPUT / "per_count_best.json").read_text(encoding="utf-8"))["letter_sets"]
        self.assertEqual([sum(len(c["letters"]) == n for c in selected) for n in (6, 7)], [10, 10])
        self.assertEqual(len({c["letters"] for c in selected}), 20)
        by_letters = {item["letters"]: item for item in archive}
        for item in archive:
            for count, variant in item["best_by_word_count"].items():
                placements = [Placement(**p) for p in variant["placements"]]
                self.assertEqual(len(placements), int(count))
                self.assertTrue(6 <= len(placements) <= 11)
                self.assertTrue(validate(placements))
                self.assertEqual(geometry_score(placements), variant["geometry_score"])
        for item in selected:
            placed = [Placement(**p) for p in item["placements"]]
            self.assertTrue(validate(placed))
            self.assertEqual(item["geometry_score"], geometry_score(placed))
            self.assertEqual(item["metrics"], metrics(placed))
            self.assertEqual(possible_words(item["letters"], item["used"]), item["used"])
            variants = by_letters[item["letters"]]["best_by_word_count"]
            self.assertEqual(item["geometry_score"], max(v["geometry_score"] for v in variants.values()))
            self.assertEqual(item["available_counts"], sorted(map(int, variants)))
        html = (OUTPUT / "preview.html").read_text(encoding="utf-8")
        self.assertEqual(html.count("<article class='card'"), 20)


if __name__ == "__main__":
    unittest.main()
