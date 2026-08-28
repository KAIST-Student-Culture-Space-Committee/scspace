#!/usr/bin/env python3
from __future__ import annotations

import argparse
import gzip
import os
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


def required_env(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise ValueError(f"Missing required environment variable: {name}")
    return value


def main() -> int:
    parser = argparse.ArgumentParser(description="Create a compressed MySQL backup.")
    parser.add_argument("--output-dir", default="backups")
    args = parser.parse_args()

    mysqldump = shutil.which("mysqldump")
    if mysqldump is None:
        print("mysqldump is required", file=sys.stderr)
        return 1

    try:
        host = required_env("MYSQL_HOST")
        port = required_env("MYSQL_PORT")
        user = required_env("MYSQL_USER")
        password = required_env("MYSQL_PWD")
        database = required_env("MYSQL_NAME")
    except ValueError as error:
        print(error, file=sys.stderr)
        return 1

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    target = output_dir / f"{database}-{timestamp}.sql.gz"
    temporary = output_dir / f".{target.name}.tmp"

    command = [
        mysqldump,
        "--single-transaction",
        "--routines",
        "--triggers",
        "--events",
        "--hex-blob",
        "--default-character-set=utf8mb4",
        "--host",
        host,
        "--port",
        port,
        "--user",
        user,
        database,
    ]
    environment = os.environ.copy()
    environment["MYSQL_PWD"] = password

    try:
        with temporary.open("wb") as raw_output:
            with gzip.GzipFile(fileobj=raw_output, mode="wb") as compressed:
                result = subprocess.run(
                    command,
                    env=environment,
                    stdout=compressed,
                    stderr=subprocess.PIPE,
                    text=True,
                    check=False,
                )

        if result.returncode != 0:
            message = result.stderr.strip() or "mysqldump failed"
            raise RuntimeError(message)

        with gzip.open(temporary, "rb") as compressed:
            compressed.read(1)
        os.chmod(temporary, 0o600)
        temporary.replace(target)
    except (OSError, RuntimeError) as error:
        temporary.unlink(missing_ok=True)
        print(error, file=sys.stderr)
        return 1

    print(target)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
