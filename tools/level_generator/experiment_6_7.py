"""Second POC experiment: ten six-letter and ten seven-letter sets.

This file deliberately leaves generator.py and its output/ directory untouched.
"""

from __future__ import annotations

import argparse
from collections import Counter
from html import escape
import json
from pathlib import Path
import random

from crossword import Placement, options, validate
from dictionary import DATA, ROOT, load_words
from generator import letter_sets, possible_words
from preview import grid, model
from scoring import metrics, score

DEFAULT_OUTPUT = ROOT / "experiment_6_7_output"


def geometry_score(placements: list[Placement]) -> float:
    """Compare grids of different word counts without the old 100×words term."""
    m = metrics(placements)
    count = len(placements)
    area = m["width"] * m["height"]
    return round(
        100 * m["square"]
        + 80 * m["density"]
        + 20 * m["crossings"] / count
        - 2 * area / count
        - 10 * m["dangling"] / count,
        3,
    )


def search_per_count(words: list[str], seed_word: str, rng: random.Random, attempts: int, max_span: int):
    best: dict[int, list[Placement]] = {}
    for _ in range(attempts):
        placed = [Placement(seed_word, 0, 0, rng.choice(("across", "down")))]
        unused = [w for w in words if w != seed_word]
        rng.shuffle(unused)
        while len(placed) < 11:
            choices = []
            for word in unused:
                for p in options(placed, word, max_span):
                    choices.append((score(placed + [p]), rng.random(), p))
            if not choices:
                break
            choices.sort(key=lambda item: (item[0], item[1]), reverse=True)
            chosen = rng.choice(choices[: min(5, len(choices))])[2]
            placed.append(chosen)
            unused.remove(chosen.word)
            count = len(placed)
            if count >= 6 and validate(placed):
                current = best.get(count)
                if current is None or geometry_score(placed) > geometry_score(current):
                    best[count] = placed.copy()
    return best


def ranked_sets(words: list[str], size: int):
    ranked = []
    for letters, seeds in letter_sets(words).items():
        if len(letters) != size:
            continue
        possible = possible_words(letters, words)
        by_length = Counter(map(len, possible))
        if len(possible) < 8 or sum(by_length[n] for n in (4, 5, 6)) < 3:
            continue
        potential_rank = len(possible) + 1.5 * by_length[4] + by_length[5] + 0.5 * by_length[6]
        ranked.append((potential_rank, letters, sorted(seeds)[0], possible))
    ranked.sort(key=lambda x: (-x[0], x[1]))
    return ranked


def _questionable() -> set[str]:
    return {line.strip() for line in (DATA / "questionable_words.txt").read_text(encoding="utf-8").splitlines() if line.strip() and not line.startswith("#")}


def write_reports(chosen, all_records, config, output_dir: Path):
    output_dir.mkdir(parents=True, exist_ok=True)
    questionable = _questionable()
    data = []
    for record in chosen:
        item = model(record)
        item["geometry_score"] = geometry_score(record["placements"])
        item["available_counts"] = sorted(record["per_count"])
        item["questionable_used"] = sorted(set(item["used"]) & questionable)
        data.append(item)

    archive = []
    for record in all_records:
        archive.append({
            "letters": record["letters"], "seed": record["seed"],
            "possible": record["possible"],
            "best_by_word_count": {str(n): {**model({**record, "placements": placed}), "geometry_score": geometry_score(placed)} for n, placed in sorted(record["per_count"].items())},
        })
    (output_dir / "per_count_best.json").write_text(json.dumps({"config": config, "letter_sets": archive}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (output_dir / "candidates.json").write_text(json.dumps({"config": config, "candidates": data}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    cards, text_cards, clean = [], [], []
    for index, item in enumerate(data, 1):
        m = item["metrics"]
        suspect = item["questionable_used"]
        if m["square"] >= 0.85 and len(item["used"]) >= 7 and not suspect:
            clean.append(index)
        potential = " · ".join(f"{n}: {item['potential'][str(n)]}" for n in range(3, 8) if item["potential"][str(n)])
        rows = grid(chosen[index - 1]["placements"])
        cells = "".join(f"<span class='cell {'cross' if cross else 'empty' if char == '·' else 'full'}'>{'' if char == '·' else escape(char)}</span>" for row in rows for char, cross in row)
        group = "6 букв" if len(item["letters"]) == 6 else "7 букв"
        cards.append(f"<article class='card' id='candidate-{index}'><h2>{index:02d}. {group} · {escape(' '.join(item['letters']))}</h2><p><b>Основа:</b> {escape(item['seed'])} · <b>Word Potential:</b> {len(item['possible'])} ({potential})</p><p><b>Used Words ({len(item['used'])}):</b> {escape(', '.join(item['used']))}</p><div class='grid' style='--columns:{m['width']}'>{cells}</div><p><b>Size:</b> {m['width']} × {m['height']} · <b>Density:</b> {m['density']:.3f} · <b>Crossings:</b> {m['crossings']} · <b>Square Score:</b> {m['square']:.3f} · <b>Geometry:</b> {item['geometry_score']:.3f}</p><p class='small'>Лучшие варианты сохранены для {', '.join(map(str, item['available_counts']))} слов. Пометки слов: {escape(', '.join(suspect)) if suspect else 'нет в текущем списке'}.</p><details><summary>Все возможные слова</summary>{escape(', '.join(item['possible']))}</details></article>")
        grid_text = "\n".join(" ".join(char for char, _ in row) for row in rows)
        text_cards.append(f"CANDIDATE {index:02d} / {group}\nLETTER SET: {' '.join(item['letters'])}\nSEED: {item['seed']}\nWORD POTENTIAL: {potential} · TOTAL {len(item['possible'])}\nALL POSSIBLE: {', '.join(item['possible'])}\nUSED WORDS ({len(item['used'])}): {', '.join(item['used'])}\nGRID\n{grid_text}\nSIZE: {m['width']} × {m['height']} · DENSITY: {m['density']:.3f} · CROSSINGS: {m['crossings']} · SQUARE SCORE: {m['square']:.3f} · GEOMETRY: {item['geometry_score']:.3f}\nQUESTIONABLE USED: {', '.join(suspect) if suspect else 'none'}")
    links = " ".join(f"<a href='#candidate-{i}'>#{i:02d}</a>" for i in clean) or "Нет кандидатов по условиям"
    css = "body{font:16px system-ui,sans-serif;background:#f2f3f5;color:#1b2430;margin:24px}main{max-width:1100px;margin:auto}.card{background:white;border:1px solid #ccd2d8;border-radius:10px;padding:20px;margin:20px 0}.grid{display:grid;grid-template-columns:repeat(var(--columns),32px);gap:2px;margin:20px 0}.cell{box-sizing:border-box;width:32px;height:32px;line-height:30px;text-align:center;font-weight:700;border:1px solid #8b96a3;background:white}.cell.empty{border:0;background:transparent}.cell.cross{background:#cde6fa}.small{color:#52606d}a{display:inline-block;margin:2px 6px 2px 0}details{line-height:1.6}"
    html = "<!doctype html><html lang='ru'><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>КроссСлов · эксперимент 6 и 7 букв</title><style>" + css + "</style><main><h1>КроссСлов · 6 и 7 букв</h1><p>По 10 кандидатов каждой длины. Лучший вариант каждой сетки выбран среди сохранённых вариантов на 6–11 слов по геометрии.</p><h2>Предварительный отбор</h2><p>Square Score ≥ 0.85, не менее 7 слов, без слов из текущего списка сомнительных: " + links + ". Редакторская проверка всё ещё необходима.</p>" + "".join(cards) + "</main></html>"
    (output_dir / "preview.html").write_text(html, encoding="utf-8")
    summary = "PRELIMINARY SHORTLIST (square_score >= 0.85, used >= 7, no flagged words)\n" + (", ".join(f"{i:02d}" for i in clean) or "none") + "\n\n" + "\n\n".join(text_cards) + "\n"
    (output_dir / "generator_output.txt").write_text(summary, encoding="utf-8")
    return clean


def run(args):
    words = load_words()
    rng = random.Random(args.seed)
    all_records, chosen = [], []
    eligible_counts = {}
    for size in (6, 7):
        ranked = ranked_sets(words, size)
        eligible_counts[size] = len(ranked)
        group = []
        for _, letters, seed_word, possible in ranked[: args.set_limit]:
            per_count = search_per_count(possible, seed_word, rng, args.attempts, args.max_span)
            if not per_count:
                continue
            best_count = max(per_count, key=lambda n: (geometry_score(per_count[n]), n))
            record = {"letters": letters, "seed": seed_word, "possible": possible, "placements": per_count[best_count], "per_count": per_count}
            all_records.append(record)
            group.append(record)
        group.sort(key=lambda x: (-geometry_score(x["placements"]), -len(x["placements"]), x["letters"]))
        if len(group) < 10:
            raise RuntimeError(f"Only {len(group)} candidates for {size}-letter sets; raise --set-limit")
        chosen.extend(group[:10])
    config = {"seed": args.seed, "set_limit_per_size": args.set_limit, "attempts_per_set": args.attempts, "max_span": args.max_span, "eligible_letter_sets": eligible_counts, "searched_letter_sets": len(all_records), "selection": "best geometry for each word count 6..11, then best geometry per letter set, top 10 per size"}
    clean = write_reports(chosen, all_records, config, args.output)
    print(f"Saved {len(chosen)} candidates: 10 six-letter + 10 seven-letter; preliminary shortlist: {', '.join(map(str, clean)) or 'none'}")
    for index, record in enumerate(chosen, 1):
        m = metrics(record["placements"])
        print(f"{index:02d} {record['letters']} {record['seed']} potential={len(record['possible'])} used={len(record['placements'])} size={m['width']}x{m['height']} square={m['square']:.3f} geometry={geometry_score(record['placements']):.3f}")


def render_saved(output_dir: Path):
    """Update editorial flags and previews without repeating the layout search."""
    saved = json.loads((output_dir / "per_count_best.json").read_text(encoding="utf-8"))
    selection = json.loads((output_dir / "candidates.json").read_text(encoding="utf-8"))
    all_records = []
    for item in saved["letter_sets"]:
        per_count = {int(n): [Placement(**p) for p in variant["placements"]] for n, variant in item["best_by_word_count"].items()}
        all_records.append({"letters": item["letters"], "seed": item["seed"], "possible": item["possible"], "per_count": per_count})
    by_letters = {record["letters"]: record for record in all_records}
    chosen = []
    for item in selection["candidates"]:
        record = by_letters[item["letters"]].copy()
        record["placements"] = [Placement(**p) for p in item["placements"]]
        chosen.append(record)
    clean = write_reports(chosen, all_records, saved["config"], output_dir)
    print(f"Re-rendered 20 saved candidates; preliminary shortlist: {', '.join(map(str, clean)) or 'none'}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--set-limit", type=int, default=40)
    parser.add_argument("--attempts", type=int, default=12)
    parser.add_argument("--max-span", type=int, default=11)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--report-only", action="store_true", help="re-render existing candidates after editing questionable_words.txt")
    args = parser.parse_args()
    if min(args.set_limit, args.attempts, args.max_span) < 1:
        parser.error("limits must be positive")
    if args.report_only:
        render_saved(args.output)
    else:
        run(args)


if __name__ == "__main__":
    main()
