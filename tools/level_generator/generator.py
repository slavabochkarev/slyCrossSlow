"""Offline level-generator POC. Run from any directory with Python 3.10+."""

from __future__ import annotations

import argparse
from collections import Counter
from pathlib import Path
import random

from crossword import search
from dictionary import build, load_words, ROOT
from preview import write
from scoring import score


def possible_words(letters: str, words: list[str]) -> list[str]:
    available = Counter(letters)
    return [word for word in words if len(word) <= len(letters) and not (Counter(word) - available)]


def letter_sets(words: list[str]):
    groups: dict[str, list[str]] = {}
    for word in words:
        if len(word) in (6, 7):
            groups.setdefault("".join(sorted(word)), []).append(word)
    return groups


def run(seed: int, set_limit: int, attempts: int, max_words: int, max_span: int, top: int, output: Path):
    build()
    words = load_words()
    groups = letter_sets(words)
    candidates = []
    for letters, seeds in groups.items():
        potential = possible_words(letters, words)
        by_length = Counter(map(len, potential))
        if len(potential) < 8 or sum(by_length[n] for n in (4, 5, 6)) < 3:
            continue
        potential_rank = len(potential) + 1.5 * by_length[4] + by_length[5] + 0.5 * by_length[6]
        candidates.append((potential_rank, letters, sorted(seeds)[0], potential))
    candidates.sort(key=lambda x: (-x[0], x[1]))
    selected = candidates[:set_limit]
    rng = random.Random(seed)
    found = []
    for _, letters, seed_word, possible in selected:
        placed = search(possible, seed_word, rng, attempts, max_words, max_span, score)
        if placed and len(placed) >= 6:
            found.append({"letters": letters, "seed": seed_word, "possible": possible, "placements": placed})
    found.sort(key=lambda x: (-score(x["placements"]), x["letters"]))
    config = {"seed": seed, "set_limit": set_limit, "attempts": attempts, "max_words": max_words, "max_span": max_span, "top": top, "letter_sets_total": len(groups), "letter_sets_eligible": len(candidates), "letter_sets_searched": len(selected)}
    write(found[:top], output, config)
    print(f"Searched {len(selected)} of {len(groups)} unique letter sets; valid candidates: {len(found)}")
    for i, c in enumerate(found[:top], 1):
        print(f"{i:02d} {c['letters']} {c['seed']} possible={len(c['possible'])} used={len(c['placements'])} score={score(c['placements']):.3f}")


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--seed", type=int, default=42)
    p.add_argument("--set-limit", type=int, default=32)
    p.add_argument("--attempts", type=int, default=12)
    p.add_argument("--max-words", type=int, default=11)
    p.add_argument("--max-span", type=int, default=11)
    p.add_argument("--top", type=int, default=10)
    p.add_argument("--output", type=Path, default=ROOT / "output")
    args = p.parse_args()
    if min(args.set_limit, args.attempts, args.max_words, args.max_span, args.top) < 1:
        p.error("limits must be positive")
    run(args.seed, args.set_limit, args.attempts, args.max_words, args.max_span, args.top, args.output)


if __name__ == "__main__":
    main()
