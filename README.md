# tmux + Neovim, shaped like VS Code

A prefix-free tmux config and a matching Neovim setup, for people who know the VS Code
keymap and want it in a terminal — especially over SSH, where the editor lives on a dev
box and the keyboard does not.

`Ctrl+\` splits. `Ctrl+P` opens a file. `Ctrl+D` gives you multiple cursors. `Ctrl+B`
toggles the file tree. No leader chord in front of any of it.

- **No prefix.** tmux keys are bound with `bind -n`, so they fire directly. `Ctrl+A`
  is kept purely as an escape hatch.
- **tmux gets out of Neovim's way.** A `bind -n` key never reaches the program in the
  pane, which would leave an editor unable to see `Ctrl+Shift+P`, `Ctrl+Shift+F` or
  `Alt+h` — exactly the keys it wants most. This config checks what is running in the
  focused pane and forwards those keys when it is Vim.
- **Copy works over SSH.** Both sides copy through OSC 52 rather than `pbcopy`, so a
  yank on the remote machine lands on the clipboard of the machine you are sitting at.
- **Monokai Pro** across the status bar, the tab line and the editor.

## Requirements

| | |
|---|---|
| tmux | 3.5+ — `set -s extended-keys` is what makes `Ctrl+Shift+<key>` reachable |
| Neovim | 0.11.3+ — uses the native `vim.lsp.enable()` API, not the deprecated `lspconfig` framework |
| ripgrep | powers search-in-files |
| A Nerd Font | or the file tree renders every icon as a blank box |
| An OSC 52 terminal | iTerm2, kitty, WezTerm, Ghostty, Alacritty. **Not macOS Terminal.app** |

```bash
brew install tmux neovim ripgrep
brew install --cask font-jetbrains-mono-nerd-font
```

## Install

```bash
git clone https://github.com/moonowl/tmux-neovim-vscode.git
cd tmux-neovim-vscode
./install.sh
```

Symlinks `tmux.conf`, `nvim/init.lua`, `vimrc` and `bin/quad` into place, backing up
anything already there. Neovim installs its own plugins on first launch — give it a
minute, then `:Lazy` and `:Mason` show the status.

## Keys

`Ctrl+A` is the escape hatch prefix; everything else is direct.

### Panes and windows — tmux

| | |
|---|---|
| `Ctrl+\` / `Alt+\` | split right / split down |
| `Alt+h` `j` `k` `l` | move between panes — passes into Neovim splits too |
| `Ctrl+Shift+←↑↓→` | resize |
| `Alt+Enter` | zoom pane / restore |
| `Ctrl+Shift+W` / `Ctrl+Shift+Q` | close pane / close window |
| `Ctrl+Shift+T` | new window |
| `Ctrl+PgUp` / `Ctrl+PgDn` | previous / next window |
| `Alt+1`…`9` | jump to window |
| `Ctrl+Space` | scratch terminal in a popup |
| `Ctrl+A` `d` | detach |

### Files and editing — Neovim

| | |
|---|---|
| `Ctrl+P` | quick open |
| `Ctrl+B` | toggle file tree |
| `Ctrl+S` | save |
| `Ctrl+D` | multi-cursor on the word, again for the next match |
| `Ctrl+/` | toggle comment |
| `Alt+↑` / `Alt+↓` | move the line |
| `Alt+Shift+↑` / `↓` | duplicate the line |
| `Shift+H` / `Shift+L` | previous / next open file |
| `Ctrl+W` | close file |
| `gd` · `gr` · `K` | definition · references · hover |
| `F2` · `Space c a` | rename symbol · code action |
| `F8` / `Shift+F8` | next / previous problem |

### Shared — resolved by what is focused

These three go to Neovim when a Vim pane has focus, and to tmux otherwise.

| | |
|---|---|
| `Ctrl+Shift+P` | command palette · tmux command prompt |
| `Ctrl+Shift+F` | search in files · search the scrollback |
| `Ctrl+Shift+E` | focus file tree · tmux session picker |

### Copy

`Ctrl+A` `[` enters copy mode, `v` selects, `y` copies to your local clipboard. Dragging
with the mouse does the same in one motion.

Pasting *into* the remote session is your terminal's own paste — `Cmd+V` — always. OSC 52
can write a clipboard but never read one, so there is no remote-paste binding to
configure, in this or any other setup.

## `quad`

A 2×2 session in one command, on the machine the config is installed on:

```bash
quad                      # session "quad", panes in $PWD
quad api                  # session "api"
quad api ~/src/api        # session "api", panes rooted there
```

Run it again after a disconnect and it reattaches with everything still running. Pair it
with a local shell function for a one-word entry point to a remote project:

```bash
myproject() { ssh -t devbox 'quad myproject $HOME/src/myproject'; }
```

## Things that will bite you

**Copy silently does nothing.** Almost always the terminal. Terminal.app has no OSC 52
support at all and discards the escape without an error. iTerm2 has it *off by default* —
enable *Settings → General → Selection → Applications in terminal may access clipboard*.
Terminals also cap the payload silently, so a very large copy can vanish while a small
one works.

**Blank boxes instead of icons.** No Nerd Font, or the terminal is pointed at a font that
is not one. On iTerm2 pick the font from the GUI picker rather than typing a name: the
PostScript name is not the filename — JetBrains Mono Nerd Font Mono is
`JetBrainsMonoNFM-Regular` — and iTerm2 falls back silently when a name does not resolve.
Choose the **Mono** variant so every icon is one cell wide and the tree columns line up.

**`Ctrl+S` freezes the terminal.** That is flow control, not a crash. `Ctrl+Q` unfreezes.
Add `stty -ixon` to your shell rc so the key reaches the editor as save.

**`Ctrl+A` needs pressing twice** to reach the program in the pane, since tmux takes the
first one as its prefix. That is how you get Neovim's select-all.

**`Ctrl+W` closes the file** rather than being Vim's window prefix, so `Ctrl+W s` and
`Ctrl+W v` do nothing. Split with `Space \` and `Space -`. Delete that one line in the
bufferline block if you would rather have the Vim behaviour back.

**Alt+arrows are deliberately not pane navigation** — Neovim uses `Alt+↑`/`Alt+↓` to move
lines, which is the VS Code behaviour worth keeping. Panes are `Alt+h` `j` `k` `l`.

**Editing tmux.conf does not fully apply.** A running tmux server never re-reads its
config; `tmux source-file ~/.tmux.conf` applies it. But sourcing only *adds and
overrides* — a binding you deleted from the file stays live until an explicit
`tmux unbind -n <key>`.

**Nested tmux eats everything.** SSHing into a remote tmux from inside a local one means
the local session takes every direct key first. There is no clean fix for a prefix-free
config: drive the remote session from a plain terminal tab.

## Layout

```
tmux.conf        prefix-free bindings, Vim passthrough, Monokai Pro, OSC 52 copy
nvim/init.lua    lazy.nvim, ~20 plugins, native LSP, blink.cmp, telescope, treesitter
vimrc            mouse + OSC 52 yank for plain vim
bin/quad         build or reattach a 2x2 session
install.sh       symlink it all into place
```

Both configs are single files, commented throughout, with no framework in front of them.
Read them and change them.

## License

MIT
