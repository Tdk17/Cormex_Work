"""Version the web service worker and cache the exact Flutter build assets."""

import hashlib
import json
import sys
from pathlib import Path
from urllib.parse import quote


def main() -> None:
    build = Path(sys.argv[1])
    entry = build / "main.dart.js"
    worker = build / "sw.js"
    if not entry.is_file() or not worker.is_file():
        raise SystemExit("Flutter web build or service worker is missing.")

    version = hashlib.sha256(entry.read_bytes()).hexdigest()[:16]
    excluded = {"sw.js", "flutter_service_worker.js", "NOTICES"}
    files = [
        "./" + quote(path.relative_to(build).as_posix(), safe="/")
        for path in sorted(build.rglob("*"))
        if path.is_file()
        and path.name not in excluded
        and path.suffix not in {".map", ".symbols"}
    ]
    source = worker.read_text()
    marker = "const PRECACHE = /*__PRECACHE__*/ ["
    if "__BUILD_ID__" not in source or marker not in source:
        raise SystemExit("Unexpected service worker template.")
    start = source.index(marker)
    end = source.index("];", start) + 2
    source = (
        source[:start]
        + "const PRECACHE = "
        + json.dumps(files, ensure_ascii=False)
        + ";"
        + source[end:]
    )
    worker.write_text(source.replace("__BUILD_ID__", version))
    print(f"PWA cache {version}: {len(files)} static assets")


if __name__ == "__main__":
    main()
