#!/usr/bin/env bash
# Prepares a fresh Claude Code cloud container for the code-video skill.
# Runs from the SessionStart hook in .claude/settings.json; safe to re-run.
set -uo pipefail
[[ "${CLAUDE_CODE_REMOTE:-}" == "true" ]] || exit 0

if ! command -v ffmpeg >/dev/null; then
  (apt-get install -y -qq ffmpeg || { apt-get update -qq && apt-get install -y -qq ffmpeg; }) >/dev/null 2>&1 \
    || echo "code-video setup: ffmpeg install failed" >&2
fi

# render.mjs launches Playwright with channel 'chrome'; Google Chrome can't be downloaded here,
# so point Chrome's install path at the preinstalled Playwright Chromium.
if [[ ! -x /opt/google/chrome/chrome && -x /opt/pw-browsers/chromium ]]; then
  mkdir -p /opt/google/chrome && ln -sf "$(readlink -f /opt/pw-browsers/chromium)" /opt/google/chrome/chrome
fi
exit 0
