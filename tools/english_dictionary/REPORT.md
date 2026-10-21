# English dictionary preparation — SCOWL 2020.12.07

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
are never included. Entries must already match lowercase ASCII `[a-z]{3,7}`
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
| Source rows read (14 SCOWL files, tiers 10–60) | 101368 |
| Rows rejected by length/format | 73437 |
| Unique 3–7 A–Z candidates before exclusions | 27931 |
| Unique game candidates before exclusions | 5979 |
| Exclusion-list entries | 81 |
| Excluded candidates present in recognition source | 77 |
| Game words after filtering | 5948 |
| Recognition words after filtering | 27854 |

Game lengths — 3: 275, 4: 919, 5: 1358, 6: 1641, 7: 1755.

Recognition lengths — 3: 657, 4: 2557, 5: 5045, 6: 8162, 7: 11433.

## 100 game-word examples

The following are 20 evenly spaced alphabetical examples for each length,
so the sample spans the dictionary rather than only its first page:

ACE, ARC, BED, BUT, DAY, EAR, FIT, GOD, HID, INK, LAW, MAP, NIL, OUR, PIN, RED, SET, SUM, TON, WAS, ABLE, BEEF, BUMP, COOK, DIRE, ENVY, FOLD, GRAY, HOOK, LAID, LOOP, MOCK, OPEN, POLE, RIDE, SEEK, SONG, TELL, TREK, WEAK, ABIDE, AWAIT, BORED, CHOIR, CRUSH, DRIPS, FIELD, FUNDS, HATES, KINDS, LYRIC, NERVE, PETTY, RACED, SAFER, SIXTH, STAKE, TASTE, TRIES, WALKS, ABORTS, ARMING, BLANKS, CHANCE, COVERS, DIVIDE, EXITED, FORGOT, HATING, IRONIC, LOGGED, MOUNTS, PALACE, PRICES, RELIED, SCARED, SLOWED, STRIVE, TOKENS, VENDOR, ABANDON, ARRIVED, BOOKLET, CLEANED, COURSES, DESERTS, EDUCATE, FALLACY, GATHERS, IDEALLY, LABELED, MEASURE, OBLIGES, PINCHED, PUMPING, RENAMES, SCROLLS, SPEAKER, TARGETS, USUALLY.

## Exclusions and quality limits

Examples rejected by category/format include proper names, abbreviations,
contractions such as `can't`, hyphenated words, accented entries, and entries
outside 3–7 characters. Examples rejected by `exclude_en.txt` include
`MORON`, `MORONS`, `IDIOT`, `IDIOTS`, and sensitive/profane entries; the
complete exact list is in that file. 77 exclusion entries
actually occur in the selected recognition tiers.

This is a conservative *candidate* game list, not a linguistically verified
lexicon. Even the 10–20 bands can contain inflected forms, obscure homographs,
regional spellings, or terms with unwanted meanings. Proper-name homographs
may remain when the same spelling is also a common word. The SCOWL category
selection does not guarantee part of speech. SCOWL source POS/inflection data
could support a future noun review, but it is not a reliable final noun
classifier; no noun-only claim is made. The older SCOWL source `pos/part-of-speech.txt` was sampled: 4786 of 5948 game words have a POS record, and 3179 have an `N` tag. This is only a candidate noun pool: the file combines Moby and WordNet, may not match this SCOWL release, has incomplete coverage and ambiguous/multiple senses.
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
