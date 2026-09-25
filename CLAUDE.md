# Videos

## code-video skill

`.claude/skills/code-video/` is a vendored copy of https://github.com/Changroro/code-video (commit 38fce0b).
Ask for a video ("make a 30-second promo video for https://example.com") to use it.

Cloud-environment notes:
- `tools/setup-code-video.sh` runs at session start (see `.claude/settings.json`): installs ffmpeg and
  links the preinstalled Playwright Chromium to `/opt/google/chrome/chrome`, which `render.mjs` launches.
- GitHub raw and jsDelivr are blocked here, so the skill's `scripts/fetch_fonts.sh` fails. Use
  `bash tools/fetch_fonts_npm.sh assets/fonts` instead; it fetches the same fonts from npm.
