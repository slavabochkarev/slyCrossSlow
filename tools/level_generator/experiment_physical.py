"""Independent search experiment bounded by the measured 360x800 Game Screen."""

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
from scoring import metrics

MAX_WIDTH = 8
MAX_HEIGHT = 9
MIN_WORDS = 6
MAX_WORDS = 14
MAX_SHORT_WORDS = 4
CELL_360 = {(width, height): min(312 / width, 334 / height) for width in range(1, 9) for height in range(1, 10)}
DEFAULT_OUTPUT = ROOT / "experiment_physical_output"


def flagged_words() -> set[str]:
    return {
        line.strip() for line in (DATA / "questionable_words.txt").read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.startswith("#")
    }


def fits(placements: list[Placement]) -> bool:
    m = metrics(placements)
    return m["width"] <= MAX_WIDTH and m["height"] <= MAX_HEIGHT


def quality(placements: list[Placement]) -> float:
    """Source-reviewed five-letter words and longer words beat short fillers."""
    return sum(12 if len(p.word) == 5 else 8 if len(p.word) >= 6 else 4 if len(p.word) == 4 else 0 for p in placements)


def score(placements: list[Placement]) -> float:
    m = metrics(placements)
    area = m["width"] * m["height"]
    # Lexical rejection is a hard gate before scoring. No square==1 bonus.
    return round(
        100 * len(placements)
        + quality(placements)
        + 6 * m["crossings"]
        + 20 * m["density"]
        - .55 * area
        - 5 * m["dangling"]
        + 2 * m["square"],
        3,
    )


def search_set(words: list[str], seeds: list[str], rng: random.Random, attempts: int) -> dict[int, list[Placement]]:
    best: dict[int, list[Placement]] = {}
    for attempt in range(attempts):
        seed = seeds[attempt % len(seeds)]
        placed = [Placement(seed, 0, 0, rng.choice(("across", "down")))]
        unused = [word for word in words if word != seed]
        rng.shuffle(unused)
        while len(placed) < MAX_WORDS:
            choices = []
            seven_count = sum(len(p.word) == 7 for p in placed)
            short_count = sum(len(p.word) == 3 for p in placed)
            for word in unused:
                if len(word) == 7 and seven_count >= 2:
                    continue
                if len(word) == 3 and short_count >= MAX_SHORT_WORDS:
                    continue
                for candidate in options(placed, word, MAX_HEIGHT):
                    trial = placed + [candidate]
                    if fits(trial):
                        choices.append((score(trial), rng.random(), candidate))
            if not choices:
                break
            choices.sort(key=lambda item: (item[0], item[1]), reverse=True)
            chosen = rng.choice(choices[:min(6, len(choices))])[2]
            placed.append(chosen)
            unused.remove(chosen.word)
            count = len(placed)
            if count >= MIN_WORDS and validate(placed):
                current = best.get(count)
                if current is None or score(placed) > score(current):
                    best[count] = placed.copy()
    return best


def ranked_sets(words: list[str], size: int):
    groups = letter_sets(words)
    result = []
    for letters, seeds in groups.items():
        if len(letters) != size:
            continue
        potential = possible_words(letters, words)
        counts = Counter(map(len, potential))
        if len(potential) < 8 or sum(counts[n] for n in (4, 5, 6)) < 3:
            continue
        rank = len(potential) + 1.5 * counts[4] + counts[5] + .5 * counts[6]
        result.append((rank, letters, sorted(seeds), potential))
    return sorted(result, key=lambda item: (-item[0], item[1]))


def _card(item: dict, index: int) -> str:
    m = item["metrics"]
    cells = "".join(
        f"<span class='cell {'cross' if cross else 'empty' if char == '·' else 'full'}'>{'' if char == '·' else escape(char)}</span>"
        for row in item["display_grid"] for char, cross in row
    )
    potential = " · ".join(f"{n}: {item['potential'][str(n)]}" for n in range(3, 8) if item["potential"][str(n)])
    return (
        f"<article class='card' id='candidate-{index}'><h2>{index:02d}. {len(item['letters'])} букв · {escape(' '.join(item['letters']))}</h2>"
        f"<p><b>Letter Set:</b> {escape(item['letters'])} · <b>Word Potential:</b> {len(item['possible'])} ({potential}) "
        f"· <b>Used:</b> {len(item['used'])}</p><div class='grid' style='--columns:{m['width']}'>{cells}</div>"
        f"<p><b>Grid size:</b> {m['width']}×{m['height']} · <b>Density:</b> {m['density']:.3f} "
        f"· <b>Crossings:</b> {m['crossings']} · <b>cell 360×800:</b> {item['cell_360']:.1f} px "
        f"· <b>score:</b> {item['score']:.3f}</p><p><b>Все использованные слова:</b> {escape(', '.join(item['used']))}</p>"
        f"<p class='small'>Качество слов: {item['quality']:.0f}; ветвей с одним пересечением: {m['dangling']}; "
        f"квадратность: {m['square']:.3f}. Варианты на {', '.join(map(str, item['available_counts']))} слов.</p></article>"
    )


def write(records: list[dict], selected: list[dict], config: dict, output: Path):
    output.mkdir(parents=True, exist_ok=True)
    archived = []
    for record in records:
        variants = {}
        for count, placements in sorted(record["per_count"].items()):
            variant = model({**record, "placements": placements})
            variant["score"] = score(placements)
            variant["quality"] = quality(placements)
            variants[str(count)] = variant
        archived.append({"letters": record["letters"], "seeds": record["seeds"], "possible": record["possible"], "best_by_word_count": variants})
    (output / "per_count_best.json").write_text(json.dumps({"config": config, "letter_sets": archived}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    items = []
    for record in selected:
        placements = record["placements"]
        item = model(record)
        item["score"] = score(placements)
        item["quality"] = quality(placements)
        item["cell_360"] = round(CELL_360[(item["metrics"]["width"], item["metrics"]["height"])], 3)
        item["available_counts"] = sorted(record["per_count"])
        item["display_grid"] = grid(placements)
        items.append(item)
    clean = [{k: v for k, v in item.items() if k != "display_grid"} for item in items]
    (output / "candidates.json").write_text(json.dumps({"config": config, "candidates": clean}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    previous = {
        item["letters"]: item
        for item in json.loads((ROOT / "experiment_6_7_output/candidates.json").read_text(encoding="utf-8"))["candidates"]
    }
    examples = []
    for width, height in ((6, 7), (7, 8), (8, 9)):
        matches = [
            (item, variant) for item in archived for variant in item["best_by_word_count"].values()
            if (variant["metrics"]["width"], variant["metrics"]["height"]) == (width, height)
        ]
        if not matches:
            continue
        source, variant = max(matches, key=lambda pair: (pair[1]["score"], pair[0]["letters"]))
        old = previous.get(source["letters"])
        examples.append({
            "letters": source["letters"], "grid_size": [width, height],
            "used": variant["used"], "score": variant["score"],
            "cell_360": round(CELL_360[(width, height)], 3),
            "previous_poc": None if old is None else {
                "grid_size": [old["metrics"]["width"], old["metrics"]["height"]],
                "used_count": len(old["used"]),
            },
        })
    (output / "rectangular_examples.json").write_text(json.dumps(examples, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    rectangles = [(i, item) for i, item in enumerate(items, 1) if item["metrics"]["width"] != item["metrics"]["height"]]
    rectangle_links = ", ".join(f"<a href='#candidate-{i}'>#{i:02d} {item['metrics']['width']}×{item['metrics']['height']}</a>" for i, item in rectangles) or "нет"
    example_cards = "".join(
        f"<article class='card'><h3>{example['grid_size'][0]}×{example['grid_size'][1]} · {escape(example['letters'])}</h3>"
        f"<p>Used: {len(example['used'])} · cell 360×800: {example['cell_360']:.1f} px · score: {example['score']:.3f}</p>"
        f"<p>{escape(', '.join(example['used']))}</p>"
        + (f"<p class='small'>Прежний POC для этого Letter Set: {example['previous_poc']['grid_size'][0]}×{example['previous_poc']['grid_size'][1]}, {example['previous_poc']['used_count']} слов.</p>" if example["previous_poc"] else "")
        + "</article>" for example in examples
    )
    css = "body{font:16px system-ui,sans-serif;background:#f2f3f5;color:#1b2430;margin:24px}main{max-width:1100px;margin:auto}.card{background:white;border:1px solid #ccd2d8;border-radius:10px;padding:20px;margin:20px 0}.grid{display:grid;grid-template-columns:repeat(var(--columns),32px);gap:2px;margin:18px 0}.cell{box-sizing:border-box;width:32px;height:32px;line-height:30px;text-align:center;font-weight:700;border:1px solid #8b96a3;background:white}.cell.empty{border:0;background:transparent}.cell.cross{background:#cde6fa}.small{color:#52606d}a{display:inline-block;margin:2px 6px 2px 0}"
    html = ("<!doctype html><html lang='ru'><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'>"
            "<title>КроссСлов · физический лимит</title><style>" + css + "</style><main><h1>КроссСлов · 8×9 физический лимит</h1>"
            "<p>TOP-10 наборов из 6 букв и TOP-10 из 7 букв. В каждой группе сортировка по итоговому качеству уровня. "
            "Сомнительные слова исключены до поиска. Клетка 8×9 на 360×800: 37.1 px.</p>"
            f"<h2>Прямоугольные варианты</h2><p>Лучшие найденные варианты каждого размера, включая те, что не вошли в TOP-20. Сравнение с прежним POC показывает результат разных поисков и не доказывает влияние одного только scoring.</p>{example_cards}"
            f"<p>Прямоугольники в итоговом TOP-20: {rectangle_links}</p>"
            "<h2>TOP-10 · 6 букв</h2>" + "".join(_card(item, i) for i, item in enumerate(items[:10], 1))
            + "<h2>TOP-10 · 7 букв</h2>" + "".join(_card(item, i) for i, item in enumerate(items[10:], 11)) + "</main></html>")
    (output / "preview.html").write_text(html, encoding="utf-8")
    lines = ["Physical limit: width <= 8, height <= 9; 8x9 cell 37.1 px on 360x800; 8x10 cell 33.4 px is excluded."]
    lines.append("RECTANGULAR EXAMPLES\n" + "\n".join(
        f"{item['grid_size'][0]}x{item['grid_size'][1]} {item['letters']} used={len(item['used'])} cell_360={item['cell_360']:.1f} score={item['score']:.3f}"
        for item in examples
    ))
    for i, item in enumerate(items, 1):
        m = item["metrics"]
        lines.append(f"{i:02d} {item['letters']} potential={len(item['possible'])} used={len(item['used'])} grid={m['width']}x{m['height']} density={m['density']:.3f} crossings={m['crossings']} cell_360={item['cell_360']:.1f} score={item['score']:.3f}\nWORDS: {', '.join(item['used'])}\n" + "\n".join(" ".join(char for char, _ in row) for row in item["display_grid"]))
    (output / "generator_output.txt").write_text("\n\n".join(lines) + "\n", encoding="utf-8")


def run(args):
    forbidden = flagged_words()
    words = [word for word in load_words() if word not in forbidden]
    rng = random.Random(args.seed)
    all_records, selected = [], []
    eligible = {}
    for size in (6, 7):
        ranked = ranked_sets(words, size)
        eligible[str(size)] = len(ranked)
        group = []
        for _, letters, seeds, possible in ranked[:args.set_limit]:
            per_count = search_set(possible, seeds, rng, args.attempts)
            if not per_count:
                continue
            count = max(per_count, key=lambda n: (score(per_count[n]), n))
            record = {"letters": letters, "seeds": seeds, "seed": seeds[0], "possible": possible,
                      "placements": per_count[count], "per_count": per_count}
            all_records.append(record)
            group.append(record)
        group.sort(key=lambda record: (-score(record["placements"]), record["letters"]))
        if len(group) < 10:
            raise RuntimeError(f"Only {len(group)} candidates for {size}-letter sets; increase --set-limit")
        selected.extend(group[:10])
    config = {"seed": args.seed, "set_limit_per_size": args.set_limit, "attempts_per_set": args.attempts,
              "max_width": MAX_WIDTH, "max_height": MAX_HEIGHT, "word_range": [MIN_WORDS, MAX_WORDS],
              "max_three_letter_words": MAX_SHORT_WORDS, "max_seven_letter_words": 2,
              "eligible_letter_sets": eligible, "searched_letter_sets": len(all_records),
              "lexical_filter": "data/words.txt minus data/questionable_words.txt; five-letter answers are curated Pyatibukv words",
              "selection": "hard lexical and physical gates, then score: 100*words + quality + 6*crossings + 20*density - .55*area - 5*dangling + 2*square"}
    write(all_records, selected, config, args.output)
    print(f"Saved {len(selected)} candidates; examined {len(all_records)} letter sets; output {args.output}")
    for i, record in enumerate(selected, 1):
        m = metrics(record["placements"])
        print(f"{i:02d} {record['letters']} used={len(record['placements'])} grid={m['width']}x{m['height']} crossings={m['crossings']} score={score(record['placements']):.3f}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seed", type=int, default=20261004)
    parser.add_argument("--set-limit", type=int, default=40)
    parser.add_argument("--attempts", type=int, default=12)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    if min(args.set_limit, args.attempts) < 1:
        parser.error("limits must be positive")
    run(args)


if __name__ == "__main__":
    main()
