"""Find playable 8..18-word developer levels with the existing crossword engine."""

from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path
import random

from crossword import Placement, options, validate
from dictionary import ROOT, load_words
from experiment_physical import flagged_words, ranked_sets
from preview import model
from scoring import metrics

COUNTS = range(8, 19)
MAX_SHORT_WORDS = 6
DEFAULT_OUTPUT = ROOT / "play_lab_output"


def score(placed: list[Placement]) -> float:
    m = metrics(placed)
    long_quality = sum(14 if len(p.word) == 5 else 12 if len(p.word) >= 6 else 8 if len(p.word) == 4 else 0 for p in placed)
    return round(
        100 * len(placed) + long_quality + 6 * m["crossings"]
        + 18 * m["density"] - 1.2 * m["width"] * m["height"]
        - 5 * m["dangling"] - 5 * abs(m["width"] - m["height"])
        + 1.5 * m["square"], 3,
    )


def search_set(possible: list[str], seeds: list[str], rng: random.Random, attempts: int):
    best: dict[int, list[Placement]] = {}
    for attempt in range(attempts):
        seed = seeds[attempt % len(seeds)]
        placed = [Placement(seed, 0, 0, rng.choice(("across", "down")))]
        unused = [word for word in possible if word != seed]
        rng.shuffle(unused)
        while len(placed) < 18:
            choices = []
            seven = sum(len(p.word) == 7 for p in placed)
            short = sum(len(p.word) == 3 for p in placed)
            for word in unused:
                if len(word) == 7 and seven >= 2:
                    continue
                if len(word) == 3 and short >= MAX_SHORT_WORDS:
                    continue
                for candidate in options(placed, word, 32):
                    trial = placed + [candidate]
                    choices.append((score(trial), rng.random(), candidate))
            if not choices:
                break
            choices.sort(key=lambda item: (item[0], item[1]), reverse=True)
            chosen = rng.choice(choices[:min(10, len(choices))])[2]
            placed.append(chosen)
            unused.remove(chosen.word)
            count = len(placed)
            if count in COUNTS and validate(placed):
                current = best.get(count)
                if current is None or score(placed) > score(current):
                    best[count] = placed.copy()
    return best


def cell_size(width: int, height: int, phone: str) -> float:
    available = {"360x800": (336, 358), "390x844": (366, 402), "412x915": (388, 473)}[phone]
    return round(min(74, (available[0] - 24) / width, (available[1] - 24) / height), 3)


def record(letters: str, possible: list[str], placed: list[Placement]) -> dict:
    item = model({"letters": letters, "seed": placed[0].word, "possible": possible, "placements": placed})
    item["score"] = score(placed)
    item["cell_size"] = {phone: cell_size(item["metrics"]["width"], item["metrics"]["height"], phone)
                         for phone in ("360x800", "390x844", "412x915")}
    item["word_count"] = len(placed)
    return item


def write(records: list[dict], selected: dict[int, dict], config: dict, output: Path):
    output.mkdir(parents=True, exist_ok=True)
    archive = []
    for item in records:
        archive.append({"letters": item["letters"], "possible": item["possible"],
                        "best_by_word_count": {str(n): record(item["letters"], item["possible"], placed)
                                               for n, placed in sorted(item["per_count"].items())}})
    (output / "search_archive.json").write_text(json.dumps({"config": config, "letter_sets": archive}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    chosen = [selected[n] for n in COUNTS if n in selected]
    (output / "candidates.json").write_text(json.dumps({"config": config, "candidates": chosen}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    lines = []
    for item in chosen:
        m = item["metrics"]
        lines.append(f"{item['word_count']} WORDS\nLETTER SET: {item['letters']}\nSEED: {item['seed']}\nGRID: {m['width']}×{m['height']}\nCELL:\n  360×800 → {item['cell_size']['360x800']:.1f}\n  390×844 → {item['cell_size']['390x844']:.1f}\n  412×915 → {item['cell_size']['412x915']:.1f}\nDENSITY: {m['density']:.3f}\nCROSSINGS: {m['crossings']}\nUSED: {', '.join(item['used'])}\nSCORE: {item['score']:.3f}")
    missing = [n for n in COUNTS if n not in selected]
    if missing:
        lines.append("MISSING COUNTS: " + ", ".join(map(str, missing)))
    (output / "diagnostics.txt").write_text("\n\n".join(lines) + "\n", encoding="utf-8")


def run(args):
    words = [word for word in load_words() if word not in flagged_words()]
    rng = random.Random(args.seed)
    records = []
    best_global: dict[int, dict] = {}
    for size in (6, 7):
        for rank, (_, letters, seeds, possible) in enumerate(ranked_sets(words, size)[:args.set_limit], 1):
            if len(possible) < 8:
                continue
            per_count = search_set(possible, seeds, rng, args.attempts)
            records.append({"letters": letters, "possible": possible, "per_count": per_count})
            for count, placed in per_count.items():
                item = record(letters, possible, placed)
                if count not in best_global or item["score"] > best_global[count]["score"]:
                    best_global[count] = item
            if rank % 5 == 0:
                print(f"{size}-letter sets: {rank}/{args.set_limit}; counts found: {sorted(best_global)}", flush=True)
    config = {"seed": args.seed, "set_limit_per_size": args.set_limit, "attempts_per_set": args.attempts,
              "word_counts": list(COUNTS), "max_short_words": MAX_SHORT_WORDS, "max_seven_letter_words": 2,
              "geometry_limit": "none; options max_span=32 is only a generous finite search bound",
              "lexical_filter": "data/words.txt minus data/questionable_words.txt"}
    write(records, best_global, config, args.output)
    print(f"Saved {len(best_global)}/11 word counts in {args.output}")
    for count in COUNTS:
        if count in best_global:
            item = best_global[count]
            print(f"{count}: {item['letters']} {item['metrics']['width']}x{item['metrics']['height']} score={item['score']}")
        else:
            print(f"{count}: NO CANDIDATE")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seed", type=int, default=20261005)
    parser.add_argument("--set-limit", type=int, default=30)
    parser.add_argument("--attempts", type=int, default=16)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    if min(args.set_limit, args.attempts) < 1:
        parser.error("limits must be positive")
    run(args)


if __name__ == "__main__":
    main()
