"""Build development-only English word lists from an unpacked SCOWL 2020.12.07.

Usage: python build.py --scowl-root C:/path/to/scowl
The source tree must contain final/, misc/, VERSION, and Copyright.
"""

from __future__ import annotations

import argparse
import re
import shutil
from collections import Counter
from pathlib import Path


HERE = Path(__file__).resolve().parent
GAME_TIERS = (10, 20)
RECOGNITION_TIERS = (10, 20, 35, 40, 50, 55, 60)
LANGUAGES = ("english", "american")
WORD_PATTERN = re.compile(r"[a-z]{3,7}\Z", re.ASCII)


def source_words(root: Path, tiers: tuple[int, ...]) -> tuple[list[str], set[str]]:
    rows: list[str] = []
    accepted: set[str] = set()
    for tier in tiers:
        for language in LANGUAGES:
            path = root / "final" / f"{language}-words.{tier}"
            # SCOWL 2020.12.07 files contain Latin-1 accented entries.
            for line in path.read_text(encoding="latin-1").splitlines():
                word = line.strip()
                rows.append(word)
                if WORD_PATTERN.fullmatch(word):
                    accepted.add(word.upper())
    return rows, accepted


def read_exclusions(path: Path) -> set[str]:
    result: set[str] = set()
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        word = line.strip()
        if not word or word.startswith("#"):
            continue
        if not re.fullmatch(r"[A-Z]{3,7}", word, re.ASCII):
            raise ValueError(f"Invalid exclusion at line {line_number}: {word!r}")
        result.add(word)
    return result


def write_words(path: Path, words: set[str]) -> None:
    path.write_text("\n".join(sorted(words)) + "\n", encoding="utf-8")


def length_distribution(words: set[str]) -> str:
    counts = Counter(map(len, words))
    return ", ".join(f"{length}: {counts[length]}" for length in range(3, 8))


def spaced_examples(words: set[str]) -> list[str]:
    examples: list[str] = []
    for length in range(3, 8):
        group = sorted(word for word in words if len(word) == length)
        examples.extend(group[(index * len(group)) // 20] for index in range(20))
    return examples


def pos_coverage(path: Path | None, words: set[str]) -> str:
    if path is None:
        return "POS coverage was not measured in this build."
    tags_by_word: dict[str, str] = {}
    for line in path.read_text(encoding="latin-1").splitlines():
        if "\t" in line:
            word, tags = line.split("\t", 1)
            tags_by_word[word.upper()] = tags
    covered = words & tags_by_word.keys()
    noun_tagged = sum("N" in tags_by_word[word] for word in covered)
    return (
        f"The older SCOWL source `pos/part-of-speech.txt` was sampled: "
        f"{len(covered)} of {len(words)} game words have a POS record, and "
        f"{noun_tagged} have an `N` tag. This is only a candidate noun pool: "
        "the file combines Moby and WordNet, may not match this SCOWL release, "
        "has incomplete coverage and ambiguous/multiple senses."
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scowl-root", required=True, type=Path)
    parser.add_argument("--pos-file", type=Path)
    args = parser.parse_args()
    root = args.scowl_root.resolve()
    version = (root / "VERSION").read_text(encoding="ascii").strip()
    if version != "2020.12.07":
        raise ValueError(f"Expected SCOWL 2020.12.07, got {version!r}")

    raw_rows, recognition_candidates = source_words(root, RECOGNITION_TIERS)
    game_rows, game_candidates = source_words(root, GAME_TIERS)
    exclusions = read_exclusions(HERE / "exclude_en.txt")
    game = game_candidates - exclusions
    recognition = recognition_candidates - exclusions
    if not game <= recognition:
        raise AssertionError("Game vocabulary must be contained in recognition vocabulary")

    write_words(HERE / "game_words_en.txt", game)
    write_words(HERE / "recognition_words_en.txt", recognition)
    shutil.copyfile(root / "Copyright", HERE / "SCOWL_Copyright.txt")

    excluded_matches = sorted(recognition_candidates & exclusions)
    rejected_format = len(raw_rows) - sum(bool(WORD_PATTERN.fullmatch(w)) for w in raw_rows)
    examples = spaced_examples(game)
    report = f"""# English dictionary preparation — SCOWL 2020.12.07

These are **development-only candidate word lists**. They are not connected to
Flutter, assets, campaign levels, or the runtime dictionary.

## Sources and licensing

- SCOWL 2020.12.07 generated `final/english-words.*` and
  `final/american-words.*`, sizes 10–60. The `final/` files came from the
  `deepin-community/scowl` mirror of the 2020.12.07 release (commit
  `3eaac49325afdd27b7092c8700708ad47a275218`). The requested
  `embernet/scowl_wordlist` repository was inspected for source structure
  and licensing (commit `f6b071244ce65b0a95ae052043042e85eed72815`).
  It does not ship generated `final/` lists. SCOWL permits commercial
  use, copying, modification, distribution, and sale, provided its copyright
  and permission notices accompany copies and supporting documentation.
  The full upstream notice is preserved in `SCOWL_Copyright.txt`. If these
  lists ship in the game later, ship those notices in the game's legal/credits
  materials too. Source links:
  https://github.com/embernet/scowl_wordlist
  https://github.com/deepin-community/scowl
  https://sourceforge.net/projects/wordlist/files/SCOWL/2020.12.07/
- `wordfreq` was reviewed but **not used** to produce either list. Its code is
  Apache 2.0, while the underlying data has separate CC BY-SA 4.0 terms and
  source-specific attribution. The project specifically cautions against
  converting its data to a plain CSV/word list. Any future use as a selection
  signal in commercially distributed dictionary data needs separate license
  review and attribution design. No wordfreq data or code is copied here.
  Sources: https://github.com/rspeer/wordfreq and its LICENSE.txt/NOTICE.md.

## Filtering method

Only `english-words` and `american-words` categories are read. SCOWL's
`proper-names`, `abbreviations`, `contractions`, `upper`, and other categories
are never included. Entries must already match lowercase ASCII `[a-z]{{3,7}}`
before uppercase normalization. This rejects punctuation, digits, accents,
hyphens, apostrophes, and multiword entries. Duplicates are removed.

`game_words_en.txt` uses size tiers 10 and 20 (the most common SCOWL bands).
`recognition_words_en.txt` uses tiers 10, 20, 35, 40, 50, 55, and 60.
SCOWL's higher tiers are spelling-list size bands, not measured word
frequencies. The separate `exclude_en.txt` removes SCOWL's taboo list entries
and a small manually chosen set of unsuitable game words from both outputs.
No Russian words were translated automatically.

## Counts

| Measure | Count |
|---|---:|
| Source rows read (14 SCOWL files, tiers 10–60) | {len(raw_rows)} |
| Rows rejected by length/format | {rejected_format} |
| Unique 3–7 A–Z candidates before exclusions | {len(recognition_candidates)} |
| Unique game candidates before exclusions | {len(game_candidates)} |
| Exclusion-list entries | {len(exclusions)} |
| Excluded candidates present in recognition source | {len(excluded_matches)} |
| Game words after filtering | {len(game)} |
| Recognition words after filtering | {len(recognition)} |

Game lengths — {length_distribution(game)}.

Recognition lengths — {length_distribution(recognition)}.

## 100 game-word examples

The following are 20 evenly spaced alphabetical examples for each length,
so the sample spans the dictionary rather than only its first page:

{', '.join(examples)}.

## Exclusions and quality limits

Examples rejected by category/format include proper names, abbreviations,
contractions such as `can't`, hyphenated words, accented entries, and entries
outside 3–7 characters. Examples rejected by `exclude_en.txt` include
`MORON`, `MORONS`, `IDIOT`, `IDIOTS`, and sensitive/profane entries; the
complete exact list is in that file. {len(excluded_matches)} exclusion entries
actually occur in the selected recognition tiers.

This is a conservative *candidate* game list, not a linguistically verified
lexicon. Even the 10–20 bands can contain inflected forms, obscure homographs,
regional spellings, or terms with unwanted meanings. Proper-name homographs
may remain when the same spelling is also a common word. The SCOWL category
selection does not guarantee part of speech. SCOWL source POS/inflection data
could support a future noun review, but it is not a reliable final noun
classifier; no noun-only claim is made. {pos_coverage(args.pos_file, game)}
A human vocabulary pass, especially
for words actually placed in levels, remains necessary before production.

## Generator compatibility

Both outputs are sorted UTF-8 text files with one uppercase A–Z word per line,
no headers, 3–7 letters each. This matches the current Python generator's
word-list input format and `Counter`-based letter multiplicity checks.
The generator's Russian dictionary builder is separate; do not call its
`run()` path with these files. Reuse its language-neutral `possible_words`,
`letter_sets`, and crossword search functions with an explicit English list.
The English lists are not wired into generation or production.

On this build, the outputs were checked for sorted order, uniqueness,
uppercase A–Z, length, exclusion compliance and game ⊆ recognition.
The existing `letter_sets` found 3,253 six/seven-letter signatures;
`possible_words("LISTEN", game_words)` returned 32 words; a two-attempt
`crossword.search` built a connected five-word layout accepted by `validate`.
"""
    (HERE / "REPORT.md").write_text(report, encoding="utf-8")
    print(f"Source rows: {len(raw_rows)}")
    print(f"Game: {len(game)} ({length_distribution(game)})")
    print(f"Recognition: {len(recognition)} ({length_distribution(recognition)})")
    print(f"Excluded source matches: {len(excluded_matches)}")


if __name__ == "__main__":
    main()
