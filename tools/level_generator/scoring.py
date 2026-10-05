"""Experimental weights are centralized here for easy POC tuning."""

from __future__ import annotations

from crossword import board, bounds

WEIGHTS = {
    "word": 100.0,
    "square": 24.0,
    "density": 20.0,
    "crossing": 9.0,
    "area": 1.5,
    "dangling": 4.0,
    "elongation": 3.0,
    "extra_letter": 3.0,
}


def metrics(placements):
    cells, owners = board(placements)
    min_r, min_c, max_r, max_c = bounds(cells)
    width, height = max_c - min_c + 1, max_r - min_r + 1
    occupied = len(cells)
    crossings = sum(len(pair) == 2 for pair in owners.values())
    crossing_by_word = [0] * len(placements)
    for pair in owners.values():
        if len(pair) == 2:
            for i in pair:
                crossing_by_word[i] += 1
    dangling = sum(n == 1 for n in crossing_by_word) if len(placements) > 2 else 0
    return {
        "width": width, "height": height, "occupied": occupied,
        "density": occupied / (width * height),
        "square": min(width, height) / max(width, height),
        "crossings": crossings, "dangling": dangling,
    }


def score(placements):
    m = metrics(placements)
    return round(
        len(placements) * WEIGHTS["word"]
        + m["square"] * WEIGHTS["square"]
        + m["density"] * WEIGHTS["density"]
        + m["crossings"] * WEIGHTS["crossing"]
        + sum(max(0, len(p.word) - 3) for p in placements) * WEIGHTS["extra_letter"]
        - m["width"] * m["height"] * WEIGHTS["area"]
        - m["dangling"] * WEIGHTS["dangling"]
        - (m["width"] - m["height"]) ** 2 * WEIGHTS["elongation"], 3
    )
