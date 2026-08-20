#!/usr/bin/env python3
import os
import sys


def list_files(directory):
    filenames = []
    for root, _, files in os.walk(directory):
        for name in files:
            full_path = os.path.join(root, name)
            filenames.append(os.path.relpath(full_path, directory))
    return filenames


def find_feature_lines(directory, filenames):
    feature_lines = []
    for rel_path in filenames:
        full_path = os.path.join(directory, rel_path)
        try:
            with open(full_path, "r", errors="ignore") as f:
                for line in f:
                    if "FEATURE" in line:
                        feature_lines.append(line)
        except (OSError, UnicodeDecodeError):
            continue
    return feature_lines


def create_feature_set(feature_lines):
    feature_set = {}
    for line in feature_lines:
        idx = line.find("FEATURE")
        after = line[idx + len("FEATURE"):].split()
        key = after[0] if after else ""
        feature_set[key] = line
    return feature_set


def write_feature_file(feature_set):
    with open("features.txt", "w") as f:
        for line in feature_set.values():
            f.write(line if line.endswith(chr(10)) else line + chr(10))


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <directory>")
        sys.exit(1)

    directory = sys.argv[1]
    filenames = list_files(directory)
    feature_lines = find_feature_lines(directory, filenames)
    feature_set = create_feature_set(feature_lines)
    write_feature_file(feature_set)


if __name__ == "__main__":
    main()
