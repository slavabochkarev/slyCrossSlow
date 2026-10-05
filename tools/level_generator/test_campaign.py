"""Validate the review-only campaign and its dictionary snapshot."""

from __future__ import annotations

from collections import Counter
import json
from pathlib import Path

from crossword import Placement, validate
from campaign_generator import CHAPTERS
from dictionary import DATA, ROOT
from experiment_physical import flagged_words


def main():
    output = ROOT / "campaign_output"
    levels = json.loads((output / "campaign_levels.json").read_text(encoding="utf-8"))
    dictionary = set((DATA / "words.txt").read_text(encoding="utf-8").splitlines())
    runtime = set((ROOT.parents[1] / "assets/game_words.txt").read_text(encoding="utf-8").splitlines())
    excluded = set((DATA / "exclude.txt").read_text(encoding="utf-8").splitlines())
    assert dictionary == runtime, "Runtime dictionary differs from generator game dictionary"
    assert not (dictionary & excluded), "Excluded word remains in game dictionary"
    assert len(levels) == 150
    assert [level["id"] for level in levels] == list(range(1, 151))
    assert len({"".join(sorted(level["letters"])) for level in levels}) == 150
    flagged = flagged_words()
    for title, start, end, lengths, min_words, max_words in CHAPTERS:
        chapter = levels[start - 1:end]
        assert len(chapter) == end - start + 1
        assert all(level["chapter"] == title for level in chapter)
        assert all(len(level["letters"]) in lengths for level in chapter)
        assert all(min_words <= len(level["words"]) <= max_words for level in chapter)
    for level in levels:
        words = [word["text"] for word in level["words"]]
        assert not (set(words) & excluded), f"Excluded word at level {level['id']}"
        assert not (set(words) & flagged), f"Questionable word at level {level['id']}"
        assert all(word in dictionary for word in words)
        assert all(not (Counter(word) - Counter(level["letters"])) for word in words)
        placed = [Placement(word["text"], word["row"], word["col"], word["direction"])
                  for word in level["words"]]
        assert validate(placed), f"Invalid geometry at level {level['id']}"
    html = (output / "preview.html").read_text(encoding="utf-8")
    assert html.count("<article class='card'>") == 150
    assert (output / "campaign_report.txt").exists()
    print("Validated 150 levels, chapters, unique letter sets, excluded/questionable words, multiplicity, geometry, runtime dictionary and preview.")


if __name__ == "__main__":
    main()
