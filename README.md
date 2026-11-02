# fontergeist

Shows fonts that aren't even installed.

Point it at a directory of font files, pick a family with fzf, and see your
text rendered in every style of it, right in the terminal. Nothing gets
installed and nothing is copied.

## Requirements

- bash and [fzf](https://github.com/junegunn/fzf)
- [ImageMagick](https://imagemagick.org) (`magick` or `convert`) with FreeType
- a terminal that can show images: [kitty](https://sw.kovidgoyal.net/kitty/),
  [WezTerm](https://wezfurlong.org/wezterm/), or anything
  [chafa](https://hpjansson.be/chafa/) supports (sixel, iTerm2, ...)
- optional: Pillow (`python3-pil`) to group files by family and style and to
  preview bitmap `.fon` fonts. Without it every file is its own entry.

## Install

It is a single script. Download it from the
[latest release](../../releases/latest), make it executable and put it on your
`PATH`:

```sh
install -m755 fontergeist ~/.local/bin/
```

## Usage

```sh
fontergeist                          # search font files below the current directory
find ~/Downloads -name '*.ttf' | fontergeist   # or feed it a list of paths
fontergeist -s 64 -f white -b '#202020' Hello, world
fontergeist -- -dashes first         # -- ends options, text may start with -
```

Everything that is not an option is the preview text. The font files of the
chosen family are printed on stdout, one per line, so you can do
`cp "$(fontergeist)" ~/.local/share/fonts/`.

| Option | Meaning |
| --- | --- |
| `-s`, `--size SIZE` | font size in pixels (default 48) |
| `-f`, `--foreground COLOR` | text color (default black) |
| `-b`, `--background COLOR` | background color (default white) |
| `-V`, `--version` | print the version |
| `-h`, `--help` | usage |

Inside fzf, `alt-up` / `alt-down` change the size by 4.

Recognised extensions (case-insensitive): `ttf otf ttc otc woff woff2 fon fnt
pfb pfa pcf bdf dfont`.

## Configuration

Settings come from, in order of precedence: command-line options, environment
variables, config file.

| Variable | Meaning |
| --- | --- |
| `FONT_TEXT` | preview text (default: the quick brown fox) |
| `FONT_SIZE` | size in pixels |
| `FONT_FG` / `FONT_BG` | text and background color |
| `FONT_RENDERER` | `kitty`, `wezterm` or `chafa` (default: autodetect) |
| `FONT_CELL` | terminal cell size in pixels, e.g. `10x20` (default: asked from the terminal) |

The config file is `${XDG_CONFIG_HOME:-~/.config}/fontergeist/config`, with
one `NAME=value` per line. It is parsed, never executed.

```
# ~/.config/fontergeist/config
FONT_SIZE=32
FONT_TEXT="Hallo Welt"
FONT_BG='#fffbe6'
```

## Notes

- Bitmap fonts (`.fon`) only exist in fixed sizes. fontergeist uses the size
  closest to yours and scales it up by whole factors, so pixels stay sharp.
- Errors while rendering a font are shown in the preview pane.
- A family with more styles than fit into the pane is cut off.

## Development

CI runs `shellcheck` and `tests/smoke.sh` (they stub fzf and the image
viewer; ImageMagick, Pillow and the DejaVu fonts are needed). Pushing a tag like `v0.1.0` runs both again and
publishes a GitHub release whose only asset is the script, with its version
set to the tag.

## License

GPL-3.0-or-later, see [LICENSE](LICENSE).
