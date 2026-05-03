# Contributing

Thanks for taking the time to improve Codex Usage.

## Development Setup

Requirements:

- KDE Plasma 6 with `kpackagetool6`
- Python 3
- A local Codex state directory, normally `~/.codex`

Install the widget locally:

```bash
./install.sh
```

Run the data helper directly:

```bash
package/contents/scripts/codex_usage_stats.py
```

The helper must remain local-only. Do not add Codex API calls, OpenAI API calls,
model prompts, or network requests to the refresh path.

## Validation

Before opening a pull request, run:

```bash
python3 -m py_compile package/contents/scripts/codex_usage_stats.py
package/contents/scripts/codex_usage_stats.py
kpackagetool6 --appstream-metainfo package
```

If Plasma is available, install the package into a temporary root:

```bash
kpackagetool6 --type Plasma/Applet --packageroot /tmp/codex-widget-kpackage --install package
```

## Pull Requests

Keep changes focused. Include:

- What changed
- Why it changed
- How it was validated
- Any KDE Plasma version assumptions
