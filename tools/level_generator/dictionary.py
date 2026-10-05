"""Build the offline POC word list; never edits either upstream source."""

from __future__ import annotations

from collections import Counter
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parent
DATA = ROOT / "data"
RUSSIAN = re.compile(r"^[А-ЯЁ]+$")


def normalize(text: str) -> str | None:
    """Trim outer whitespace, uppercase, fold Ё to Е, reject all other separators."""
    word = text.strip().upper().replace("Ё", "Е")
    return word if RUSSIAN.fullmatch(word) and 3 <= len(word) <= 7 else None


def source_words() -> tuple[list[str], list[str], list[str], list[str]]:
    answers = (DATA / "pyatibukv_answers.txt").read_text(encoding="utf-8").splitlines()
    accepted = (DATA / "pyatibukv_accepted.txt").read_text(encoding="utf-8").splitlines()
    harrix = (DATA / "harrix_russian_nouns.txt").read_text(encoding="utf-8-sig").splitlines()
    common = (DATA / "common_russian_nouns.txt").read_text(encoding="utf-8-sig").splitlines()
    return answers, accepted, harrix, common


def _clean(lines: list[str], stats: Counter, length: int | None = None) -> set[str]:
    result: set[str] = set()
    for line in lines:
        original = line.strip().upper().replace("Ё", "Е")
        if not RUSSIAN.fullmatch(original):
            stats["invalid_characters"] += 1
        elif not 3 <= len(original) <= 7 or (length is not None and len(original) != length):
            stats["wrong_length"] += 1
        elif original in result:
            stats["duplicates_removed"] += 1
        else:
            result.add(original)
    return result


def build() -> dict:
    answers, accepted, harrix, common = source_words()
    stats: Counter = Counter()
    raw_five = _clean(accepted, stats, 5)
    # A curated list of answers is a higher-quality subset of the five-letter source.
    game_five = _clean(answers, Counter(), 5) & raw_five
    raw_other = {w for w in _clean(harrix, stats) if len(w) != 5}
    common_other = {w for w in _clean(common, Counter()) if len(w) != 5}
    raw = raw_other | raw_five
    game = (raw_other & common_other) | game_five

    excludes = _clean((DATA / "exclude.txt").read_text(encoding="utf-8").splitlines(), Counter())
    includes = _clean((DATA / "include.txt").read_text(encoding="utf-8").splitlines(), Counter())
    # Includes can add custom words; all additions are visible in their own file.
    game = (game | includes) - excludes
    stats["other_rejected"] = len(raw - game)

    (DATA / "raw_words.txt").write_text("\n".join(sorted(raw)) + "\n", encoding="utf-8")
    game_text = "\n".join(sorted(game)) + "\n"
    (DATA / "words.txt").write_text(game_text, encoding="utf-8")
    (ROOT.parents[1] / "assets/game_words.txt").write_text(game_text, encoding="utf-8")
    report = {
        "source_lines": {"pyatibukv_answers": len(answers), "pyatibukv_accepted": len(accepted), "harrix": len(harrix), "common": len(common)},
        "pyatibukv_five_raw": len(raw_five),
        "pyatibukv_five_game": len(game_five),
        "raw_by_length": {str(n): sum(len(w) == n for w in raw) for n in range(3, 8)},
        "game_by_length": {str(n): sum(len(w) == n for w in game) for n in range(3, 8)},
        "raw_total": len(raw), "game_total": len(game),
        "cleaning": dict(sorted(stats.items())),
        "common_not_in_harrix": len(common_other - raw_other),
    }
    (DATA / "dictionary_stats.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return report


def load_words() -> list[str]:
    excluded = _clean((DATA / "exclude.txt").read_text(encoding="utf-8").splitlines(), Counter())
    return [word for word in (DATA / "words.txt").read_text(encoding="utf-8").splitlines()
            if word not in excluded]


if __name__ == "__main__":
    print(json.dumps(build(), ensure_ascii=False, indent=2))
