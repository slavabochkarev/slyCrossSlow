"""Complete the approved English introduction with the existing crossword engine.

Run this developer tool before copying its validated result into assets.
The approved first twenty objects are copied unchanged, never searched again.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from concurrent.futures import ProcessPoolExecutor, as_completed
from hashlib import sha256
from html import escape
from itertools import combinations
import json
from pathlib import Path
import random

from campaign_generator import search_set
from crossword import Placement, board, bounds, validate
from experiment_english import DICTIONARY, difficulty, portrait, read_words
from preview import grid
from scoring import metrics

ROOT = Path(__file__).resolve().parent
OUTPUT = ROOT / "english_campaign"
APPROVED = ROOT / "english_preview" / "levels_en_preview.json"
SEED = 20261021
# Editorial avoidance for this campaign only. No dictionary files are edited.
# These are ambiguous acronyms, spell-check artefacts, or unsuitable senses.
AVOID = set("ASS HES SHES GIT GITS DOS UNIX ABORT ABORTED ABORTS ANAL ANUS PORN TIT TITS DICK COCK CUM FAGS FAG NAZI NAZIS AIDS HIV LSD STD STDS DAMN THOUS THOU TRIPOS ROMAN KEN UPS SIC SIGMA WONT AMP PRO".split())
REVIEW = {
    "SINE": "technical mathematical term", "ION": "scientific term",
    "IRATE": "less basic adjective", "REND": "literary verb",
    "LEST": "formal conjunction", "LENT": "past of LEND / proper-name homograph",
    "LAIN": "less basic participle", "SOD": "regional noun / offensive sense",
    "DIRE": "less basic adjective", "PAR": "golf/finance term",
    "PER": "preposition/abbreviation-like appearance", "NIL": "regional zero",
    "CHARS": "verb/plural or computing abbreviation-like appearance",
    "CHAR": "verb/noun or computing abbreviation-like appearance",
    "INTER": "formal verb / prefix-like appearance", "TENS": "number plural",
    "RIDS": "uncommon inflected form", "WETS": "less common inflected form",
    "TERSE": "less basic adjective", "SLAG": "industrial term / offensive sense",
    "SACS": "anatomical term", "SAC": "anatomical term",
    "RANT": "ordinary but less basic noun/verb", "PANT": "verb, not singular of PANTS",
    "DINER": "regional everyday noun", "DINE": "more formal than EAT",
    "AMBIENT": "technical/less basic adjective", "AKIN": "less basic adjective",
    "BETA": "Greek-letter/software term", "CAM": "mechanical term / abbreviation-like",
    "CHAP": "regional noun", "DELTA": "technical/geographic term",
    "DESTINE": "less common verb", "ERGO": "formal Latin loan",
    "GLEAN": "less basic verb", "LAGER": "regional drink term",
    "LISP": "speech/programming homograph", "LITER": "US measurement spelling",
    "ONUS": "formal noun", "ORIENT": "less basic verb",
    "PARSE": "technical verb", "PARSING": "technical verb form",
    "PUNT": "regional sport/boating term", "PUNTS": "regional term/inflection",
    "RENDS": "literary verb form", "ROUT": "less basic noun/verb",
    "ROUTS": "less basic noun/verb form", "SECTS": "less basic plural",
    "UNTO": "archaic/formal preposition", "VENDS": "less common verb form",
    "WEE": "regional adjective", "WREN": "specific bird name",
    "DON": "formal verb / title / name homograph", "DONS": "formal verb/title plural",
}
CHAPTERS = (("Лес", 1, 20), ("Озеро", 21, 50), ("Горы", 51, 80),
            ("Замок", 81, 110), ("Север", 111, 150))
ADVISORY = {
    "AMP": "lexical shortened form / technical noun; check abbreviation policy",
    "PRO": "lexical shortened form; check abbreviation policy",
    "CON": "ordinary noun/verb with several senses; check intended sense",
    "TOME": "literary noun, less basic vocabulary",
    "VICAR": "regional British noun",
    "NEURAL": "scientific adjective",
    "DEITY": "less basic abstract noun",
    "ATHEISM": "philosophical noun, domain-specific vocabulary",
    "ETHIC": "valid singular noun; less familiar than ETHICS",
    "ERR": "formal verb meaning make a mistake; less basic vocabulary",
}


def placements(level):
    return [Placement(w["text"], w["row"], w["col"], w["direction"]) for w in level["words"]]


def gameplay(level):
    return {key: level[key] for key in ("id", "letters", "words")}


def validate_campaign(levels, approved, game, recognition, excluded):
    assert len(levels) == 150
    assert [level["id"] for level in levels] == list(range(1, 151))
    assert [gameplay(level) for level in levels[:20]] == [gameplay(level) for level in approved]
    signatures = set()
    previous = None
    previous_level = None
    for level in levels:
        letters = "".join(sorted(level["letters"]))
        assert letters not in signatures, f"Duplicate set {letters}"
        signatures.add(letters)
        assert 3 <= len(letters) <= 7 and all("A" <= c <= "Z" for c in letters)
        placed = placements(level)
        assert validate(placed), f"Invalid crossword {level['id']}"
        m = metrics(placed)
        for p in placed:
            assert p.word in game and p.word in recognition, (level["id"], p.word)
            assert p.word not in excluded and p.word not in AVOID
            assert not Counter(p.word) - Counter(letters)
            assert p.row >= 0 and p.col >= 0
            assert all(0 <= r < m["height"] and 0 <= c < m["width"] for r, c in p.cells())
        for index, p in enumerate(placed):
            for other in placed[index + 1:]:
                assert len(set(p.cells()) & set(other.cells())) <= 1
        d = difficulty(letters, placed)
        if previous and level["id"] > 20:
            prev_count, prev_m, prev_d = previous
            assert abs(len(placed) - prev_count) <= 2
            assert abs(m["width"] - prev_m["width"]) <= 2
            assert abs(m["height"] - prev_m["height"]) <= 2
            assert -7 <= d - prev_d <= 14, (level["id"], d, prev_d)
            shared_letters = sum((Counter(letters) & Counter(previous_level["letters"])).values())
            if len(letters) == len(previous_level["letters"]):
                assert shared_letters < len(letters) - 1
            shared_words = len({p.word for p in placed} & {w["text"] for w in previous_level["words"]})
            assert shared_words <= max(2, min(len(placed), prev_count) // 4)
        previous = len(placed), m, d
        previous_level = level
    assert min(len(level["words"]) for level in levels[110:]) >= 13
    assert max(len(level["words"]) for level in levels[110:]) >= 16


def lexical_pool(game, used_sets, six_limit, seven_limit):
    groups = defaultdict(list)
    for word in sorted(game - AVOID):
        groups["".join(sorted(word))].append(word)
    ranked = {6: [], 7: []}
    for letters, seeds in groups.items():
        if len(letters) not in ranked or letters in used_sets:
            continue
        signatures = {"".join(c) for n in range(3, len(letters) + 1) for c in combinations(letters, n)}
        possible = sorted({word for signature in signatures for word in groups.get(signature, [])})
        # Give 4–6 letter words enough representation without forbidding normal
        # verbs, plurals or past forms. Search itself caps short/seven-letter words.
        long_count = sum(len(word) >= 4 for word in possible)
        if long_count < 8:
            continue
        rank = len(possible) + .7 * long_count - 2 * sum(word in REVIEW for word in possible)
        ranked[len(letters)].append((rank, letters, seeds, possible))
    result = []
    for length, limit in ((6, six_limit), (7, seven_limit)):
        ranked[length].sort(key=lambda item: (-item[0], item[1]))
        # Preserve varied letter composition instead of only S/T/E-rich sets.
        rich = ranked[length][:limit * 2]
        chosen = []
        while rich and len(chosen) < limit:
            pick = max(rich, key=lambda item: item[0] - sum(
                8 for prior in chosen if sum((Counter(item[1]) & Counter(prior[1])).values()) >= length - 1))
            chosen.append(pick)
            rich.remove(pick)
        result.extend(chosen)
    return result


def search_task(task):
    _, letters, seeds, possible, attempts = task
    # Prefer ordinary vocabulary but retain all word types. Keep enough words
    # for large boards; no recognition-only words are ever considered.
    possible = sorted(possible, key=lambda word: (word in REVIEW, -len(word), word))
    possible = possible[:42]
    seeds = [word for word in seeds if word in possible][:2]
    if not seeds:
        return []
    rng = random.Random(SEED + int(sha256(letters.encode()).hexdigest()[:8], 16))
    found = search_set(possible, seeds, rng, attempts, len(letters))
    result = []
    for count, placed in found.items():
        if count < 7:
            continue
        placed = portrait(placed)
        m = metrics(placed)
        if max(m["width"], m["height"]) > 13:
            continue
        result.append({"letters": letters, "placements": [p.__dict__ for p in placed],
                       "count": count, "metrics": m, "difficulty": difficulty(letters, placed)})
    return result


def make_pool(game, approved, attempts, workers, six_limit, seven_limit):
    used_sets = {"".join(sorted(level["letters"])) for level in approved}
    lexical = lexical_pool(game, used_sets, six_limit, seven_limit)
    tasks = [(*item, attempts) for item in lexical]
    pool = []
    with ProcessPoolExecutor(max_workers=workers) as executor:
        futures = [executor.submit(search_task, task) for task in tasks]
        for done, future in enumerate(as_completed(futures), 1):
            pool.extend(future.result())
            if done % 10 == 0:
                print(f"Search {done}/{len(tasks)} sets; {len(pool)} layouts", flush=True)
    pool.sort(key=lambda item: (item["letters"], item["count"]))
    return pool


def target(number):
    # Count increases by at most one at chapter boundaries and within a chapter.
    if number <= 50:
        return round(7 + (number - 21) * 3 / 29)
    if number <= 80:
        return round(10 + (number - 51) * 2 / 29)
    if number <= 110:
        return round(12 + (number - 81) * 2 / 29)
    return round(14 + (number - 111) * 4 / 39)


def select(pool, approved):
    selected = list(approved)
    used_sets = {"".join(sorted(level["letters"])) for level in approved}
    word_usage = Counter(w["text"] for level in approved for w in level["words"])
    for number in range(21, 151):
        previous = placements(selected[-1])
        pm = metrics(previous)
        pd = difficulty("".join(selected[-1]["letters"]), previous)
        previous_letters = Counter(selected[-1]["letters"])
        previous_words = {p.word for p in previous}
        recent = Counter(w["text"] for level in selected[-4:] for w in level["words"])
        choices = []
        for item in pool:
            if item["letters"] in used_sets:
                continue
            count, m, d = item["count"], item["metrics"], item["difficulty"]
            if abs(count - target(number)) > 1 or abs(count - len(previous)) > 2:
                continue
            if number >= 111 and count < 13:
                continue
            if abs(m["width"] - pm["width"]) > 2 or abs(m["height"] - pm["height"]) > 2:
                continue
            if not -7 <= d - pd <= 14:
                continue
            shared_letters = sum((Counter(item["letters"]) & previous_letters).values())
            if len(item["letters"]) == len(selected[-1]["letters"]) and shared_letters >= len(item["letters"]) - 1:
                continue
            words = {p["word"] for p in item["placements"]}
            shared_words = len(words & previous_words)
            if shared_words > max(2, min(count, len(previous)) // 4):
                continue
            desired_length = 6 if number < 40 else 7
            quality = (24 * abs(count - target(number)) + 7 * abs(len(item["letters"]) - desired_length)
                       + 1.5 * sum(recent[w] for w in words) + .2 * sum(word_usage[w] for w in words)
                       + 2 * shared_words + 9 * sum(w in REVIEW for w in words)
                       + .07 * m["width"] * m["height"] + .7 * m["dangling"]
                       + .15 * abs(d - pd - .45) - .5 * m["crossings"])
            choices.append((quality, item["letters"], count, item))
        if not choices:
            raise RuntimeError(f"No valid continuation at {number}; no fallback/repeated sets written")
        item = min(choices, key=lambda choice: choice[:3])[3]
        placed = [Placement(**p) for p in item["placements"]]
        min_r, min_c, _, _ = bounds(board(placed)[0])
        selected.append({"id": number, "letters": list(item["letters"]),
                         "words": [{"text": p.word, "row": p.row - min_r, "col": p.col - min_c,
                                    "direction": p.direction} for p in placed]})
        used_sets.add(item["letters"])
        word_usage.update(p.word for p in placed)
    return selected


def write_outputs(levels, approved, game, recognition, excluded):
    validate_campaign(levels, approved, game, recognition, excluded)
    by_word = defaultdict(list)
    lines = ["КроссСлов · English campaign · 150 levels", "VALIDATION: PASS",
             "Approved levels 1–20: identical gameplay content; original file unchanged.",
             f"Seed: {SEED}; reproducible cached search layouts: search_pool.json",
             "Approved file SHA-256: " + sha256(APPROVED.read_bytes()).hexdigest(),
             "Difficulty is the same transparent experiment heuristic for RU and EN, not measured player difficulty.",
             "No dictionary expansion; no recognition-only generation words.",
             "Editorial campaign-only avoidance: " + ", ".join(sorted(AVOID)), ""]
    cards = []
    for title, start, end in CHAPTERS:
        part = levels[start - 1:end]
        count = [len(level["words"]) for level in part]
        ds = [difficulty("".join(level["letters"]), placements(level)) for level in part]
        lines.append(f"{title} {start}–{end}: words {min(count)}–{max(count)}; difficulty {min(ds):.2f}–{max(ds):.2f}, mean {sum(ds)/len(ds):.2f}")
    lines.extend(["", "LEVEL | LETTER SET | WORDS | GRID width×height | CROSSINGS | DIFFICULTY | WORD LIST"])
    for level in levels:
        placed = placements(level)
        m = metrics(placed)
        d = difficulty("".join(level["letters"]), placed)
        for p in placed:
            by_word[p.word].append(level["id"])
        review_notes = REVIEW | ADVISORY
        notes = {p.word: review_notes[p.word] for p in placed if p.word in review_notes}
        if level["id"] <= 20:
            notes.update(level.get("preview", {}).get("review", {}))
        words = ", ".join(p.word for p in placed)
        lines.append(f"{level['id']:03d} | {''.join(level['letters'])} | {len(placed)} | {m['width']}×{m['height']} | {m['crossings']} | {d:.2f} | {words}")
        tiles = "".join(f'<span class="cell {"empty" if char == "·" else "cross" if cross else ""}">{"" if char == "·" else char}</span>' for row in grid(placed) for char, cross in row)
        cards.append(f'<article id="level-{level["id"]}"><h3>{level["id"]:03d} · {"".join(level["letters"])}</h3><p>{len(placed)} words · {m["width"]}×{m["height"]} · crossings {m["crossings"]} · difficulty {d:.2f}</p><div class="grid" style="--cols:{m["width"]}">{tiles}</div><p>{escape(words)}</p>{"<details><summary>Review ⚑</summary><p>" + escape(str(notes)) + "</p></details>" if notes else ""}</article>')
    review_notes = REVIEW | ADVISORY
    suspicious = {word: ids for word, ids in sorted(by_word.items()) if word in review_notes}
    lines.extend(["", f"UNIQUE WORDS: {len(by_word)}", "EXCLUDED WORDS USED: 0", "DUPLICATE LETTER SETS: 0", "", "POTENTIALLY QUESTIONABLE / REVIEW"])
    lines.extend(f"{word} | levels {','.join(map(str, ids))} | {review_notes[word]}" for word, ids in suspicious.items())
    lines.extend(["", "Regular plurals and verbs are retained; these are not automatically questionable.",
                  "Review flags identify less basic/regional/technical senses, not confirmed invalid words.",
                  "First twenty approved inflection/editorial flags remain in their preview metadata.", "", "ALL USED WORDS", ", ".join(sorted(by_word))])
    scores = [difficulty("".join(level["letters"]), placements(level)) for level in levels]
    lines.extend(["", "DIFFICULTY DISTRIBUTION (10-point bins): " + json.dumps(dict(sorted(Counter(int(value // 10) * 10 for value in scores).items()))),
                  "MAX ADJACENT DIFFICULTY INCREASE: " + str(round(max(b - a for a, b in zip(scores, scores[1:])), 2)),
                  "WORD COUNT DISTRIBUTION: " + json.dumps(dict(sorted(Counter(len(level['words']) for level in levels).items())))])
    ru = json.loads((ROOT.parents[1] / "assets" / "levels.json").read_text(encoding="utf-8"))
    lines.extend(["", "RU / EN COMPARISON (same heuristic)"])
    for title, start, end in CHAPTERS:
        values = []
        for campaign in (ru, levels):
            part = campaign[start - 1:end]
            ds = [difficulty("".join(level["letters"]), placements(level)) for level in part]
            values.append(f"mean difficulty {sum(ds)/len(ds):.2f}; words {min(len(l['words']) for l in part)}–{max(len(l['words']) for l in part)}")
        lines.append(f"{title}: RU {values[0]} | EN {values[1]}")
    (OUTPUT / "campaign_levels_en.json").write_text(json.dumps(levels, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (OUTPUT / "campaign_report_en.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
    css = 'body{font:16px system-ui;background:#eef2f6;color:#18263a;margin:20px}main{max-width:1200px;margin:auto}.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,350px),1fr));gap:16px}article{padding:18px;background:white;border-radius:12px;overflow:auto}p{line-height:1.5}.grid{display:grid;grid-template-columns:repeat(var(--cols),24px);gap:2px;margin:15px 0}.cell{height:24px;line-height:22px;text-align:center;font-weight:bold;border:1px solid #8c9bb0;box-sizing:border-box}.empty{border:0}.cross{background:#d2e8ff}nav a{margin-right:15px}details{font-size:13px}'
    nav = "".join(f'<a href="#level-{start}">{title} {start}–{end}</a>' for title, start, end in CHAPTERS)
    (OUTPUT / "preview_en.html").write_text(f'<!doctype html><html lang="ru"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>English campaign · 150</title><style>{css}</style><main><h1>English · 150 уровней</h1><p>Все сетки проверены. Первые 20 сохранены. Review — редакционные вопросы.</p><nav>{nav}</nav><div class="cards">{"".join(cards)}</div></main></html>', encoding="utf-8")
    print(f"VALID: 150 levels, {len(by_word)} unique words, {len(suspicious)} review words", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--attempts", type=int, default=3)
    parser.add_argument("--workers", type=int, default=4)
    parser.add_argument("--six-limit", type=int, default=100)
    parser.add_argument("--seven-limit", type=int, default=220)
    parser.add_argument("--rebuild-pool", action="store_true")
    parser.add_argument("--reuse-pool", action="store_true",
                        help="Reuse searched layouts after editorial changes; filter all words again")
    args = parser.parse_args()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    approved = json.loads(APPROVED.read_text(encoding="utf-8"))
    assert len(approved) == 20
    game = read_words(DICTIONARY / "game_words_en.txt")
    recognition = read_words(DICTIONARY / "recognition_words_en.txt")
    excluded = read_words(DICTIONARY / "exclude_en.txt")
    fingerprint = sha256(json.dumps([sorted(game - excluded - AVOID), sorted(REVIEW.items()), args.attempts, args.six_limit, args.seven_limit], sort_keys=True).encode()).hexdigest()
    cache = OUTPUT / "search_pool.json"
    saved = json.loads(cache.read_text()) if cache.exists() else {}
    if not args.reuse_pool and (args.rebuild_pool or saved.get("fingerprint") != fingerprint):
        pool = make_pool(game - excluded, approved, args.attempts, args.workers, args.six_limit, args.seven_limit)
        cache.write_text(json.dumps({"fingerprint": fingerprint, "pool": pool}, indent=2), encoding="utf-8")
    else:
        pool = saved["pool"]
    allowed = game - excluded - AVOID
    pool = [item for item in pool if all(p["word"] in allowed for p in item["placements"])]
    cache.write_text(json.dumps({"fingerprint": fingerprint, "pool": pool}, indent=2), encoding="utf-8")
    print(f"Pool: {len(pool)} layouts from {len({p['letters'] for p in pool})} sets", flush=True)
    selected = select(pool, approved)
    write_outputs(selected, approved, game, recognition, excluded)


if __name__ == "__main__":
    main()
