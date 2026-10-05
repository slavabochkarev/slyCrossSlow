"""Human-readable reports; deliberately separate from Flutter level assets."""

from __future__ import annotations

from collections import Counter
from html import escape
from pathlib import Path
import json

from crossword import board, bounds
from scoring import metrics, score


def grid(placements):
    cells, owners = board(placements)
    min_r, min_c, max_r, max_c = bounds(cells)
    return [[(cells.get((r, c), "·"), len(owners.get((r, c), [])) == 2) for c in range(min_c, max_c + 1)] for r in range(min_r, max_r + 1)]


def model(candidate):
    placed = candidate["placements"]
    words = candidate["possible"]
    m = metrics(placed)
    min_r, min_c, _, _ = bounds(board(placed)[0])
    return {
        "letters": candidate["letters"], "seed": candidate["seed"],
        "potential": {str(n): sum(len(w) == n for w in words) for n in range(3, 8)},
        "possible": words, "used": [p.word for p in placed],
        "placements": [{"word": p.word, "row": p.row - min_r, "col": p.col - min_c, "direction": p.direction} for p in placed],
        "grid": [[letter for letter, _ in row] for row in grid(placed)],
        "metrics": m, "score": score(placed),
    }


def write(candidates, output_dir: Path, config: dict):
    output_dir.mkdir(parents=True, exist_ok=True)
    data = [model(c) for c in candidates]
    (output_dir / "candidates.json").write_text(json.dumps({"config": config, "candidates": data}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    text_parts = []
    cards = []
    for i, item in enumerate(data, 1):
        m = item["metrics"]
        potential = "\n".join(f"{n} letters: {item['potential'][str(n)]}" for n in range(3, 8))
        lines = [" ".join(row) for row in item["grid"]]
        text_parts.append(f"LEVEL CANDIDATE {i:02d}\nLETTER SET: {' '.join(item['letters'])}\nSEED: {item['seed']}\nWORD POTENTIAL\n{potential}\nTOTAL: {len(item['possible'])}\nALL POSSIBLE WORDS\n{', '.join(item['possible'])}\nCROSSWORD WORDS\n{', '.join(item['used'])}\nUSED: {len(item['used'])} / {len(item['possible'])}\nGRID\n" + "\n".join(lines) + f"\nSIZE: {m['width']} × {m['height']}\nOCCUPIED CELLS: {m['occupied']}\nDENSITY: {m['density']:.3f}\nCROSSINGS: {m['crossings']}\nSQUARE SCORE: {m['square']:.3f}\nDANGLING WORDS: {m['dangling']}\nTOTAL SCORE: {item['score']:.3f}")
        html_grid = "".join("<div class='cell %s'>%s</div>" % ("cross" if cross else "empty" if char == "·" else "full", "" if char == "·" else escape(char)) for row in grid(candidates[i - 1]["placements"]) for char, cross in row)
        cards.append(f"<section class='card'><h2>Кандидат {i:02d} · {escape(' '.join(item['letters']))}</h2><p>Основа: <b>{escape(item['seed'])}</b> · Возможных слов: {len(item['possible'])} · Использовано: {len(item['used'])}</p><div class='grid' style='--columns:{m['width']}'>{html_grid}</div><p class='words'><b>Слова сетки:</b> {escape(', '.join(item['used']))}</p><p class='stats'>{m['width']} × {m['height']} · клеток {m['occupied']} · плотность {m['density']:.3f} · пересечений {m['crossings']} · квадратность {m['square']:.3f} · score {item['score']:.3f}</p><details><summary>Все возможные слова ({len(item['possible'])})</summary><p>{escape(', '.join(item['possible']))}</p></details></section>")
    (output_dir / "generator_output.txt").write_text("\n\n".join(text_parts) + "\n", encoding="utf-8")
    css = "body{font:16px system-ui,sans-serif;background:#f5f5f3;color:#222;margin:24px}main{max-width:1100px;margin:auto}.card{background:white;border:1px solid #ddd;border-radius:10px;margin:20px 0;padding:20px}.grid{display:grid;grid-template-columns:repeat(var(--columns),32px);gap:2px;margin:18px 0}.cell{width:32px;height:32px;box-sizing:border-box;text-align:center;line-height:30px;font-weight:700;border:1px solid #888;background:#fff}.cell.empty{border:0;background:transparent}.cell.cross{background:#d9ebff}.words{line-height:1.6}.stats{color:#555}details{line-height:1.6}"
    html = "<!doctype html><html lang='ru'><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>КроссСлов · POC генератора</title><style>" + css + "</style><main><h1>КроссСлов · кандидаты уровней</h1><p>Предпросмотр для ручной оценки. Синие клетки — пересечения.</p>" + "".join(cards) + "</main></html>"
    (output_dir / "preview.html").write_text(html, encoding="utf-8")
