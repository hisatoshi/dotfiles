----------------------------------------------------------------------
--  基本設定
----------------------------------------------------------------------
-- モジュールキャッシュ（起動高速化）
vim.loader.enable()

vim.g.mapleader = " "

-- MoonBit
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.mbt", "*.mbti" },
  callback = function()
    vim.bo.filetype = "moonbit"
    vim.schedule(function() pcall(vim.treesitter.start) end)
  end,
})

-- Provider無効化
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0

-- 不要なビルトインプラグイン無効化
local disabled_builtins = {
  "netrw", "netrwPlugin", "netrwSettings", "netrwFileHandlers",
  "gzip", "zip", "zipPlugin", "tar", "tarPlugin",
  "getscript", "getscriptPlugin", "vimball", "vimballPlugin",
  "2html_plugin", "tutor", "rplugin",
  "matchit", "matchparen",
}
for _, plugin in ipairs(disabled_builtins) do
  vim.g["loaded_" .. plugin] = 1
end

local BG = "#2a2d3e"

vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.swapfile = false
vim.opt.laststatus = 0
vim.opt.cmdheight = 1

vim.opt.statusline = " "
vim.opt.fillchars = { stl = "─", stlnc = "─" }
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.signcolumn = "yes"
vim.opt.smartcase = true
vim.opt.ignorecase = true
vim.opt.completeopt = "menu,menuone,noselect"
vim.opt.updatetime = 250
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.shortmess:append("FI")

-- 起動時のちらつき防止（カラースキーム読み込み前に背景色を統一）
do
  vim.api.nvim_set_hl(0, "Normal", { bg = BG })
  vim.api.nvim_set_hl(0, "NormalNC", { bg = BG })
  vim.api.nvim_set_hl(0, "MsgArea", { fg = BG, bg = BG })
  vim.api.nvim_set_hl(0, "StatusLine", { fg = BG, bg = BG })
  vim.api.nvim_set_hl(0, "StatusLineNC", { fg = BG, bg = BG })
  vim.api.nvim_set_hl(0, "MsgSeparator", { fg = BG, bg = BG })
end

-- UIの準備完了後にcmdheight=0を適用（起動時のちらつき防止）
vim.api.nvim_create_autocmd("UIEnter", {
  once = true,
  callback = function()
    vim.opt.cmdheight = 0
  end,
})

-- 診断メッセージの表示設定
vim.diagnostic.config({
  virtual_text = false,
  float = {
    source = true,
    border = "rounded",
  },
  severity_sort = true,
})

-- クリップボード（lemonade）- xは除外
if vim.fn.executable("lemonade") == 1 then
  vim.g.clipboard = {
    name = "lemonade",
    copy = {
      ["+"] = { "lemonade", "copy" },
      ["*"] = { "lemonade", "copy" },
    },
    paste = {
      ["+"] = { "lemonade", "paste" },
      ["*"] = { "lemonade", "paste" },
    },
    cache_enabled = 0,
  }
end
vim.opt.clipboard:prepend({ "unnamedplus" })

----------------------------------------------------------------------
--  キーマップ
----------------------------------------------------------------------
local map = vim.keymap.set

-- xだけはクリップボードを使わない（normal modeのみ）
map("n", "x", '"_x')

map("n", "<leader><Left>", "<C-w>h")
map("n", "<leader><Down>", "<C-w>j")
map("n", "<leader><Up>", "<C-w>k")
map("n", "<leader><Right>", "<C-w>l")
map("n", "j", "gj")
map("n", "k", "gk")
map("n", "<Down>", "gj")
map("n", "<Up>", "gk")

vim.cmd([[cnoreabbrev <expr> s getcmdtype() .. getcmdline() ==# ':s' ? [getchar(), ''][1] .. "%s///g<Left><Left><Left>" : 's']])
vim.cmd([[cnoreabbrev <expr> Q getcmdtype() .. getcmdline() ==# ':Q' ? 'qall' : 'Q']])
vim.cmd([[cnoreabbrev <expr> QF getcmdtype() .. getcmdline() ==# ':QF' ? 'qall!' : 'QF']])

----------------------------------------------------------------------
--  Autocmd
----------------------------------------------------------------------
-- 保存時に行末の空白を削除
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("TrimWhitespace", { clear = true }),
  pattern = "*",
  command = [[%s/\s\+$//e]],
})

-- カーソル下の診断を自動表示
vim.api.nvim_create_autocmd("CursorHold", {
  group = vim.api.nvim_create_augroup("DiagnosticFloat", { clear = true }),
  callback = function()
    vim.diagnostic.open_float(nil, { focus = false, scope = "cursor" })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("UserFileTypeConfig", { clear = true }),
  pattern = "javascript",
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("MarkdownFormat", { clear = true }),
  pattern = "markdown",
  callback = function(args)
    map("n", "<leader>q", function()
      local cursor = vim.api.nvim_win_get_cursor(0)
      vim.cmd("%!prettier --parser markdown")
      pcall(vim.api.nvim_win_set_cursor, 0, cursor)
    end, { buffer = args.buf })
  end,
})

vim.api.nvim_create_autocmd('QuitPre', {
  callback = function()
    local current_win = vim.api.nvim_get_current_win()
    local normal_bufs = vim.tbl_filter(function(win)
      return win ~= current_win and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == ''
    end, vim.api.nvim_list_wins())
    if #normal_bufs == 0 then
      vim.cmd.only({ bang = true })
    end
  end,
  desc = 'Close all special buffers and quit Neovim',
})
----------------------------------------------------------------------
--  LSP（ネイティブ API — プラグイン不要）
----------------------------------------------------------------------
vim.lsp.config.pyright = {
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "setup.py", "requirements.txt", ".git" },
  settings = { python = { analysis = { typeCheckingMode = "strict" } } },
}

vim.lsp.config.ruff = {
  cmd = { "ruff", "server" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
  settings = { ruff = { lineLength = 200 } },
}

vim.lsp.config.ts_ls = {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
}

vim.lsp.config.moonbit_lsp = {
  cmd = { "moonbit-lsp" },
  filetypes = { "moonbit" },
  root_markers = { "moon.mod.json", ".git" },
}

vim.lsp.enable({ "pyright", "ruff", "ts_ls", "moonbit_lsp" })

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local buf_map = function(mode, lhs, rhs)
      map(mode, lhs, rhs, { buffer = args.buf })
    end
    buf_map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end)
    buf_map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end)
    buf_map("n", "K", "<cmd>Lspsaga hover_doc<CR>")
    buf_map("n", "<leader>i", "<cmd>Lspsaga show_line_diagnostics<CR>")
    buf_map("n", "<leader>rn", "<cmd>Lspsaga rename<CR>")
    buf_map("n", "<leader>g", "<cmd>Lspsaga peek_definition<CR>")
    buf_map("n", "<leader>q", function() vim.lsp.buf.format({ timeout_ms = 5000 }) end)

    if client and client.name == "ruff" then
      client.server_capabilities.hoverProvider = false
    end
  end,
})

----------------------------------------------------------------------
--  lazy.nvim Bootstrap
----------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.runtimepath:prepend(lazypath)

----------------------------------------------------------------------
--  プラグイン
----------------------------------------------------------------------
require("lazy").setup({
  -- テーマ
  {
    "rebelot/kanagawa.nvim",
    priority = 1000,
    config = function()
      local sel_bg = "#2d5a7a"
      local border_fg = "#565c64"
      require("kanagawa").setup({
        colors = {
          theme = {
            all = {
              ui = {
                bg = BG,
                bg_gutter = BG,
              },
            },
          },
        },
        overrides = function()
          return {
            Visual = { bg = sel_bg },
            Search = { bg = sel_bg },
            IncSearch = { bg = sel_bg },
            CurSearch = { bg = sel_bg },
            CursorLine = { bg = sel_bg },
            TelescopePreviewMatch = { bg = sel_bg },
            TelescopeMatching = { bg = sel_bg },
            TelescopeSelection = { bg = sel_bg },

            StatusLine = { fg = BG, bg = BG },
            StatusLineNC = { fg = BG, bg = BG },
            MsgArea = { fg = BG, bg = BG },
            MsgSeparator = { fg = BG, bg = BG },

            DiagnosticUnderlineError = { undercurl = true, sp = "#e06c75" },
            DiagnosticUnderlineWarn = { undercurl = true, sp = "#e5c07b" },
            DiagnosticUnderlineInfo = { undercurl = true, sp = "#61afef" },
            DiagnosticUnderlineHint = { undercurl = true, sp = "#98c379" },

            NormalFloat = { bg = BG },
            FloatBorder = { fg = border_fg, bg = BG },
            NeoTreeNormalFloat = { bg = BG },
            NeoTreeFloatBorder = { fg = border_fg, bg = BG },
            NeoTreeFloatTitle = { fg = border_fg, bg = BG },
            TelescopeNormal = { bg = BG },
            TelescopeBorder = { fg = border_fg, bg = BG },
            NotifyBackground = { bg = BG },
            NoicePopup = { bg = BG },
            NoicePopupBorder = { fg = border_fg, bg = BG },
          }
        end,
      })
      vim.cmd("colorscheme kanagawa")
    end,
  },

  -- アイコン
  {
    "nvim-tree/nvim-web-devicons",
    opts = { color_icons = true, default = true },
  },

  -- incline.nvim
  {
    "b0o/incline.nvim",
    event = "VeryLazy",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      local devicons = require("nvim-web-devicons")
      local icons = { error = "󰅚 ", warn = "󰀪 ", hint = "󰌶 ", info = " " }
      local function get_diagnostic_label(props)
        local label = {}
        for severity, icon in pairs(icons) do
          local n = #vim.diagnostic.get(props.buf, { severity = vim.diagnostic.severity[string.upper(severity)] })
          if n > 0 then
            table.insert(label, { icon .. n .. " ", group = props.focused and ("DiagnosticSign" .. severity) or "Comment" })
          end
        end
        if #label > 0 then table.insert(label, { "┊ ", guifg = "#5c6370" }) end
        return label
      end

      require("incline").setup({
        highlight = {
          groups = {
            InclineNormal = { guibg = "#282c34", guifg = "#abb2bf" },
            InclineNormalNC = { guibg = "none", guifg = "#5c6370" },
          },
        },
        window = {
          margin = { horizontal = 0, vertical = 0 },
          placement = { horizontal = "right", vertical = "bottom" },
          padding = 2,
        },
        render = function(props)
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":.")
          local ft_icon, ft_color = devicons.get_icon_color(vim.fn.fnamemodify(filename, ":t"))
          local mode = vim.api.nvim_get_mode().mode
          local mode_map = {
            n = { label = "NORMAL", color = "#61afef" },
            i = { label = "INSERT", color = "#98c379" },
            v = { label = "VISUAL", color = "#c678dd" },
            V = { label = "V-LINE", color = "#c678dd" },
            ["\22"] = { label = "V-BLOCK", color = "#c678dd" },
            c = { label = "COMMAND", color = "#e5c07b" },
            R = { label = "REPLACE", color = "#e06c75" },
          }
          local mode_info = mode_map[mode] or { label = mode, color = "#abb2bf" }
          return {
            { get_diagnostic_label(props) },
            { (ft_icon or "") .. " ", guifg = ft_color },
            { filename .. " ", guifg = props.focused and "#abb2bf" or "#5c6370", gui = props.focused and "bold" or "" },
            { vim.bo[props.buf].modified and "● " or "", guifg = props.focused and "#e5c07b" or "#5c6370" },
            { "┊ ", guifg = "#5c6370" },
            { mode_info.label, guifg = props.focused and mode_info.color or "#5c6370", gui = "bold" },
          }
        end,
      })
    end,
  },

  -- LSP UI
  {
    "glepnir/lspsaga.nvim",
    event = "LspAttach",
    opts = { symbol_in_winbar = { enable = false } },
  },
  { "j-hui/fidget.nvim", event = "LspAttach", opts = {} },
  { "kevinhwang91/nvim-bqf", ft = "qf" },

  -- 補完
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "onsails/lspkind.nvim",
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        mapping = cmp.mapping.preset.insert({
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-e>"] = cmp.mapping.close(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "path" },
          { name = "buffer" },
        },
        formatting = {
          format = require("lspkind").cmp_format({
            mode = "symbol",
            maxwidth = 50,
            ellipsis_char = "...",
          }),
        },
      })
    end,
  },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>" },
      { "<leader>fw", "<cmd>Telescope live_grep<CR>" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>" },
    },
    dependencies = "nvim-lua/plenary.nvim",
    opts = function()
      local send_to_qf = function(bufnr)
        local actions = require("telescope.actions")
        actions.send_to_qflist(bufnr)
        actions.open_qflist(bufnr)
      end
      return {
        defaults = {
          mappings = {
            n = { ["<C-f>"] = send_to_qf },
            i = { ["<C-f>"] = send_to_qf },
          },
          prompt_prefix = "   ",
          selection_caret = "  ",
          entry_prefix = "  ",
          sorting_strategy = "ascending",
          layout_config = {
            horizontal = { prompt_position = "top", preview_width = 0.55 },
            width = 0.87,
            height = 0.80,
            preview_cutoff = 120,
          },
        },
      }
    end,
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      vim.treesitter.language.register("bash", "zsh")

      local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
      parser_config.moonbit = {
        install_info = {
          url = "https://github.com/moonbitlang/tree-sitter-moonbit",
          files = { "src/parser.c", "src/scanner.c" },
          branch = "main",
        },
        filetype = "moonbit",
      }

      require("nvim-treesitter.configs").setup({
        ensure_installed = { "regex", "bash", "lua", "python", "javascript", "typescript" },
        auto_install = true,
        highlight = { enable = true },
      })
    end,
  },

  -- ジャンプ
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end },
    },
    opts = {},
  },

  -- Surround
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    opts = {},
  },

  -- Git・インデント可視化
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
  },
  {
    "shellRaining/hlchunk.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      chunk = { enable = true },
      indent = { enable = true },
    },
  },

  -- UI拡張
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
    opts = {
      routes = {
        { filter = { event = "msg_show", kind = "", find = "written" }, opts = { skip = true } },
      },
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
      },
      presets = {
        command_palette = true,
        long_message_to_split = true,
        lsp_doc_border = true,
      },
    },
    config = function(_, opts)
      require("noice").setup(opts)
      require("notify").setup({ stages = "static" })
    end,
  },

  -- Filer
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    keys = { { "<leader>e", "<cmd>Neotree float<CR>" } },
    dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
    opts = {
      popup_border_style = "rounded",
      default_component_configs = {
        name = {
          use_git_status_colors = false,
        },
      },
      window = {
        popup = {
          position = { col = "50%", row = "50%" },
          size = { width = "50%", height = "80%" },
        },
        mappings = {
          ["u"] = "navigate_up",
        },
      },
      filesystem = {
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = false,
          hide_hidden = false,
          hide_by_name = { ".git", ".gitlab", ".vscode", ".pytest_cache", "__pycache__" },
        },
      },
    },
  },

  -- Trouble
  {
    "folke/trouble.nvim",
    keys = { { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>" } },
    dependencies = "nvim-tree/nvim-web-devicons",
    opts = {},
  },

  -- 括弧
  { "cohama/lexima.vim", event = "InsertEnter" },

  -- Markdownレンダリング
  {
    "delphinus/md-render.nvim",
    version = "*",
    dependencies = {
      { "nvim-tree/nvim-web-devicons", version = "*" },
      { "delphinus/budoux.lua", version = "*" },
    },
    keys = {
      { "<leader>mp", "<Plug>(md-render-preview)", desc = "Markdown preview (toggle)" },
      { "<leader>mt", "<Plug>(md-render-preview-tab)", desc = "Markdown preview in tab (toggle)" },
    },
  },

  -- リサイズ
  {
    "simeji/winresizer",
    keys = { { "<leader>wr", "<cmd>WinResizerStartResize<CR>" } },
    init = function()
      vim.api.nvim_create_user_command("WinR", "WinResizerStartResize", {})
    end,
  },
}, {
  checker = { enabled = false },
  change_detection = { enabled = false },
  rocks = { enabled = false },
})
