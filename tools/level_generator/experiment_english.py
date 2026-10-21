"""Generate a review-only 20-level English experiment using the existing engine.

Run: python tools/level_generator/experiment_english.py
Never builds dictionaries, writes production assets, or changes Flutter settings.
"""

from __future__ import annotations

from collections import Counter
from html import escape
import json
from pathlib import Path
import random
import re

from crossword import Placement, board, bounds, search, validate
from generator import possible_words
from scoring import metrics, score

ROOT = Path(__file__).resolve().parent
DICTIONARY = ROOT.parent / "english_dictionary"
OUTPUT = ROOT / "english_preview"
RANDOM_SEED = 20261020
PLAN = (
    ("CAT", 2), ("TOP", 2), ("EAT", 3), ("STAR", 3), ("STOP", 3),
    ("CARE", 4), ("TEAM", 4), ("STONE", 4), ("PLANT", 4), ("HEART", 4),
    ("TRAIN", 5), ("SMILE", 5), ("GARDEN", 5), ("STREAM", 5), ("PLANET", 5),
    ("LISTEN", 6), ("FRIEND", 6), ("PARENTS", 6), ("TEACHER", 7), ("PLASTER", 7),
)
# Human-reviewed vocabulary preference, not a replacement dictionary or a
# frequency corpus. Words absent from game_words_en.txt cannot be used.
COMMON = set("""
ACT CAT POT TOP ATE EAT TEA ART RAT TAR STAR RATS ARTS STOP POST SPOT POTS
CAR CARE RACE ACRE EAR ARE ERA TEAM MEAT MATE TAME STONE TONE NOTE NOTES
ONES SET NET TEN SON ONE TOE TONS NOSE NEST SENT PLANT PLAN ANT TAN TAP
PAN LAP NAP PANT HEART EARTH HATE HEAT RATE TEAR HEAR HARE TRAIN RAIN
RANT TIN AIR RAN SMILE SLIME MILE MILES SLIM LIME LIE LIES ISLE GARDEN
DANGER ANGER RANGE GRADE GRAND READ DEAR DARE DRAG RAGE AGE RED STREAM
MASTER STEAM SMART TEAMS MEATS MATES TAMES SAME SEAM ARM RAM PLANET PLATE
PLANE PANEL PETAL LATE TALE LEAP PALE PANE LANE LISTEN SILENT ENLIST LIST
LINE LINES LENT LENS SITE TIES TIE FRIEND FIND FIRE FINE RIDE RIND DINE
FRIED FIN END DEN DINER PAINTER PAINT PRINT PARENT PARENTS RETAIN REPAINT
TEACHER CHEATER HEATER CREATE TRACE REACH TEACH TREE EACH ACHE PLASTER
PLATES STAPLER PASTEL STAPLE PETALS PASTE PEAR PEARS PART PARTS PAST LAST
SALT SEAT EAST EATS REST TRAP TRAPS TAPE TAPES REAL EARN EARS NEAR NEAT
PEN PENS PET PANTS RENT SEA SPAN SPARE SPENT STARE STEP TEARS LEAST SALE
SEAL SLEPT STALE STEAL ALERT ALTER LATER TALES LET LETS
""".split())
WORD_NOTES = {
    word: "inflected form; confirm editorial policy (not a rare word)"
    for word in "ATE RATS ARTS NOTES ONES TONS MILES LIES TEAMS LINES TIES FRIED PARENTS PLATES PARTS EATS TRAPS TAPES EARS PENS PANTS SPENT SENT TEARS SLEPT LETS TALES".split()
}
WORD_NOTES.update({
    "ARTS": "plural/multiple senses of ART; confirm early-level vocabulary",
    "PANT": "ordinary verb meaning breathe rapidly; less basic, review",
    "RANT": "ordinary noun/verb; less basic, review",
    "DINE": "ordinary but more formal than EAT; review",
    "TAME": "less basic than CAT/TOP; ordinary English adjective/verb",
    "DINER": "ordinary English word; regional meaning may need review",
    "LENT": "past form of LEND; also a proper-name homograph, review sense",
})
FAMILIES = (
    {"EAT", "ATE", "EATS"}, {"LIE", "LIES"}, {"MILE", "MILES"},
    {"PARENT", "PARENTS"}, {"LET", "LETS"}, {"TEAM", "TEAMS"},
)
INTRO_VOCABULARY = {
    "STAR": {"STAR", "ART", "RAT"},
    "CARE": {"CARE", "RACE", "CAR", "EAR"},
    "TEAM": {"TEAM", "MEAT", "MATE", "TAME"},
    "PLANT": {"PLANT", "PLAN", "PAN", "TAP"},
    "TRAIN": {"TRAIN", "RAIN", "AIR", "RAT", "ART"},
}
LEVEL_AVOID = {
    "PLANET": {"LENT"}, "LISTEN": {"LETS"},
    "FRIEND": {"DINER", "DINE"}, "PARENTS": {"PARENT"},
}


def read_words(path: Path) -> set[str]:
    words = {line.strip() for line in path.read_text(encoding="utf-8").splitlines()
             if line.strip() and not line.startswith("#")}
    if any(not re.fullmatch(r"[A-Z]{3,7}", word) for word in words):
        raise ValueError(f"Invalid English entry in {path}")
    return words


def portrait(placed: list[Placement]) -> list[Placement]:
    """Transpose only, preserving word direction and all placement rules."""
    m = metrics(placed)
    if m["width"] <= m["height"]:
        return placed
    return [Placement(p.word, p.col, p.row,
                      "down" if p.direction == "across" else "across") for p in placed]


def difficulty(letters: str, placed: list[Placement]) -> float:
    m = metrics(placed)
    average = sum(len(p.word) for p in placed) / len(placed)
    return round(8 * (len(letters) - 3) + 3 * (len(placed) - 2)
                 + .15 * m["width"] * m["height"] + .7 * average
                 - .4 * m["crossings"], 2)


def check_level(item: dict, game: set[str], recognition: set[str], excluded: set[str]):
    placed, letters = item["placements"], item["letters"]
    assert validate(placed), f"Crossword validation: {letters}"
    for p in placed:
        assert p.word in game and p.word in recognition
        assert p.word not in excluded
        assert not (Counter(p.word) - Counter(letters))
    for index, p in enumerate(placed):
        for other in placed[index + 1:]:
            assert len(set(p.cells()) & set(other.cells())) <= 1


def build():
    game = read_words(DICTIONARY / "game_words_en.txt")
    recognition = read_words(DICTIONARY / "recognition_words_en.txt")
    excluded = read_words(DICTIONARY / "exclude_en.txt")
    reviewed = sorted((COMMON & game) - excluded)
    absent = sorted(COMMON - game)
    rng = random.Random(RANDOM_SEED)
    used_words: Counter = Counter()
    selected = []
    for seed_word, target in PLAN:
        assert seed_word in game and seed_word in reviewed
        letters = "".join(sorted(seed_word))
        possible = possible_words(letters, reviewed)
        if seed_word in INTRO_VOCABULARY:
            possible = [word for word in possible if word in INTRO_VOCABULARY[seed_word]]
        possible = [word for word in possible if word not in LEVEL_AVOID.get(seed_word, set())]
        all_possible = possible_words(letters, sorted(game - excluded))
        def quality(placed):
            return (score(placed) + 5 * sum(len(p.word) for p in placed)
                    - 14 * sum(used_words[p.word] for p in placed))
        layouts = []
        for _ in range(8):
            placed = search(possible, seed_word, rng, attempts=4,
                            max_words=target, max_span=9, score_fn=quality)
            if placed and len(placed) == target:
                layouts.append(portrait(placed))
        if not layouts:
            raise RuntimeError(f"No {target}-word layout for {seed_word}")
        placed = max(layouts, key=quality)
        item = {"seed": seed_word, "letters": letters, "placements": placed,
                "potential": len(all_possible), "reviewed_potential": len(possible),
                "difficulty": difficulty(letters, placed)}
        check_level(item, game, recognition, excluded)
        selected.append(item)
        used_words.update(p.word for p in placed)
        print(seed_word, len(placed), metrics(placed), flush=True)
    # Keep the requested letter-count bands; order equal-size/count puzzles by
    # the same transparent difficulty heuristic instead of their seed spelling.
    selected.sort(key=lambda item: (len(item["letters"]), len(item["placements"]), item["difficulty"]))
    signatures = [item["letters"] for item in selected]
    assert len(set(signatures)) == 20
    for previous, current in zip(selected, selected[1:]):
        assert current["difficulty"] >= previous["difficulty"], "Difficulty regression"
        assert current["difficulty"] - previous["difficulty"] <= 14, "Difficulty jump"
        a, b = metrics(previous["placements"]), metrics(current["placements"])
        assert abs(a["width"] - b["width"]) <= 2, "Width jump"
        assert abs(a["height"] - b["height"]) <= 2, "Height jump"
        assert len(current["placements"]) - len(previous["placements"]) <= 1
    for index, item in enumerate(selected):
        assert (3 + index // 5) <= len(item["letters"]) <= (4 + index // 5)
    write(selected, game, recognition, excluded, absent)


def write(selected, game, recognition, excluded, absent):
    OUTPUT.mkdir(parents=True, exist_ok=True)
    levels, cards, report = [], [], []
    unique_words = {p.word for item in selected for p in item["placements"]}
    report.extend([
        "КроссСлов — английская экспериментальная кампания: 20 уровней",
        f"Seed: {RANDOM_SEED}; game dictionary: {len(game)}; recognition: {len(recognition)}; excludes: {len(excluded)}",
        "Движок: существующие crossword.search / validate / can_place; generator.possible_words; scoring.metrics / score.",
        "Русская нормализация не вызывается. Русские данные и Flutter не изменяются.",
        "Отбор качества: вручную просмотренная общеупотребительная подвыборка игрового словаря; wordfreq и внешние частоты не используются.",
        "Для вводных наборов дополнительно выбраны конкретные простые слова; PANT/LENT/DINER и некоторые повторы основ избегаются локально без изменения словарей.",
        "В каждом уровне seed использует все буквы набора. Количество слов растёт 2→7; размеры ограничены 9 клетками по стороне.",
        "Difficulty — относительная эвристика, не результат тестирования на игроках:",
        "8*(letters-3) + 3*(words-2) + .15*area + .7*average_word_length - .4*crossings.",
        "Проверки: dictionary / recognition / multiplicity / connected / adjacency / conflicts / pair crossings / excludes / unique sets: PASS.",
        "Прогрессия: score не убывает, шаг <=14; изменение ширины/высоты <=2; прирост слов <=1: PASS.",
        f"Уникальных использованных слов: {len(unique_words)}.",
        f"Максимальный шаг difficulty: {max(b['difficulty'] - a['difficulty'] for a, b in zip(selected, selected[1:])):.2f}.",
        "HTML: статическая структура проверяется test_english_preview.py; визуальная проверка браузером не выполнена — политика браузера запрещает file://.",
        "Слово может повторяться между уровнями; при выборе действует мягкий штраф за повтор. Letter Sets не повторяются.",
        "Ручные флаги обозначают словоформы/многозначность, а не подтверждённую ошибку.",
        "", "LEVEL | LETTER SET | WORDS | GRID (width×height) | CROSSINGS | DIFFICULTY | WORD LIST",
    ])
    for number, item in enumerate(selected, 1):
        placed = item["placements"]
        m = metrics(placed)
        cells, owners = board(placed)
        min_r, min_c, max_r, max_c = bounds(cells)
        notes = {p.word: WORD_NOTES[p.word] for p in placed if p.word in WORD_NOTES}
        used = {p.word for p in placed}
        for family in FAMILIES:
            related = used & family
            if len(related) > 1:
                for word in sorted(related):
                    notes[word] = notes.get(word, "") + (
                        "; " if word in notes else ""
                    ) + "same word family in this grid: " + ", ".join(sorted(related))
        level = {"id": number, "letters": list(item["letters"]),
                 "words": [{"text": p.word, "row": p.row - min_r, "col": p.col - min_c,
                            "direction": p.direction} for p in placed],
                 "preview": {"seed": item["seed"], "wordCount": len(placed),
                             "width": m["width"], "height": m["height"],
                             "crossings": m["crossings"], "difficultyScore": item["difficulty"],
                             "wordPotential": item["potential"], "reviewedPotential": item["reviewed_potential"],
                             "review": notes}}
        levels.append(level)
        words = ", ".join(p.word for p in placed)
        report.append(f"{number:02d} | {item['letters']} | {len(placed)} | {m['width']}×{m['height']} | {m['crossings']} | {item['difficulty']:.2f} | {words}")
        report.append("\n".join(" ".join(cells.get((r, c), ".") for c in range(min_c, max_c + 1)) for r in range(min_r, max_r + 1)))
        if notes:
            report.append("REVIEW: " + "; ".join(f"{word}: {reason}" for word, reason in notes.items()))
        report.append("")
        grid_cells = []
        for row in range(min_r, max_r + 1):
            for col in range(min_c, max_c + 1):
                char = cells.get((row, col), "")
                owning_words = " ".join(placed[i].word for i in owners.get((row, col), []))
                cls = "cell" + (" empty" if not char else " cross" if len(owners[(row,col)]) == 2 else "")
                grid_cells.append(f'<div class="{cls}" data-words="{owning_words}">{char}</div>')
        buttons = " ".join(f'<button data-word="{p.word}" title="{escape(notes.get(p.word,"Common word"))}">{p.word}{" ⚑" if p.word in notes else ""}</button>' for p in placed)
        cards.append(f'<section><h2>{number:02d} · {item["letters"]}</h2><p>{len(placed)} слов · {m["width"]}×{m["height"]} · {m["crossings"]} пересечений · difficulty {item["difficulty"]:.2f}</p><div class="grid" style="--cols:{m["width"]}">{"".join(grid_cells)}</div><div class="words">{buttons}</div><p>Word potential: {item["potential"]}; после ручного отбора: {item["reviewed_potential"]}</p><details><summary>Размещения / ручная проверка</summary><pre>{escape(json.dumps(level["words"], indent=2))}</pre><p>{escape("; ".join(f"{word}: {reason}" for word, reason in notes.items()) or "Нет дополнительных флагов")}</p></details></section>')
    report.extend([
        "ОЦЕНКА КАЧЕСТВА",
        "Первые уровни используют ACT/CAT, POT/TOP, EAT/ATE/TEA и другие базовые слова. Подтверждённо редких слов не выбрано.",
        "Словоформы допустимы в эксперименте: ATE, множественные числа и формы глаголов помечены для ручного решения.",
        "В сетке SMILE остаётся повтор одной основы (например LIE/LIES либо MILE/MILES): из шести доступных базовых слов нужно выбрать пять. Он помечен для ручной проверки.",
        "Отсутствуют реальные частотные оценки, поэтому commonness является редакционной оценкой, а difficulty требует playtest.",
        "Базовый словарь имеет пробелы: обычные слова ANT, LIME, PAINTER и др. отсутствуют. Мы не добавляли их обходным путём.",
        "Просмотренные кандидаты, отсутствующие в game dictionary: " + ", ".join(absent),
        "ИТОГ: 20/20 валидны; prohibited/excluded words used: 0; duplicate Letter Sets: 0.",
    ])
    (OUTPUT / "levels_en_preview.json").write_text(json.dumps(levels, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (OUTPUT / "report_en.txt").write_text("\n".join(report) + "\n", encoding="utf-8")
    css = 'body{font:16px system-ui;background:#eef2f6;color:#162238;margin:20px}main{max-width:1200px;margin:auto}.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,360px),1fr));gap:20px}section{background:white;border-radius:14px;padding:20px;box-shadow:0 3px 14px #14263a12}h2{margin-top:0}.grid{display:grid;grid-template-columns:repeat(var(--cols),30px);gap:2px;margin:18px 0}.cell{height:30px;box-sizing:border-box;border:1px solid #8292a3;text-align:center;line-height:28px;font-weight:750;border-radius:3px}.cross{background:#dceeff}.empty{border:0;background:transparent}.cell.active{background:#ffe099;border-color:#d88b00}button{font:inherit;border:1px solid #b3c3d5;border-radius:6px;background:#f5f8fc;padding:5px 8px;margin:3px;cursor:pointer}button.active{background:#ffe099}p{line-height:1.5}pre{white-space:pre-wrap;font-size:12px}details{margin-top:10px}header{padding-bottom:18px}'
    js = "document.querySelectorAll('button[data-word]').forEach(b=>b.onclick=()=>{const s=b.closest('section'),w=b.dataset.word;const on=!b.classList.contains('active');s.querySelectorAll('.active').forEach(x=>x.classList.remove('active'));if(on){b.classList.add('active');s.querySelectorAll('.cell').forEach(c=>{if(c.dataset.words.split(' ').includes(w))c.classList.add('active')})}});"
    html = f'<!doctype html><html lang="ru"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>КроссСлов · English 20 · Experiment</title><style>{css}</style><main><header><h1>English · 20 тестовых уровней</h1><p>Эксперимент, к Flutter не подключён. Нажмите слово для подсветки его клеток. Синие клетки — пересечения; ⚑ — редакционная проверка словоформы или смысла.</p><p>Все 20 сеток прошли проверки. Difficulty — относительная эвристика. Русские данные сохранены.</p></header><div class="cards">{"".join(cards)}</div></main><script>{js}</script></html>'
    (OUTPUT / "preview_en.html").write_text(html, encoding="utf-8")
    print(f"Saved {len(levels)} levels to {OUTPUT}", flush=True)


if __name__ == "__main__":
    build()
