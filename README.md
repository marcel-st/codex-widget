# codex-widget

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Simple KDE Plasma widget that shows Codex usage stats from the local Codex
state database.

The widget does not call Codex, the OpenAI API, or any model when refreshing.
It runs `package/contents/scripts/codex_usage_stats.py`, which opens
`$CODEX_HOME/state_5.sqlite` or `~/.codex/state_5.sqlite` read-only and
aggregates the existing `threads.tokens_used` counters. It also reads the most
recent local rollout JSONL token snapshot, when available, to show cached
Codex rate-limit usage percentages.

The compact panel widget shows the latest 5-hour usage percentage when local
rate-limit telemetry is available. Clicking the widget opens a detailed view
with token totals plus a usage-limits table for regular Codex usage and
`gpt-5.3-codex-spark`. Each row shows the cached 5-hour and weekly usage
percentages and reset times. Model-specific rows show `No local data` until a
local rollout for that model has recorded rate-limit telemetry.

## Install

```bash
chmod +x install.sh package/contents/scripts/codex_usage_stats.py
./install.sh
```

After installing, add the "Codex Usage" widget from KDE Plasma's widget picker.

## Local stats

Run the helper directly to inspect the JSON used by the widget:

```bash
package/contents/scripts/codex_usage_stats.py
```

The JSON includes:

- `tokens_24h`
- `tokens_7d`
- `tokens_30d`
- `total_tokens`
- `sessions`
- `last_thread`
- `latest_token_snapshot`
- `usage_limits`

## Notes

- Refresh interval: 60 seconds.
- Data source: local SQLite only.
- Token use: zero for retrieval, because no Codex session or model request is
  made by the widget.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development and validation steps.

## Security

See [SECURITY.md](SECURITY.md) for the security model and vulnerability
reporting guidance.

## License

MIT. See [LICENSE](LICENSE).
