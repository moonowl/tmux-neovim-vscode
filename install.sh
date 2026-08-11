#!/usr/bin/env bash
# install.sh — symlink this config into place.
#
# Symlinks rather than copies, so editing the live file edits the checkout and
# `git diff` shows what you changed. Anything already there that is not already
# our symlink is moved to <file>.bak-<timestamp> — nothing is overwritten
# silently.
#
#   ./install.sh            everything
#   ./install.sh tmux       just tmux.conf
#   ./install.sh nvim       just the Neovim config
#   ./install.sh --dry-run  show what would happen

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DRY=0
WHAT="all"

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    tmux|nvim|vim|quad|all) WHAT="$arg" ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done

link() {
  local src="$REPO/$1" dst="$2"
  [ -e "$src" ] || { echo "  skip    $dst  (not in repo)"; return; }
  if [ "$DRY" = 1 ]; then echo "  would link $dst -> $src"; return; fi
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "  ok      $dst"; return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "$dst.bak-$STAMP"
    echo "  backup  $(basename "$dst") -> $(basename "$dst").bak-$STAMP"
  fi
  ln -s "$src" "$dst"
  echo "  link    $dst"
}

want() { [ "$WHAT" = "all" ] || [ "$WHAT" = "$1" ]; }

want tmux && link tmux.conf     "$HOME/.tmux.conf"
want nvim && link nvim/init.lua "$HOME/.config/nvim/init.lua"
want vim  && link vimrc         "$HOME/.vimrc"
want quad && { link bin/quad "$HOME/bin/quad"; chmod +x "$REPO/bin/quad"; }

[ "$DRY" = 1 ] && exit 0

echo
# Checked rather than assumed: a missing dependency here is a silent failure
# later — no icons, no search, or a config that errors on load.
command -v rg   >/dev/null || echo "  missing: ripgrep      (search-in-files won't work)  brew install ripgrep"
command -v nvim >/dev/null || echo "  missing: neovim       brew install neovim"
if command -v nvim >/dev/null; then
  v=$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo 0.0.0)
  [ "$(printf '%s\n0.11.3\n' "$v" | sort -V | head -1)" = "0.11.3" ] \
    || echo "  neovim $v is below 0.11.3 — the LSP setup needs the native vim.lsp API"
fi
if command -v tmux >/dev/null; then
  tv=$(tmux -V | grep -oE '[0-9]+\.[0-9]+' || echo 0)
  awk -v v="$tv" 'BEGIN{ if (v+0 < 3.5) print "  tmux " v " is below 3.5 — Ctrl+Shift bindings will not work" }'
fi

echo
echo "  next:"
echo "    tmux source-file ~/.tmux.conf   (a running server won't reload on its own)"
echo "    set your terminal to a Nerd Font, or the file tree shows blank boxes"
echo "    add 'stty -ixon' to your shell rc, or Ctrl+S freezes the terminal"
echo
echo "done."
