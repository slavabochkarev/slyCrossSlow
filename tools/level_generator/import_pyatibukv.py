"""Refresh frozen 5-letter source snapshots from a local Pyatibukv checkout."""

from pathlib import Path
import argparse
import re

from dictionary import DATA

TOKEN = re.compile(r"'([^']+)'")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=Path(r"C:\Project\Pyatibukv\lib\word_dictionary.dart"))
    args = parser.parse_args()
    dart = args.source.read_text(encoding="utf-8")
    answers = TOKEN.findall(dart.split("const answerWords = <String>[", 1)[1].split("];", 1)[0])
    accepted = TOKEN.findall(dart.split("const acceptedWords = <String>{", 1)[1].split("};", 1)[0])
    for name, words in (("answers", answers), ("accepted", accepted)):
        (DATA / f"pyatibukv_{name}.txt").write_text("\n".join(words) + "\n", encoding="utf-8")
        print(f"{name}: {len(words)}")


if __name__ == "__main__":
    main()
