"""Build a review-only, reproducible 150-level campaign from the existing POC engine."""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from html import escape
import json
from pathlib import Path
import random

from crossword import Placement, options, validate
from dictionary import ROOT, load_words
from experiment_physical import flagged_words
from generator import possible_words
from preview import grid, model
from scoring import metrics

CHAPTERS = (
    ("Лес", 1, 20, (3, 4, 5), 2, 7),
    ("Озеро", 21, 50, (5, 6), 5, 9),
    ("Горы", 51, 80, (6, 7), 7, 12),
    ("Замок", 81, 110, (7,), 9, 15),
    ("Север", 111, 150, (7,), 10, 18),
)
SET_LIMITS = {3: 6, 4: 35, 5: 80, 6: 95, 7: 185}
DEFAULT_OUTPUT = ROOT / "campaign_output"
INTRO_SETS = ("КОТ", "НОС", "ЕЛОТ", "ОРСТ", "АДКОС")


def lexical_groups(words: list[str]):
    groups: dict[str, list[str]] = defaultdict(list)
    for word in words:
        groups["".join(sorted(word))].append(word)
    ranked = {length: [] for length in SET_LIMITS}
    for letters, seeds in groups.items():
        length = len(letters)
        if length not in ranked:
            continue
        potential = possible_words(letters, words)
        if len(potential) < (2 if length == 3 else 3 if length == 4 else 4):
            continue
        counts = Counter(map(len, potential))
        rank = len(potential) + 1.4 * counts[4] + 1.6 * counts[5] + counts[6] + counts[7]
        ranked[length].append((rank, letters, sorted(seeds), potential))
    for length in ranked:
        ranked[length].sort(key=lambda item: (-item[0], item[1]))
        chosen = ranked[length][:SET_LIMITS[length]]
        for intro in INTRO_SETS:
            if len(intro) == length and not any(item[1] == intro for item in chosen):
                chosen.extend(item for item in ranked[length] if item[1] == intro)
        ranked[length] = chosen
    return ranked


def layout_score(placed: list[Placement]) -> float:
    m = metrics(placed)
    quality = sum(14 if len(p.word) == 5 else 12 if len(p.word) >= 6 else 8 if len(p.word) == 4 else 0 for p in placed)
    return round(
        100 * len(placed) + quality + 6 * m["crossings"]
        + 18 * m["density"] - 1.2 * m["width"] * m["height"]
        - 5 * m["dangling"] - 5 * abs(m["width"] - m["height"])
        + 1.5 * m["square"], 3,
    )


def search_set(possible: list[str], seeds: list[str], rng: random.Random, attempts: int, length: int):
    best: dict[int, list[Placement]] = {}
    for attempt in range(attempts):
        seed = seeds[attempt % len(seeds)]
        placed = [Placement(seed, 0, 0, rng.choice(("across", "down")))]
        unused = [word for word in possible if word != seed]
        rng.shuffle(unused)
        while len(placed) < min(18, len(possible)):
            choices = []
            seven = sum(len(p.word) == 7 for p in placed)
            short = sum(len(p.word) == 3 for p in placed)
            for word in unused:
                if len(word) == 7 and seven >= 2:
                    continue
                if length >= 6 and len(word) == 3 and short >= 6:
                    continue
                for candidate in options(placed, word, 32):
                    trial = placed + [candidate]
                    choices.append((layout_score(trial), rng.random(), candidate))
            if not choices:
                break
            choices.sort(key=lambda item: (item[0], item[1]), reverse=True)
            chosen = rng.choice(choices[:min(9, len(choices))])[2]
            placed.append(chosen)
            unused.remove(chosen.word)
            count = len(placed)
            if count >= 2 and validate(placed):
                current = best.get(count)
                if current is None or layout_score(placed) > layout_score(current):
                    best[count] = placed.copy()
    return best


def make_pool(words: list[str], seed: int, attempts: int):
    rng = random.Random(seed)
    groups = lexical_groups(words)
    pool = []
    for length, items in groups.items():
        for rank, (_, letters, seeds, possible) in enumerate(items, 1):
            variants = search_set(possible, seeds, rng, attempts if length >= 6 else max(12, attempts), length)
            for count, placed in variants.items():
                m = metrics(placed)
                occupied = m["occupied"]
                long_words = sum(len(p.word) >= 5 for p in placed)
                average_length = sum(len(p.word) for p in placed) / count
                difficulty = round(
                    8 * (length - 3) + 2.5 * (count - 2)
                    + 1.4 * long_words + .6 * len(possible)
                    + .24 * m["width"] * m["height"]
                    + .7 * m["crossings"] + .6 * average_length
                    - 5 * m["density"], 2,
                )
                pool.append({
                    "letters": letters, "seed": placed[0].word, "possible": possible,
                    "placements": placed, "count": count, "metrics": m,
                    "difficulty": difficulty, "layout_score": layout_score(placed),
                    "long_words": long_words, "occupied": occupied,
                })
            if rank % 20 == 0:
                print(f"pool {length} letters: {rank}/{len(items)} sets, {len(pool)} variants", flush=True)
    return pool


def chapter_for(number: int):
    return next(chapter for chapter in CHAPTERS if chapter[1] <= number <= chapter[2])


def target_for(number: int, chapter):
    title, start, end, lengths, minimum, maximum = chapter
    progress = (number - start) / max(1, end - start)
    wave = (0, 1, -1, 0, 2, -2, 1, -1)[(number - start) % 8]
    target_count = max(minimum, min(maximum, round(minimum + progress * (maximum - minimum)) + wave))
    if number <= 5:
        target_count = (2, 2, 3, 4, 4)[number - 1]
    if (number - start) % 6 == 5:
        target_count = max(minimum, target_count - 2)
    target_length = lengths[min(len(lengths) - 1, int(progress * len(lengths)))]
    target_difficulty = (8 * (target_length - 3) + 2.5 * (target_count - 2)
                         + 1.3 * max(0, target_count - 4) + .5 * (7 + 2 * target_count)
                         + .24 * (target_count * 5) + .7 * target_count + 1)
    return target_count, target_length, target_difficulty


def sequence(pool: list[dict], rng: random.Random):
    milestones = {125: 16, 139: 17, 150: 18}
    selected = []
    used_sets = set()
    recent_words: dict[str, int] = {}
    global_words: Counter = Counter()
    repeats = []
    for number in range(1, 151):
        chapter = chapter_for(number)
        title, start, end, lengths, minimum, maximum = chapter
        target_count, target_length, target_difficulty = target_for(number, chapter)
        candidates = [p for p in pool if len(p["letters"]) in lengths and minimum <= p["count"] <= maximum]
        if number in milestones:
            exact = [p for p in candidates if p["count"] == milestones[number]]
            if exact:
                candidates = exact
        if number <= 2:
            candidates = [p for p in candidates if len(p["letters"]) == 3]
        elif number <= 5:
            candidates = [p for p in candidates if len(p["letters"]) in (4, 5)]
        elif number <= 10:
            candidates = [p for p in candidates if len(p["letters"]) in (4, 5)]
        elif number <= 20:
            candidates = [p for p in candidates if len(p["letters"]) == 5]
        if number <= 5:
            intro = INTRO_SETS[number - 1]
            fixed = [p for p in candidates if p["letters"] == intro]
            if fixed:
                exact = [p for p in fixed if p["count"] == target_count]
                candidates = exact or fixed
        unique = [p for p in candidates if p["letters"] not in used_sets]
        if unique:
            candidates = unique
        fresh = [p for p in candidates if all(
            number - recent_words.get(word.word, -1000) > 3 for word in p["placements"])]
        if fresh:
            candidates = fresh
        if not candidates:
            raise RuntimeError(f"No campaign candidates for level {number}")
        choices = []
        for item in candidates:
            m = item["metrics"]
            words = [p.word for p in item["placements"]]
            recent_penalty = 0.0
            for word in words:
                distance = number - recent_words.get(word, -1000)
                if distance <= 3:
                    recent_penalty += 130 if len(word) <= 4 else 70
                elif distance <= 8:
                    recent_penalty += (9 - distance) * (8 if len(word) <= 4 else 4)
                recent_penalty += min(global_words[word], 15) * (2.5 if len(word) <= 4 else .8)
            repeat_penalty = 1000 if item["letters"] in used_sets else 0
            length_penalty = 14 * abs(len(item["letters"]) - target_length)
            count_penalty = 22 * abs(item["count"] - target_count)
            difficulty_penalty = .8 * abs(item["difficulty"] - target_difficulty)
            geometry_penalty = 2 * m["dangling"] + .14 * m["width"] * m["height"]
            quality_bonus = .05 * item["layout_score"] + item["long_words"]
            total = (repeat_penalty + recent_penalty + length_penalty + count_penalty
                     + difficulty_penalty + geometry_penalty - quality_bonus)
            choices.append((total, rng.random(), item, recent_penalty))
        choices.sort(key=lambda choice: (choice[0], choice[1]))
        _, _, chosen, recent_penalty = choices[0]
        if chosen["letters"] in used_sets:
            repeats.append((number, chosen["letters"]))
        used_sets.add(chosen["letters"])
        for word in (p.word for p in chosen["placements"]):
            recent_words[word] = number
            global_words[word] += 1
        selected.append({**chosen, "id": number, "chapter": title,
                         "target_count": target_count, "recent_penalty": round(recent_penalty, 2)})
    def close_repeat_cost(items: list[dict]) -> float:
        cost = 0.0
        for index in range(110, 150):
            words = {p.word for p in items[index]["placements"]}
            for prior in range(max(0, index - 3), index):
                for word in words & {p.word for p in items[prior]["placements"]}:
                    cost += (4 - (index - prior)) * (4 if len(word) <= 4 else 2)
            cost += .15 * abs(items[index]["count"] - target_for(index + 1, CHAPTERS[4])[0])
        return cost

    # Reorder only the last chapter to avoid close repeats around its large boards.
    movable = [index for index in range(110, 150) if index + 1 not in milestones]
    for _ in range(30):
        current = close_repeat_cost(selected)
        best = (current, None, None)
        for left_offset, left in enumerate(movable):
            for right in movable[left_offset + 1:]:
                selected[left], selected[right] = selected[right], selected[left]
                value = close_repeat_cost(selected)
                selected[left], selected[right] = selected[right], selected[left]
                if value < best[0] - .01:
                    best = (value, left, right)
        if best[1] is None:
            break
        selected[best[1]], selected[best[2]] = selected[best[2]], selected[best[1]]
    recent_words.clear()
    for number, item in enumerate(selected, 1):
        item["id"] = number
        item["target_count"] = target_for(number, chapter_for(number))[0]
        penalty = 0.0
        for placement in item["placements"]:
            distance = number - recent_words.get(placement.word, -1000)
            if distance <= 3:
                penalty += 130 if len(placement.word) <= 4 else 70
            elif distance <= 8:
                penalty += (9 - distance) * (8 if len(placement.word) <= 4 else 4)
            recent_words[placement.word] = number
        item["recent_penalty"] = round(penalty, 2)
    return selected, repeats


def save(selected: list[dict], repeats: list, pool: list[dict], seed: int, attempts: int, output: Path):
    output.mkdir(parents=True, exist_ok=True)
    levels = []
    cards = []
    for item in selected:
        candidate = model(item)
        m = item["metrics"]
        level = {
            "id": item["id"], "letters": list(item["letters"]),
            "words": [{"text": p["word"], "row": p["row"], "col": p["col"], "direction": p["direction"]}
                      for p in candidate["placements"]],
            "chapter": item["chapter"], "seed": item["seed"],
            "difficulty_score": item["difficulty"], "word_potential": len(item["possible"]),
        }
        levels.append(level)
        tiles = "".join(
            f"<span class='cell {'cross' if cross else 'empty' if char == '·' else 'full'}'>{'' if char == '·' else escape(char)}</span>"
            for row in grid(item["placements"]) for char, cross in row
        )
        cards.append((item["chapter"],
                      f"<article class='card'><h3>LEVEL {item['id']} · {escape(item['letters'])}</h3>"
                      f"<p>Seed: {escape(item['seed'])} · Words: {item['count']} · Grid: {m['width']}×{m['height']} "
                      f"· Difficulty: {item['difficulty']:.1f} · Potential: {len(item['possible'])}</p>"
                      f"<div class='grid' style='--columns:{m['width']}'>{tiles}</div>"
                      f"<p>{escape(', '.join(p.word for p in item['placements']))}</p></article>"))
    (output / "campaign_levels.json").write_text(json.dumps(levels, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    css = "body{font:16px system-ui,sans-serif;background:#f2f3f5;color:#1b2430;margin:24px}main{max-width:1150px;margin:auto}.card{background:white;border:1px solid #ccd2d8;border-radius:10px;padding:16px;margin:16px 0}.grid{display:grid;grid-template-columns:repeat(var(--columns),30px);gap:2px;margin:15px 0}.cell{box-sizing:border-box;width:30px;height:30px;line-height:28px;text-align:center;font-weight:700;border:1px solid #8b96a3;background:white}.cell.empty{border:0;background:transparent}.cell.cross{background:#cde6fa}h2{background:#dce8f7;padding:12px;border-radius:8px}"
    sections = []
    for title, start, end, _, _, _ in CHAPTERS:
        sections.append(f"<section><h2>ГЛАВА {CHAPTERS.index(chapter_for(start))+1} · {title.upper()} · {start}–{end}</h2>"
                        + "".join(card for chapter, card in cards if chapter == title) + "</section>")
    html = ("<!doctype html><html lang='ru'><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'>"
            "<title>КроссСлов · кампания 150</title><style>" + css + "</style><main><h1>КроссСлов · кандидат кампании из 150 уровней</h1>"
            "<p>Для ручного просмотра. Production levels.json не заменён.</p>" + "".join(sections) + "</main></html>")
    (output / "preview.html").write_text(html, encoding="utf-8")

    by_word: dict[str, list[int]] = defaultdict(list)
    by_set: dict[str, list[int]] = defaultdict(list)
    for item in selected:
        by_set[item["letters"]].append(item["id"])
        for p in item["placements"]:
            by_word[p.word].append(item["id"])
    counts = Counter(item["count"] for item in selected)
    sizes = Counter(f"{item['metrics']['width']}×{item['metrics']['height']}" for item in selected)
    letters = Counter(len(item["letters"]) for item in selected)
    questionable = flagged_words() & set(by_word)
    lines = [
        "КРОСССЛОВ · CANDIDATE CAMPAIGN (not production)",
        f"SEED: {seed}; ATTEMPTS PER SET: {attempts}; POOL VARIANTS: {len(pool)}",
        f"TOTAL LEVELS: {len(selected)}",
        "",
        "CHAPTERS",
    ]
    for title, start, end, _, _, _ in CHAPTERS:
        part = selected[start - 1:end]
        scores = [item["difficulty"] for item in part]
        lines.append(f"{title}: {start}–{end}, {len(part)} levels, difficulty {min(scores):.2f}–{max(scores):.2f}, words {min(item['count'] for item in part)}–{max(item['count'] for item in part)}")
    lines.extend(["", "LETTER COUNTS: " + json.dumps(dict(sorted(letters.items())), ensure_ascii=False),
                  "WORD COUNTS: " + json.dumps(dict(sorted(counts.items())), ensure_ascii=False),
                  "GRID SIZES: " + json.dumps(dict(sorted(sizes.items())), ensure_ascii=False),
                  "DIFFICULTY TOTAL RANGE: " + f"{min(item['difficulty'] for item in selected):.2f}–{max(item['difficulty'] for item in selected):.2f}",
                  "", "TOP-20 REPEATED WORDS"])
    for word, ids in sorted(by_word.items(), key=lambda pair: (-len(pair[1]), pair[0]))[:20]:
        distance = min((b - a for a, b in zip(ids, ids[1:])), default=None)
        lines.append(f"{word}: {len(ids)} levels; min distance: {distance if distance is not None else '—'}; levels: {', '.join(map(str, ids))}")
    repeated_sets = {letters: ids for letters, ids in by_set.items() if len(ids) > 1}
    lines.extend(["", f"UNIQUE LETTER SETS: {len(by_set)}", f"REPEATED LETTER SETS: {len(repeated_sets)}"])
    lines.extend(f"{letters}: {', '.join(map(str, ids))}" for letters, ids in sorted(repeated_sets.items()))
    largest = max(selected, key=lambda item: item["metrics"]["width"] * item["metrics"]["height"])
    lines.extend(["", f"LARGEST GRID: level {largest['id']}, {largest['metrics']['width']}×{largest['metrics']['height']}",
                  f"MAX WORD COUNT: {max(item['count'] for item in selected)}",
                  "LEVELS WITH 15+ WORDS: " + ", ".join(str(item["id"]) for item in selected if item["count"] >= 15),
                  "QUESTIONABLE USED: " + (", ".join(sorted(questionable)) if questionable else "0"),
                  "", "LEVEL DETAILS"])
    for item in selected:
        m = item["metrics"]
        lines.append(f"{item['id']:03d} {item['chapter']} | {item['letters']} | seed {item['seed']} | {item['count']} words | {m['width']}×{m['height']} | density {m['density']:.3f} | crossings {m['crossings']} | potential {len(item['possible'])} | difficulty {item['difficulty']:.2f} | recent penalty {item['recent_penalty']:.1f} | {', '.join(p.word for p in item['placements'])}")
    (output / "campaign_report.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {len(levels)} levels; unique letter sets {len(by_set)}; repeated {len(repeated_sets)}; questionable {len(questionable)}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seed", type=int, default=20261006)
    parser.add_argument("--attempts", type=int, default=10)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    if args.attempts < 1:
        parser.error("attempts must be positive")
    words = [word for word in load_words() if word not in flagged_words()]
    pool = make_pool(words, args.seed, args.attempts)
    selected, repeats = sequence(pool, random.Random(args.seed + 1))
    save(selected, repeats, pool, args.seed, args.attempts, args.output)


if __name__ == "__main__":
    main()
