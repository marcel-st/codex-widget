#!/usr/bin/env python3
"""Read Codex usage counters from local state without contacting Codex."""

from __future__ import annotations

import json
import os
import sqlite3
import sys
import time
from pathlib import Path


def codex_home() -> Path:
    return Path(os.environ.get("CODEX_HOME", Path.home() / ".codex")).expanduser()


def open_database(path: Path) -> sqlite3.Connection:
    uri = f"file:{path}?mode=ro"
    return sqlite3.connect(uri, uri=True, timeout=1)


def query_one(conn: sqlite3.Connection, sql: str, params: tuple[int, ...] = ()) -> tuple:
    row = conn.execute(sql, params).fetchone()
    return row if row is not None else tuple()


def latest_token_snapshot(home: Path) -> dict | None:
    sessions_dir = home / "sessions"
    if not sessions_dir.exists():
        return None

    rollouts = sorted(
        sessions_dir.glob("**/rollout-*.jsonl"),
        key=lambda path: path.stat().st_mtime,
        reverse=True,
    )
    for rollout in rollouts[:8]:
        latest = None
        try:
            with rollout.open("r", encoding="utf-8") as handle:
                for line in handle:
                    if '"token_count"' not in line:
                        continue
                    event = json.loads(line)
                    payload = event.get("payload", {})
                    if payload.get("type") == "token_count":
                        latest = payload
        except (OSError, json.JSONDecodeError):
            continue
        if latest:
            latest["rollout_path"] = str(rollout)
            return latest
    return None


def is_spark_model(model: str | None) -> bool:
    return "gpt-5.3-codex-spark" in (model or "").lower()


def usage_limit_snapshots(home: Path) -> dict:
    sessions_dir = home / "sessions"
    limits = {
        "regular": None,
        "spark": None,
    }
    if not sessions_dir.exists():
        return limits

    rollouts = sorted(
        sessions_dir.glob("**/rollout-*.jsonl"),
        key=lambda path: path.stat().st_mtime,
        reverse=True,
    )
    for rollout in rollouts[:40]:
        current_model = None
        latest = None
        try:
            with rollout.open("r", encoding="utf-8") as handle:
                for line in handle:
                    if '"model"' not in line and '"token_count"' not in line:
                        continue
                    event = json.loads(line)
                    payload = event.get("payload", {})
                    if "model" in payload:
                        current_model = payload.get("model")
                    if payload.get("type") == "token_count" and payload.get("rate_limits"):
                        latest = {
                            "model": current_model,
                            "rate_limits": payload["rate_limits"],
                            "timestamp": event.get("timestamp"),
                            "rollout_path": str(rollout),
                        }
        except (OSError, json.JSONDecodeError):
            continue

        if not latest:
            continue

        key = "spark" if is_spark_model(latest["model"]) else "regular"
        if limits[key] is None:
            limits[key] = latest
        if all(limits.values()):
            break

    return limits


def main() -> int:
    home = codex_home()
    db_path = home / "state_5.sqlite"
    if not db_path.exists():
        print(
            json.dumps(
                {
                    "ok": False,
                    "error": f"Codex state database not found: {db_path}",
                    "updated_at": int(time.time()),
                }
            )
        )
        return 0

    try:
        with open_database(db_path) as conn:
            conn.row_factory = sqlite3.Row
            now_ms = int(time.time() * 1000)
            day_start = now_ms - 24 * 60 * 60 * 1000
            week_start = now_ms - 7 * 24 * 60 * 60 * 1000
            month_start = now_ms - 30 * 24 * 60 * 60 * 1000

            total = query_one(
                conn,
                """
                select
                    count(*) as sessions,
                    coalesce(sum(tokens_used), 0) as tokens,
                    coalesce(max(updated_at_ms), 0) as last_updated
                from threads
                """,
            )
            day = query_one(
                conn,
                "select coalesce(sum(tokens_used), 0) from threads where updated_at_ms >= ?",
                (day_start,),
            )
            week = query_one(
                conn,
                "select coalesce(sum(tokens_used), 0) from threads where updated_at_ms >= ?",
                (week_start,),
            )
            month = query_one(
                conn,
                "select coalesce(sum(tokens_used), 0) from threads where updated_at_ms >= ?",
                (month_start,),
            )
            latest = conn.execute(
                """
                select title, tokens_used, model, updated_at_ms
                from threads
                order by updated_at_ms desc, id desc
                limit 1
                """
            ).fetchone()

        print(
            json.dumps(
                {
                    "ok": True,
                    "source": str(db_path),
                    "retrieval": "local sqlite read-only; no Codex API or model call",
                    "updated_at": int(time.time()),
                    "total_tokens": int(total["tokens"]),
                    "sessions": int(total["sessions"]),
                    "tokens_24h": int(day[0]),
                    "tokens_7d": int(week[0]),
                    "tokens_30d": int(month[0]),
                    "last_thread": dict(latest) if latest else None,
                    "last_updated_ms": int(total["last_updated"]),
                    "latest_token_snapshot": latest_token_snapshot(home),
                    "usage_limits": usage_limit_snapshots(home),
                }
            )
        )
        return 0
    except Exception as exc:
        print(
            json.dumps(
                {
                    "ok": False,
                    "error": str(exc),
                    "updated_at": int(time.time()),
                }
            )
        )
        return 0


if __name__ == "__main__":
    sys.exit(main())
