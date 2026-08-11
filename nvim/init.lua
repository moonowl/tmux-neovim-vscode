-- ~/.config/nvim/init.lua
-- Neovim as a VS Code-shaped editor. Hand-rolled, ~16 plugins, nothing hidden.
-- Requires Neovim 0.11.3+ (0.12.2 is current stable). Check with :version
--
-- Layout of this file:
--   1. Bootstrap lazy.nvim      6. LSP (native 0.11+ API)
--   2. Options                  7. Completion (blink.cmp)
--   3. Leader keys              8. UI: tree, tabs, statusline, git
--   4. VS Code keymaps          9. Editing niceties
--   5. Plugin list             10. Theme

-- ═══════════════════════════════════════════════════════════
-- 1. Bootstrap lazy.nvim
-- ═══════════════════════════════════════════════════════════
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ═══════════════════════════════════════════════════════════
-- 2. Options — VS Code-ish defaults
-- ═══════════════════════════════════════════════════════════
local o = vim.opt

o.number = true
o.relativenumber = false      -- VS Code shows absolute numbers; flip if you prefer
o.mouse = "a"
o.mousemodel = "popup"        -- right-click opens a menu instead of visual-select
o.clipboard = "unnamedplus"   -- yank goes to the system clipboard

-- This Neovim runs on the DEV SERVER. Left to auto-detect, nvim finds pbcopy
-- (it is macOS) and every yank lands in the SERVER's clipboard, which nobody
-- reads. Pin the provider to OSC 52 so the copy is emitted as an escape
-- sequence that travels back over SSH to the terminal you are sitting at.
-- Requires iTerm2 with clipboard access enabled; Terminal.app drops OSC 52.
--
-- Paste reads the internal register on purpose: terminals refuse OSC 52
-- clipboard *reads*, and asking anyway makes nvim hang for a timeout on every
-- paste. To paste text copied on your Mac, use the terminal paste (Cmd+V).
local osc52 = require("vim.ui.clipboard.osc52")
vim.g.clipboard = {
  name = "OSC 52",
  copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
  paste = {
    ["+"] = function() return vim.split(vim.fn.getreg("") or "", "\n") end,
    ["*"] = function() return vim.split(vim.fn.getreg("") or "", "\n") end,
  },
}
o.signcolumn = "yes"          -- stops the gutter jumping when diagnostics appear
o.cursorline = true
o.termguicolors = true
o.scrolloff = 8
o.wrap = false
o.splitright = true
o.splitbelow = true

-- Indentation: 2 spaces, expandtab. Change to taste.
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.softtabstop = 2
o.smartindent = true

-- Search behaves like VS Code's find: incremental, case-insensitive until you
-- type a capital, highlighted as you go.
o.ignorecase = true
o.smartcase = true
o.incsearch = true
o.hlsearch = true

-- Persistent undo, no swap/backup clutter
o.undofile = true
o.swapfile = false
o.backup = false

o.updatetime = 250            -- how fast diagnostics/git signs refresh
o.timeoutlen = 400
o.completeopt = "menu,menuone,noselect"

-- THE line that makes Shift+Arrow select text like every other editor.
-- keymodel=startsel,stopsel + selectmode=key gives you real shift-selection.
o.keymodel = { "startsel", "stopsel" }
o.selectmode = { "key" }
o.whichwrap:append("<,>,[,]")

-- ═══════════════════════════════════════════════════════════
-- 3. Leader
-- ═══════════════════════════════════════════════════════════
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ═══════════════════════════════════════════════════════════
-- 4. VS Code keymaps
-- ═══════════════════════════════════════════════════════════
-- Note on what's missing and why: Ctrl+Space, Ctrl+Shift+P, Ctrl+Shift+F,
-- Ctrl+\, Ctrl+PageUp/Down and Alt+hjkl are all claimed by the tmux config.
-- The companion tmux.conf yields the editor-ish ones back to Neovim when a vim
-- pane is focused. If you're running Neovim outside tmux they all just work.

local map = vim.keymap.set

-- ── File ──────────────────────────────────────────────────
-- Ctrl+S save. IMPORTANT: your shell must have flow control off or the
-- terminal eats Ctrl+S and freezes. Add `stty -ixon` to ~/.zshrc.
map({ "n", "i", "v" }, "<C-s>", "<Cmd>write<CR><Esc>", { desc = "Save" })
map("n", "<C-n>", "<Cmd>enew<CR>", { desc = "New file" })

-- ── Undo / redo ───────────────────────────────────────────
-- Ctrl+Z is normally "suspend to shell". Inside tmux that's rarely what you
-- want, so it's remapped. Use :suspend explicitly if you need the old behaviour.
map({ "n", "i", "v" }, "<C-z>", "<Cmd>undo<CR>", { desc = "Undo" })
map({ "n", "i", "v" }, "<C-y>", "<Cmd>redo<CR>", { desc = "Redo" })

-- ── Select / clipboard ────────────────────────────────────
map({ "n", "i" }, "<C-a>", "<Esc>ggVG", { desc = "Select all" })
map("v", "<C-c>", '"+y', { desc = "Copy" })
map("v", "<C-x>", '"+d', { desc = "Cut" })
map({ "n", "v" }, "<C-v>", '"+p', { desc = "Paste" })
map("i", "<C-v>", "<C-r>+", { desc = "Paste" })

-- ── Line manipulation ─────────────────────────────────────
-- Alt+Up/Down move lines. Alt+Shift+Up/Down duplicate. Exactly VS Code.
map("n", "<M-Up>",   "<Cmd>move .-2<CR>==",      { desc = "Move line up" })
map("n", "<M-Down>", "<Cmd>move .+1<CR>==",      { desc = "Move line down" })
map("i", "<M-Up>",   "<Esc><Cmd>move .-2<CR>==gi")
map("i", "<M-Down>", "<Esc><Cmd>move .+1<CR>==gi")
map("v", "<M-Up>",   ":move '<-2<CR>gv=gv",      { desc = "Move selection up" })
map("v", "<M-Down>", ":move '>+1<CR>gv=gv",      { desc = "Move selection down" })
map("n", "<M-S-Up>",   "<Cmd>copy .-1<CR>",      { desc = "Duplicate line up" })
map("n", "<M-S-Down>", "<Cmd>copy .<CR>",        { desc = "Duplicate line down" })
map("n", "<C-S-k>", '<Cmd>delete _<CR>',         { desc = "Delete line" })

-- ── Indent with Tab in visual mode, keeping the selection ──
map("v", "<Tab>",   ">gv")
map("v", "<S-Tab>", "<gv")

-- ── Find ──────────────────────────────────────────────────
map("n", "<C-f>", "/", { desc = "Find in file" })
map("i", "<C-f>", "<Esc>/", { desc = "Find in file" })
map("n", "<Esc>", "<Cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- ── Windows (VS Code editor groups) ────────────────────────
-- Ctrl+\ would be the VS Code split, but tmux owns it. Leader-based instead.
map("n", "<leader>\\", "<Cmd>vsplit<CR>", { desc = "Split right" })
map("n", "<leader>-",  "<Cmd>split<CR>",  { desc = "Split down" })

-- ── LSP: these become active once a language server attaches ──
map("n", "gd", vim.lsp.buf.definition,      { desc = "Go to definition" })
map("n", "gr", vim.lsp.buf.references,      { desc = "Find references" })
map("n", "gi", vim.lsp.buf.implementation,  { desc = "Go to implementation" })
map("n", "K",  vim.lsp.buf.hover,           { desc = "Hover docs" })
map("n", "<F12>", vim.lsp.buf.definition,   { desc = "Go to definition" })
map("n", "<F2>",  vim.lsp.buf.rename,       { desc = "Rename symbol" })
map({ "n", "v" }, "<C-.>", vim.lsp.buf.code_action, { desc = "Quick fix" })
map("n", "<leader>ca", vim.lsp.buf.code_action,     { desc = "Code action" })
map({ "n", "v" }, "<M-S-f>", function() vim.lsp.buf.format({ async = true }) end,
  { desc = "Format document" })
map("n", "<F8>", function() vim.diagnostic.jump({ count = 1 }) end,  { desc = "Next problem" })
map("n", "<S-F8>", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Prev problem" })

-- ═══════════════════════════════════════════════════════════
-- 5. Plugins
-- ═══════════════════════════════════════════════════════════
require("lazy").setup({

  -- ── Theme: Monokai Pro, matching the tmux status bar ─────
  {
    "loctvl842/monokai-pro.nvim",
    priority = 1000,
    config = function()
      require("monokai-pro").setup({
        filter = "pro",  -- pro | classic | machine | octagon | ristretto | spectrum
        background_clear = { "toggleterm", "telescope", "float_win" },
      })
      vim.cmd.colorscheme("monokai-pro")
    end,
  },

  -- ── Icons, used by tree/tabs/statusline ──────────────────
  { "nvim-tree/nvim-web-devicons", lazy = true },

  -- ═════════════════════════════════════════════════════════
  -- 6. LSP — the native 0.11+ API. No require("lspconfig").setup{}.
  -- ═════════════════════════════════════════════════════════
  -- nvim-lspconfig is now just a bag of server *definitions*; the framework
  -- part of it is deprecated. You enable servers with vim.lsp.enable() and
  -- override them with vim.lsp.config().
  { "neovim/nvim-lspconfig" },

  -- Mason installs the language servers themselves so you don't have to
  -- hand-install pyright, gopls, etc. :Mason opens the UI.
  { "mason-org/mason.nvim", opts = {} },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      -- Servers auto-installed on first launch. Trim to what you actually use.
      ensure_installed = { "lua_ls", "pyright", "ts_ls", "bashls", "jsonls" },
      automatic_enable = true,   -- calls vim.lsp.enable() for you
    },
  },

  -- ═════════════════════════════════════════════════════════
  -- 7. Completion — blink.cmp
  -- ═════════════════════════════════════════════════════════
  -- Chosen over nvim-cmp because it's one plugin instead of six and its
  -- fuzzy matcher is in Rust. Ships snippets and signature help built in.
  {
    "saghen/blink.cmp",
    version = "*",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = {
        preset = "none",
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"]     = { "hide" },
        ["<CR>"]      = { "accept", "fallback" },
        ["<Tab>"]     = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"]   = { "select_prev", "snippet_backward", "fallback" },
        ["<Up>"]      = { "select_prev", "fallback" },
        ["<Down>"]    = { "select_next", "fallback" },
      },
      appearance = { nerd_font_variant = "mono" },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        ghost_text = { enabled = true },   -- the grey inline preview
      },
      signature = { enabled = true },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
  },

  -- ═════════════════════════════════════════════════════════
  -- 8a. Fuzzy finder — Ctrl+P and friends
  -- ═════════════════════════════════════════════════════════
  -- Needs ripgrep on PATH for project-wide search: brew install ripgrep
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      local t = require("telescope")
      t.setup({
        defaults = {
          layout_strategy = "flex",
          mappings = {
            i = {
              ["<Esc>"] = require("telescope.actions").close,
              ["<C-j>"] = require("telescope.actions").move_selection_next,
              ["<C-k>"] = require("telescope.actions").move_selection_previous,
            },
          },
        },
      })
      pcall(t.load_extension, "fzf")

      local b = require("telescope.builtin")
      map("n", "<C-p>", b.find_files, { desc = "Quick open" })
      -- Ctrl+Shift+P / Ctrl+Shift+F work outside tmux; inside tmux the
      -- companion tmux.conf passes them through to Neovim.
      map("n", "<C-S-p>", b.commands,    { desc = "Command palette" })
      map("n", "<C-S-f>", b.live_grep,   { desc = "Search in files" })
      map("n", "<C-S-o>", b.lsp_document_symbols, { desc = "Go to symbol" })
      map("n", "<C-g>",   b.current_buffer_fuzzy_find, { desc = "Go to line" })
      map("n", "<leader>fb", b.buffers,  { desc = "Open buffers" })
      map("n", "<leader>fd", b.diagnostics, { desc = "Problems panel" })
    end,
  },

  -- ═════════════════════════════════════════════════════════
  -- 8b. File explorer — Ctrl+B, like the VS Code sidebar
  -- ═════════════════════════════════════════════════════════
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        view = { width = 32 },
        renderer = { group_empty = true },
        actions = { open_file = { quit_on_open = false } },
      })
      map("n", "<C-b>", "<Cmd>NvimTreeToggle<CR>", { desc = "Toggle explorer" })
      map("n", "<C-S-e>", "<Cmd>NvimTreeFocus<CR>", { desc = "Focus explorer" })
    end,
  },

  -- ═════════════════════════════════════════════════════════
  -- 8c. Editor tabs across the top
  -- ═════════════════════════════════════════════════════════
  -- Ctrl+PageUp/Down belongs to tmux (it switches tmux windows), so buffer
  -- switching here is Shift+H / Shift+L. If you'd rather have the VS Code keys
  -- in Neovim, remove those two bindings from tmux.conf.
  {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("bufferline").setup({
        options = {
          diagnostics = "nvim_lsp",
          offsets = { { filetype = "NvimTree", text = "EXPLORER", separator = true } },
          show_buffer_close_icons = true,
        },
      })
      map("n", "<S-l>", "<Cmd>BufferLineCycleNext<CR>", { desc = "Next tab" })
      map("n", "<S-h>", "<Cmd>BufferLineCyclePrev<CR>", { desc = "Prev tab" })
      map("n", "<C-w>", "<Cmd>bdelete<CR>", { desc = "Close tab" })
    end,
  },

  -- ═════════════════════════════════════════════════════════
  -- 8d. Statusline and git gutter
  -- ═════════════════════════════════════════════════════════
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { options = { theme = "auto", globalstatus = true } },
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "│" }, change = { text = "│" },
        delete = { text = "_" }, topdelete = { text = "‾" }, changedelete = { text = "~" },
      },
      current_line_blame = false,   -- flip to true for VS Code GitLens-style blame
    },
  },

  -- ═════════════════════════════════════════════════════════
  -- 9a. Syntax — Treesitter
  -- ═════════════════════════════════════════════════════════
  -- Pinned to the master branch. The `main` rewrite has a different API; if you
  -- later switch, the setup call below changes shape.
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "vim", "vimdoc", "python", "bash", "json", "yaml", "markdown" },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- ═════════════════════════════════════════════════════════
  -- 9b. Multi-cursor — the real Ctrl+D
  -- ═════════════════════════════════════════════════════════
  -- This is the one VS Code habit vanilla Vim genuinely cannot fake. Ctrl+D
  -- selects the word under the cursor, Ctrl+D again adds the next occurrence,
  -- then you just type. Esc to drop back to one cursor.
  {
    "mg979/vim-visual-multi",
    init = function()
      vim.g.VM_maps = {
        ["Find Under"]         = "<C-d>",
        ["Find Subword Under"] = "<C-d>",
        ["Select All"]         = "<C-S-l>",
      }
      vim.g.VM_silent_exit = 1
    end,
  },

  -- ═════════════════════════════════════════════════════════
  -- 9c. Small comforts
  -- ═════════════════════════════════════════════════════════
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
  { "folke/which-key.nvim",  event = "VeryLazy",    opts = {} },

  -- Seamless movement between Neovim splits and tmux panes with Alt+hjkl.
  -- Requires the matching bindings in tmux.conf (already in the companion file).
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    init = function()
      vim.g.tmux_navigator_no_mappings = 1
    end,
    config = function()
      map({ "n", "i" }, "<M-h>", "<Cmd>TmuxNavigateLeft<CR>",  { desc = "Pane left" })
      map({ "n", "i" }, "<M-j>", "<Cmd>TmuxNavigateDown<CR>",  { desc = "Pane down" })
      map({ "n", "i" }, "<M-k>", "<Cmd>TmuxNavigateUp<CR>",    { desc = "Pane up" })
      map({ "n", "i" }, "<M-l>", "<Cmd>TmuxNavigateRight<CR>", { desc = "Pane right" })
    end,
  },

}, {
  ui = { border = "rounded" },
  change_detection = { notify = false },
})

-- ═══════════════════════════════════════════════════════════
-- 10. Diagnostics display — inline errors like VS Code
-- ═══════════════════════════════════════════════════════════
vim.diagnostic.config({
  virtual_text = { prefix = "●", spacing = 2 },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = true },
})

-- Comment toggling: Neovim has this built in since 0.10 as `gcc` / `gc`.
-- Wire Ctrl+/ to it. Terminals send Ctrl+/ as either <C-_> or <C-/>, so bind both.
for _, lhs in ipairs({ "<C-_>", "<C-/>" }) do
  map("n", lhs, "gcc", { remap = true, desc = "Toggle comment" })
  map("v", lhs, "gc",  { remap = true, desc = "Toggle comment" })
  map("i", lhs, "<Esc>gccgi", { remap = true, desc = "Toggle comment" })
end

-- Highlight on yank, so you can see what got copied
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})
