"""Bounded constructive search for connected, conventional crossword layouts."""

from __future__ import annotations

from collections import Counter, defaultdict
from dataclasses import dataclass
import random


@dataclass(frozen=True)
class Placement:
    word: str
    row: int
    col: int
    direction: str  # across | down

    def cells(self):
        dr, dc = (0, 1) if self.direction == "across" else (1, 0)
        return [(self.row + i * dr, self.col + i * dc) for i in range(len(self.word))]


def board(placements: list[Placement]):
    cells: dict[tuple[int, int], str] = {}
    owners: dict[tuple[int, int], list[int]] = defaultdict(list)
    for index, placed in enumerate(placements):
        for pos, char in zip(placed.cells(), placed.word):
            if pos in cells and cells[pos] != char:
                raise ValueError("letter conflict")
            cells[pos] = char
            owners[pos].append(index)
    return cells, owners


def bounds(cells):
    rows, cols = zip(*cells)
    return min(rows), min(cols), max(rows), max(cols)


def can_place(placed: list[Placement], candidate: Placement) -> bool:
    if any(p.word == candidate.word for p in placed):
        return False
    existing, owners = board(placed)
    points = candidate.cells()
    dr, dc = (0, 1) if candidate.direction == "across" else (1, 0)
    if (points[0][0] - dr, points[0][1] - dc) in existing:
        return False
    if (points[-1][0] + dr, points[-1][1] + dc) in existing:
        return False
    intersects: Counter = Counter()
    for point, char in zip(points, candidate.word):
        if point in existing:
            if existing[point] != char or len(owners[point]) != 1:
                return False
            other = owners[point][0]
            if placed[other].direction == candidate.direction:
                return False
            intersects[other] += 1
            if intersects[other] > 1:
                return False
        else:
            # Empty cells may not touch a parallel existing word side by side.
            sides = ((point[0] - 1, point[1]), (point[0] + 1, point[1])) if dc else ((point[0], point[1] - 1), (point[0], point[1] + 1))
            if any(side in existing for side in sides):
                return False
    return bool(intersects) if placed else True


def options(placed: list[Placement], word: str, max_span: int) -> list[Placement]:
    cells, owners = board(placed)
    found = set()
    result = []
    for (row, col), char in cells.items():
        for i, letter in enumerate(word):
            if char != letter:
                continue
            for direction in ("across", "down"):
                p = Placement(word, row - (i if direction == "down" else 0), col - (i if direction == "across" else 0), direction)
                key = (p.row, p.col, p.direction)
                if key in found:
                    continue
                found.add(key)
                pts = p.cells()
                all_pts = list(cells) + pts
                min_r, min_c, max_r, max_c = bounds({pt: None for pt in all_pts})
                if max(max_r - min_r + 1, max_c - min_c + 1) <= max_span and can_place(placed, p):
                    result.append(p)
    return result


def validate(placements: list[Placement]) -> bool:
    if not placements or len({p.word for p in placements}) != len(placements):
        return False
    for index, p in enumerate(placements):
        if not can_place(placements[:index], p):
            return False
    cells, owners = board(placements)
    graph = {i: set() for i in range(len(placements))}
    for pair in owners.values():
        if len(pair) > 2:
            return False
        if len(pair) == 2:
            a, b = pair
            graph[a].add(b)
            graph[b].add(a)
    visited = {0}
    frontier = [0]
    while frontier:
        for neighbor in graph[frontier.pop()] - visited:
            visited.add(neighbor)
            frontier.append(neighbor)
    return len(visited) == len(placements)


def search(words: list[str], seed_word: str, rng: random.Random, attempts: int, max_words: int, max_span: int, score_fn):
    best = None
    for _ in range(attempts):
        first = Placement(seed_word, 0, 0, rng.choice(("across", "down")))
        placed = [first]
        unused = [w for w in words if w != seed_word]
        rng.shuffle(unused)
        while len(placed) < max_words:
            candidates = []
            for word in unused:
                for p in options(placed, word, max_span):
                    trial = placed + [p]
                    candidates.append((score_fn(trial), rng.random(), p))
            if not candidates:
                break
            candidates.sort(reverse=True, key=lambda item: (item[0], item[1]))
            # Explore near-best choices while keeping the search reproducible.
            chosen = rng.choice(candidates[: min(5, len(candidates))])[2]
            placed.append(chosen)
            unused.remove(chosen.word)
        if validate(placed) and (best is None or score_fn(placed) > score_fn(best)):
            best = placed
    return best
