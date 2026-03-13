----------------------------------------------------------------------
--  基本設定
----------------------------------------------------------------------
-- Provider無効化
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.python3_host_prog = vim.fn.expand("~/.python/venv/bin/python")

vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.swapfile = false
vim.opt.laststatus = 0
vim.opt.cmdheight = 0

vim.opt.statusline = " "
vim.opt.fillchars = { stl = "─", stlnc = "─" }
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.winblend = 0
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

-- 診断メッセージの表示設定
vim.diagnostic.config({
  virtual_text = false,
  float = {
    source = "always",
    border = "rounded",
  },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- ColorScheme後のハイライト設定
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    local bg = "#2d5a7a"
    local float_bg = "#2a2d3e"
    local border_fg = "#565c64"

    -- Visual mode背景色
    vim.api.nvim_set_hl(0, "Visual", { bg = bg })
    vim.api.nvim_set_hl(0, "Search", { bg = bg })
    vim.api.nvim_set_hl(0, "IncSearch", { bg = bg })
    vim.api.nvim_set_hl(0, "CurSearch", { bg = bg })
    vim.api.nvim_set_hl(0, "CursorLine", { bg = bg })
    vim.api.nvim_set_hl(0, "TelescopePreviewMatch", { bg = bg })
    vim.api.nvim_set_hl(0, "TelescopeMatching", { bg = bg })
    vim.api.nvim_set_hl(0, "TelescopeSelection", { bg = bg })

    -- ステータスライン（cmdheight=0起動時のちらつき防止）
    vim.api.nvim_set_hl(0, "StatusLine", { fg = float_bg, bg = float_bg })
    vim.api.nvim_set_hl(0, "StatusLineNC", { fg = float_bg, bg = float_bg })

    -- 診断のundercurl
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { undercurl = true, sp = "#e06c75" })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { undercurl = true, sp = "#e5c07b" })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", { undercurl = true, sp = "#61afef" })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { undercurl = true, sp = "#98c379" })

    -- float背景（ちらつき防止）
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = float_bg })
    vim.api.nvim_set_hl(0, "FloatBorder", { fg = border_fg, bg = float_bg })
    vim.api.nvim_set_hl(0, "NeoTreeNormalFloat", { bg = float_bg })
    vim.api.nvim_set_hl(0, "NeoTreeFloatBorder", { fg = border_fg, bg = float_bg })
    vim.api.nvim_set_hl(0, "NeoTreeFloatTitle", { fg = border_fg, bg = float_bg })
    vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = float_bg })
    vim.api.nvim_set_hl(0, "TelescopeBorder", { fg = border_fg, bg = float_bg })
    vim.api.nvim_set_hl(0, "NotifyBackground", { bg = float_bg })
    vim.api.nvim_set_hl(0, "NoicePopup", { bg = float_bg })
    vim.api.nvim_set_hl(0, "NoicePopupBorder", { fg = border_fg, bg = float_bg })
  end,
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

map("n", "<space><Left>", "<C-w>h")
map("n", "<space><Down>", "<C-w>j")
map("n", "<space><Up>", "<C-w>k")
map("n", "<space><Right>", "<C-w>l")
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

local filetype_tabstop = { javascript = 2 }
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("UserFileTypeConfig", { clear = true }),
  callback = function(args)
    local ftts = filetype_tabstop[args.match]
    if ftts then
      vim.bo.tabstop = ftts
      vim.bo.shiftwidth = ftts
    end
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
--  LSP on_attach
----------------------------------------------------------------------
local on_attach = function(client, bufnr)
  map("n", "[d", vim.diagnostic.goto_prev)
  map("n", "]d", vim.diagnostic.goto_next)
  map("n", "K", "<cmd>Lspsaga hover_doc<CR>")
  map("n", "<space>i", "<cmd>Lspsaga show_line_diagnostics<CR>")
  map("n", "<space>rn", "<cmd>Lspsaga rename<CR>")
  map("n", "<space>g", "<cmd>Lspsaga peek_definition<CR>")
  map("n", "<space>q", function() vim.lsp.buf.format({ timeout_ms = 5000 }) end)
end

----------------------------------------------------------------------
--  プラグイン
----------------------------------------------------------------------
require("lazy").setup({
  -- テーマ
  {
    "rebelot/kanagawa.nvim",
    priority = 1000,
    config = function()
      require("kanagawa").setup({
        colors = {
          theme = {
            all = {
              ui = {
                bg = "#2a2d3e",
                bg_gutter = "#2a2d3e",
              },
            },
          },
        },
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
          options = { winblend = 0 },
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

  -- LSP
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "glepnir/lspsaga.nvim",
      { "j-hui/fidget.nvim", opts = {} },
      { "kevinhwang91/nvim-bqf", ft = "qf" },
      "creativenull/efmls-configs-nvim",
    },
    config = function()
      require("lspsaga").setup({
        symbol_in_winbar = {
          enable = false,
        },
      })

      -- Pyright
      vim.lsp.config.pyright = {
        cmd = { "pyright-langserver", "--stdio" },
        filetypes = { "python" },
        root_markers = { "pyproject.toml", "setup.py", "requirements.txt", ".git" },
        settings = { python = { analysis = { typeCheckingMode = "strict" } } },
      }
      vim.lsp.enable("pyright")

      -- TypeScript
      vim.lsp.config.ts_ls = {
        cmd = { "typescript-language-server", "--stdio" },
        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
        root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
      }
      vim.lsp.enable("ts_ls")

      -- EFM
      local fs = require("efmls-configs.fs")
      local flake8 = require("efmls-configs.linters.flake8")
      flake8.lintCommand = string.format("%s --max-line-length 200 --ignore=W391,W503 -", fs.executable("flake8"))

      local languages = {
        python = { flake8, require("efmls-configs.formatters.black") },
        json = { require("efmls-configs.formatters.jq") },
      }

      vim.lsp.config.efm = {
        cmd = { "efm-langserver" },
        filetypes = vim.tbl_keys(languages),
        settings = { rootMarkers = { vim.fn.getcwd() }, languages = languages },
        init_options = { documentFormatting = true, documentRangeFormatting = true },
      }
      vim.lsp.enable("efm")

      -- on_attach設定
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          on_attach(nil, args.buf)
        end,
      })
    end,
  },

  -- 補完
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-vsnip",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/vim-vsnip",
      "onsails/lspkind.nvim",
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = { expand = function(args) vim.fn["vsnip#anonymous"](args.body) end },
        mapping = cmp.mapping.preset.insert({
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-e>"] = cmp.mapping.close(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "vsnip" },
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
      { "<space>ff", "<cmd>Telescope find_files<CR>" },
      { "<space>fw", "<cmd>Telescope live_grep<CR>" },
      { "<space>fb", "<cmd>Telescope buffers<CR>" },
    },
    dependencies = "nvim-lua/plenary.nvim",
    opts = {
      defaults = {
        mappings = {
          n = { ["<C-f>"] = function(bufnr)
            require("telescope.actions").send_to_qflist(bufnr)
            require("telescope.actions").open_qflist(bufnr)
          end },
          i = { ["<C-f>"] = function(bufnr)
            require("telescope.actions").send_to_qflist(bufnr)
            require("telescope.actions").open_qflist(bufnr)
          end },
        },
        winblend = 0,
        prompt_prefix = "   ",
        selection_caret = "  ",
        entry_prefix = "  ",
        initial_mode = "insert",
        selection_strategy = "reset",
        sorting_strategy = "ascending",
        layout_strategy = "horizontal",
        layout_config = {
          horizontal = { prompt_position = "top", preview_width = 0.55 },
          width = 0.87,
          height = 0.80,
          preview_cutoff = 120,
        },
      },
    },
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      highlight = { enable = true },
      auto_install = true,
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
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
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPost", "BufNewFile" },
    main = "ibl",
    opts = { scope = { enabled = false } },
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose" },
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
      presets = {
        command_palette = true,
        long_message_to_split = true,
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
    branch = "v2.x",
    keys = { { "<space>e", "<cmd>Neotree float<CR>" } },
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
          size = function(state)
            return {
              width = math.floor(vim.o.columns * 0.5),
              height = math.floor(vim.o.lines * 0.8),
            }
          end,
        },
        mappings = {
          ["u"] = "navigate_up",
        },
      },
      filesystem = {
        window = {
          popup = {
            position = { col = "50%", row = "50%" },
            size = function(state)
              return {
                width = math.floor(vim.o.columns * 0.5),
                height = math.floor(vim.o.lines * 0.8),
              }
            end,
          },
        },
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = false,
          hide_hidden = false,
          hide_by_name = { ".git", ".gitlab", ".vscode", ".pytest_cache", "__pycache__" },
        },
      },
    },
    config = function(_, opts)
      require("neo-tree").setup(opts)
    end,
  },

  -- メモ
  { "glidenote/memolist.vim", cmd = { "MemoNew", "MemoList" } },

  -- Trouble
  {
    "folke/trouble.nvim",
    keys = { { "<space>xx", "<cmd>Trouble diagnostics toggle<CR>" } },
    dependencies = "nvim-tree/nvim-web-devicons",
    opts = {},
  },

  -- 括弧
  { "cohama/lexima.vim", event = "InsertEnter" },

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
