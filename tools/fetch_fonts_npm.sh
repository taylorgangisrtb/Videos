#!/usr/bin/env bash
# Fallback for .claude/skills/code-video/scripts/fetch_fonts.sh when GitHub raw and jsDelivr are
# blocked (as in the Claude Code cloud environment). Pulls the same fonts from the npm registry and
# writes them under the file names the skill expects. Variable Latin fonts come from
# @fontsource-variable as latin-subset woff2 (Chrome's FontFace sniffs the format, so the .ttf name is fine).
# Usage: bash tools/fetch_fonts_npm.sh [dir]   (default assets/fonts)
set -euo pipefail
dir="$(mkdir -p "${1:-assets/fonts}" && cd "${1:-assets/fonts}" && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
declare -A unpacked
# get <out name> <npm package> <path inside package/>
get() {
  local out="$1" pkg="$2" src="$3" key="${2//[@\/]/_}"
  if [[ -z "${unpacked[$key]:-}" ]]; then
    mkdir -p "$tmp/$key"
    local tgz; tgz="$(cd "$tmp" && npm pack --silent "$pkg" | tail -1)"
    tar xzf "$tmp/$tgz" -C "$tmp/$key"
    unpacked[$key]=1
  fi
  cp "$tmp/$key/package/$src" "$dir/$out" || { echo "font copy failed: $out <- $pkg/$src" >&2; exit 1; }
  echo "ok $out"
}
EG=@expo-google-fonts; FV=@fontsource-variable
get Pretendard-ExtraBold.otf pretendard dist/public/static/Pretendard-ExtraBold.otf
get Pretendard-Regular.otf pretendard dist/public/static/Pretendard-Regular.otf
get Pretendard-Bold.otf pretendard dist/public/static/Pretendard-Bold.otf
get Pretendard-Black.otf pretendard dist/public/static/Pretendard-Black.otf
get Galmuri11-Bold.ttf galmuri dist/Galmuri11-Bold.ttf
get BlackHanSans-Regular.ttf $EG/black-han-sans 400Regular/BlackHanSans_400Regular.ttf
get Gaegu-Bold.ttf $EG/gaegu 700Bold/Gaegu_700Bold.ttf
get NanumMyeongjo-ExtraBold.ttf $EG/nanum-myeongjo 800ExtraBold/NanumMyeongjo_800ExtraBold.ttf
get NanumMyeongjo-Regular.ttf $EG/nanum-myeongjo 400Regular/NanumMyeongjo_400Regular.ttf
get PressStart2P-Regular.ttf $EG/press-start-2p 400Regular/PressStart2P_400Regular.ttf
get NanumGothicCoding-Regular.ttf $EG/nanum-gothic-coding 400Regular/NanumGothicCoding_400Regular.ttf
get NanumGothicCoding-Bold.ttf $EG/nanum-gothic-coding 700Bold/NanumGothicCoding_700Bold.ttf
get IBMPlexMono-Regular.ttf $EG/ibm-plex-mono 400Regular/IBMPlexMono_400Regular.ttf
get IBMPlexMono-Medium.ttf $EG/ibm-plex-mono 500Medium/IBMPlexMono_500Medium.ttf
get Poppins-SemiBold.ttf $EG/poppins 600SemiBold/Poppins_600SemiBold.ttf
get Poppins-Bold.ttf $EG/poppins 700Bold/Poppins_700Bold.ttf
get Geist.ttf $FV/geist files/geist-latin-wght-normal.woff2
get PlayfairDisplay.ttf $FV/playfair-display files/playfair-display-latin-wght-normal.woff2
get SourceSerif4.ttf $FV/source-serif-4 files/source-serif-4-latin-standard-normal.woff2
get Caveat.ttf $FV/caveat files/caveat-latin-wght-normal.woff2
get Cormorant.ttf $FV/cormorant files/cormorant-latin-wght-normal.woff2
get Cormorant-Italic.ttf $FV/cormorant files/cormorant-latin-wght-italic.woff2
get IBMPlexSans.ttf $FV/ibm-plex-sans files/ibm-plex-sans-latin-standard-normal.woff2
