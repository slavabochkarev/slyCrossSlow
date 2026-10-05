"""Replace only five affected candidate levels using the existing crossword search."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import random
import shutil
import tempfile

from campaign_generator import (DEFAULT_OUTPUT, chapter_for, layout_score,
                                lexical_groups, save, search_set)
from crossword import Placement, validate
from dictionary import DATA, load_words
from experiment_physical import flagged_words
from generator import possible_words
from scoring import metrics

AFFECTED = (22, 46, 94, 120, 142)
EXPECTED_OLD = {22: "ДРОВА", 46: "ДРОВА", 94: "СУТКИ",
                120: "ОСТАНКИ", 142: "СУТКИ"}
SEARCH_SEED = 20261004
EXCLUDED = frozenset((DATA / "exclude.txt").read_text(encoding="utf-8").splitlines())


def candidate(letters: str, possible: list[str], placed: list[Placement]) -> dict:
    m = metrics(placed)
    count = len(placed)
    long_words = sum(len(p.word) >= 5 for p in placed)
    average_length = sum(len(p.word) for p in placed) / count
    difficulty = round(
        8 * (len(letters) - 3) + 2.5 * (count - 2)
        + 1.4 * long_words + .6 * len(possible)
        + .24 * m["width"] * m["height"]
        + .7 * m["crossings"] + .6 * average_length
        - 5 * m["density"], 2,
    )
    return {"letters": letters, "seed": placed[0].word, "possible": possible,
            "placements": placed, "count": count, "metrics": m,
            "difficulty": difficulty, "layout_score": layout_score(placed),
            "long_words": long_words, "occupied": m["occupied"]}


def existing_item(level: dict) -> dict:
    placed = [Placement(w["text"], w["row"], w["col"], w["direction"])
              for w in level["words"]]
    item = candidate("".join(level["letters"]), [], placed)
    item.update({"id": level["id"], "chapter": level["chapter"],
                 "seed": level["seed"], "difficulty": level["difficulty_score"],
                 # Preserve the approved metadata for all untouched levels.
                 "possible": [""] * level["word_potential"]})
    return item


def get_pool(words: list[str], original: list[dict]) -> list[dict]:
    used_sets = {"".join(sorted(level["letters"])) for level in original
                 if level["id"] not in AFFECTED}
    groups = lexical_groups(words)
    rng = random.Random(SEARCH_SEED)
    pool = []
    for length, limit, min_potential in ((5, 45, 6), (6, 55, 9), (7, 95, 10)):
        searched = 0
        for _, letters, seeds, possible in groups[length]:
            if letters in used_sets or len(possible) < min_potential:
                continue
            variants = search_set(possible, seeds, rng, 16, length)
            for count, placed in variants.items():
                if (length == 5 and 5 <= count <= 7
                    or length == 6 and 8 <= count <= 10
                    or length == 7 and 9 <= count <= 14):
                    pool.append(candidate(letters, possible, placed))
            searched += 1
            if searched >= limit:
                break
        print(f"searched {searched} unused {length}-letter sets; {len(pool)} variants", flush=True)
    return pool


def rank(item: dict, old: dict, number: int, selected: dict[int, dict], original: list[dict]) -> float:
    old_metrics = metrics([Placement(w["text"], w["row"], w["col"], w["direction"])
                           for w in old["words"]])
    m = item["metrics"]
    words = {p.word for p in item["placements"]}
    neighbor_penalty = 0.0
    for other_id in range(max(1, number - 8), min(150, number + 8) + 1):
        if other_id == number:
            continue
        other = selected.get(other_id)
        other_words = ({p.word for p in other["placements"]} if other
                       else {w["text"] for w in original[other_id - 1]["words"]})
        distance = abs(number - other_id)
        for word in words & other_words:
            neighbor_penalty += (100 if distance <= 3 else 7 * (9 - distance)) * (1.5 if len(word) <= 4 else 1)
    return (100 * abs(item["count"] - len(old["words"]))
            + 2.2 * abs(item["difficulty"] - old["difficulty_score"])
            + 4 * (abs(m["width"] - old_metrics["width"])
                   + abs(m["height"] - old_metrics["height"]))
            + .3 * abs(m["width"] * m["height"]
                       - old_metrics["width"] * old_metrics["height"])
            + neighbor_penalty - .03 * item["layout_score"])


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="write the five replacements")
    args = parser.parse_args()
    output = DEFAULT_OUTPUT
    original = json.loads((output / "campaign_levels.json").read_text(encoding="utf-8"))
    assert len(original) == 150 and [x["id"] for x in original] == list(range(1, 151))
    for number, banned in EXPECTED_OLD.items():
        assert banned in {w["text"] for w in original[number - 1]["words"]}, (
            f"Level {number} no longer contains {banned}; this one-time repair has already run")
    words = [w for w in load_words() if w not in flagged_words()]
    assert not EXCLUDED.intersection(words)
    pool = get_pool(words, original)
    selected: dict[int, dict] = {}
    used_sets = {"".join(sorted(level["letters"])) for level in original
                 if level["id"] not in AFFECTED}
    for number in AFFECTED:
        old = original[number - 1]
        desired_length = len(old["letters"])
        choices = [item for item in pool if len(item["letters"]) == desired_length
                   and item["letters"] not in used_sets
                   and not {p.word for p in item["placements"]} & EXCLUDED]
        exact = [item for item in choices if item["count"] == len(old["words"])]
        if exact:
            choices = exact
        choices.sort(key=lambda item: (rank(item, old, number, selected, original), item["letters"]))
        if not choices:
            raise RuntimeError(f"No replacement for level {number}")
        print(f"\nLEVEL {number}: old {''.join(old['letters'])}, {len(old['words'])} words, difficulty {old['difficulty_score']}")
        for item in choices[:5]:
            m = item["metrics"]
            print(f"  {item['letters']} | {item['count']} words | {m['width']}×{m['height']} "
                  f"| difficulty {item['difficulty']} | rank {rank(item, old, number, selected, original):.1f} "
                  f"| {', '.join(p.word for p in item['placements'])}")
        chosen = choices[0]
        selected[number] = chosen
        used_sets.add(chosen["letters"])
    if not args.apply:
        print("\nDry run only; use --apply after review.")
        return

    items = [existing_item(level) for level in original]
    for number, chosen in selected.items():
        items[number - 1] = {**chosen, "id": number,
                             "chapter": chapter_for(number)[0], "recent_penalty": 0.0}
    by_word: dict[str, int] = {}
    for item in items:
        penalty = 0.0
        for placement in item["placements"]:
            distance = item["id"] - by_word.get(placement.word, -1000)
            if distance <= 3:
                penalty += 130 if len(placement.word) <= 4 else 70
            elif distance <= 8:
                penalty += (9 - distance) * (8 if len(placement.word) <= 4 else 4)
            by_word[placement.word] = item["id"]
        item["recent_penalty"] = round(penalty, 2)
    for item in items:
        assert validate(item["placements"])
        assert not {p.word for p in item["placements"]} & EXCLUDED
    with tempfile.TemporaryDirectory() as temporary:
        staging = Path(temporary)
        save(items, [], [], SEARCH_SEED, 16, staging)
        updated = json.loads((staging / "campaign_levels.json").read_text(encoding="utf-8"))
        for before, after in zip(original, updated):
            if before["id"] not in AFFECTED:
                assert before == after, f"Untouched level {before['id']} changed"
        assert len({"".join(sorted(x["letters"])) for x in updated}) == 150
        assert not EXCLUDED & {w["text"] for x in updated for w in x["words"]}
        report = staging / "campaign_report.txt"
        text = report.read_text(encoding="utf-8")
        text = text.replace("SEED: 20261004; ATTEMPTS PER SET: 16; POOL VARIANTS: 0",
                            "BASE CAMPAIGN SEED: 20261006; TARGETED REPAIR SEED: 20261004; "
                            "ONLY LEVELS 22, 46, 94, 120, 142 REPLACED")
        text = text.replace("QUESTIONABLE USED: 0", "QUESTIONABLE USED: 0\nEXCLUDED USED: 0\nPLURALIA TANTUM USED: 0")
        stale = [(level["id"], level["word_potential"],
                  len(possible_words("".join(level["letters"]), words)))
                 for level in updated if level["id"] not in AFFECTED
                 and level["word_potential"] != len(possible_words("".join(level["letters"]), words))]
        if stale:
            note = "; ".join(f"level {number}: stored {stored}, current {current}"
                             for number, stored, current in stale)
            text = text.replace("\nLEVEL DETAILS\n", "\nUNCHANGED WORD POTENTIAL METADATA: " + note
                                + " (level records preserved exactly)\n\nLEVEL DETAILS\n")
        report.write_text(text, encoding="utf-8")
        for name in ("campaign_levels.json", "campaign_report.txt", "preview.html"):
            shutil.copyfile(staging / name, output / name)
    print("Verified all other 145 level records unchanged.")


if __name__ == "__main__":
    main()
