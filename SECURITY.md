# Security Policy

## Supported Versions

This project is pre-1.0. Security fixes are handled on the default branch.

## Reporting a Vulnerability

Please report vulnerabilities privately by opening a GitHub security advisory
for this repository, or by contacting the maintainer through GitHub.

## Security Model

Codex Usage reads local Codex state files:

- `$CODEX_HOME/state_5.sqlite`
- `~/.codex/state_5.sqlite`
- local rollout JSONL files under the Codex sessions directory

The widget must not send usage data to external services. It must not call
Codex, the OpenAI API, or any model during refresh.

Avoid sharing screenshots or logs that expose private prompts, local paths, or
repository names from `~/.codex`.
