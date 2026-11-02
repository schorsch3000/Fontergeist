#!/usr/bin/env bash
# Smoke tests for fontergeist. Needs ImageMagick, Pillow and the DejaVu fonts;
# fzf and the image renderer are replaced by stubs.
set -u

root=$(cd "$(dirname "$0")/.." && pwd)
bin=$root/fontergeist
fontdir=${FONT_DIR:-/usr/share/fonts/truetype/dejavu}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

unset FONT_TEXT FONT_SIZE FONT_FG FONT_BG FONT_RENDERER FONT_CELL
mkdir -p "$tmp/bin" "$tmp/fonts" "$tmp/xdg/fontergeist" "$tmp/home"
cp "$fontdir"/DejaVuSans.ttf "$fontdir"/DejaVuSans-Bold.ttf "$fontdir"/DejaVuSerif.ttf "$tmp/fonts/"
touch "$tmp/fonts/notes.txt"

# fzf stub: record input, environment and state files, pick the "DejaVu Sans" family
cat >"$tmp/bin/fzf" <<STUB
#!/bin/sh
cat >"$tmp/fzf.in"
env >"$tmp/fzf.env"
cp "\$FONTERGEIST_INDEX" "$tmp/index.tsv"
grep '^DejaVu Sans (2)' "$tmp/fzf.in"
STUB
# chafa stub: keep the image fontergeist would have displayed
cat >"$tmp/bin/chafa" <<STUB
#!/bin/sh
for last; do :; done
cp "\$last" "$tmp/out.png"
STUB
chmod +x "$tmp/bin/fzf" "$tmp/bin/chafa"

export PATH="$tmp/bin:$PATH" HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/xdg" FONT_CELL=10x20
failed=0
check() { # description command...
  local desc=$1
  shift
  if "$@"; then echo "ok   $desc"; else echo "FAIL $desc"; failed=1; fi
}
# shellcheck disable=SC2317,SC2329 # called through check
has() { grep -qxF -- "$2" "$1"; } # file line
paths() { printf '%s\n' "$tmp"/fonts/*; }

out=$(paths | "$bin" 2>&1)
cp "$tmp/index.tsv" "$tmp/index.main.tsv"
check "selected family prints its files" test "$(wc -l <<<"$out")" -eq 2
check "…both DejaVuSans files" grep -q 'DejaVuSans-Bold.ttf' <<<"$out"
check "family list groups styles" has "$tmp/fzf.in" $'DejaVu Sans (2)\tDejaVu Sans'
check "single-style family has no count" has "$tmp/fzf.in" $'DejaVu Serif\tDejaVu Serif'
check "non-font files are ignored" test "$(grep -c notes "$tmp/fzf.in")" -eq 0
check "index is sorted Book before Bold" test "$(awk -F'\t' '$1=="DejaVu Sans"{print $2}' "$tmp/index.main.tsv" | paste -sd,)" = "Book,Bold"

echo /some/where/MISSING.TTF | "$bin" >/dev/null 2>&1
check "extension match is case-insensitive, unreadable file listed by name" has "$tmp/fzf.in" $'MISSING\tMISSING'

paths | "$bin" -s 20 -f red -- -dash text >/dev/null 2>&1
check "text after -- may start with a dash" has "$tmp/fzf.env" 'FONT_TEXT=-dash text'
check "-f sets the foreground" has "$tmp/fzf.env" 'FONT_FG=red'

paths | "$bin" -s x >/dev/null 2>&1
check "non-numeric size is rejected" test $? -ne 0
paths | "$bin" -x >/dev/null 2>&1
check "unknown option is rejected" test $? -ne 0
check "--version prints the version" grep -q '^fontergeist ' <<<"$("$bin" --version)"

printf '# comment\nFONT_TEXT="from config"\nFONT_FG=green\nFONT_BG = yellow\n' >"$tmp/xdg/fontergeist/config"
paths | FONT_FG=blue "$bin" >/dev/null 2>&1
check "config sets variables" has "$tmp/fzf.env" 'FONT_TEXT=from config'
check "config values are trimmed" has "$tmp/fzf.env" 'FONT_BG=yellow'
check "environment beats config" has "$tmp/fzf.env" 'FONT_FG=blue'
paths | "$bin" hello world >/dev/null 2>&1
check "arguments beat config" has "$tmp/fzf.env" 'FONT_TEXT=hello world'

# render a family through the stub renderer and check the image size
echo 32 >"$tmp/state"
FONTERGEIST_INDEX=$tmp/index.tsv FONTERGEIST_STATE=$tmp/state FONT_RENDERER=chafa \
  FONT_TEXT=Hello FONT_FG=black FONT_BG=white FZF_PREVIEW_COLUMNS=60 FZF_PREVIEW_LINES=20 \
  "$bin" __render "DejaVu Sans" >"$tmp/render.log" 2>&1
ident=(magick identify)
command -v magick >/dev/null || ident=(identify)
check "preview image fills the pane" test "$("${ident[@]}" -format %wx%h "$tmp/out.png")" = 600x400

exit "$failed"
