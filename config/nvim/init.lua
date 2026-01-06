----------------------------------------------------------------------
--  基本設定
----------------------------------------------------------------------
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.swapfile = false
vim.opt.laststatus = 0
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
    -- Visual mode背景色
    local bg = "#2d5a7a"
    vim.api.nvim_set_hl(0, "Visual", { bg = bg })
    vim.api.nvim_set_hl(0, "Search", { bg = bg })
    vim.api.nvim_set_hl(0, "IncSearch", { bg = bg })
    vim.api.nvim_set_hl(0, "CurSearch", { bg = bg })
    vim.api.nvim_set_hl(0, "CursorLine", { bg = bg })
    vim.api.nvim_set_hl(0, "TelescopePreviewMatch", { bg = bg })
    vim.api.nvim_set_hl(0, "TelescopeMatching", { bg = bg })
    vim.api.nvim_set_hl(0, "TelescopeSelection", { bg = bg })
    
    -- 診断のundercurl
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { undercurl = true, sp = "#e06c75" })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { undercurl = true, sp = "#e5c07b" })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", { undercurl = true, sp = "#61afef" })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { undercurl = true, sp = "#98c379" })
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

vim.cmd([[cnoreabbrev <expr> s getcmdtype() .. getcmdline() ==# ':s' ? [getchar(), ''][1] .. "%s///g<Left><Left>" : 's']])

----------------------------------------------------------------------
--  Autocmd
----------------------------------------------------------------------
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
local on_attach = function(_, _)
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
    lazy = true,
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
          local bufname = vim.api.nvim_buf_get_name(props.buf)
          local filename = vim.fn.fnamemodify(bufname, ":t")
          local cwd = vim.fn.getcwd()
          local filepath = bufname:find(cwd, 1, true) == 1 and bufname:sub(#cwd + 2) or bufname
          local dirname = filepath:sub(1, -(#filename + 1))
          local ft_icon, ft_color = devicons.get_icon_color(filename)
          local has_error = #vim.diagnostic.get(props.buf, { severity = vim.diagnostic.severity.ERROR }) > 0
          local is_readonly = vim.bo[props.buf].readonly
          local fg = props.focused and (has_error and "#e06c75" or (is_readonly and "#5c6370" or "#abb2bf")) or "#5c6370"
          return {
            { get_diagnostic_label(props) },
            { ft_icon and ft_icon .. " " or "", guifg = props.focused and ft_color or "#5c6370" },
            { is_readonly and " " or "", guifg = fg },
            { dirname, guifg = props.focused and "#7c8390" or "#5c6370" },
            { filename, guifg = fg, gui = props.focused and "bold" or "" },
            { vim.bo[props.buf].modified and " ●" or "", guifg = props.focused and "#e5c07b" or "#5c6370" },
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
      require("lspsaga").setup()

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
        winblend = 4,
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
      parser_install_dir = vim.fn.stdpath("data") .. "/treesitter",
    },
    config = function(_, opts)
      vim.opt.runtimepath:append(opts.parser_install_dir)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  -- Surround
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    opts = {},
  },

  -- インデント可視化
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPost", "BufNewFile" },
    main = "ibl",
    opts = { scope = { enabled = false } },
  },

  -- Git
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
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
      vim.api.nvim_set_hl(0, "NeoTreeFloatBorder", { fg = "#2a2d3e", bg = "#2a2d3e" })
      vim.api.nvim_set_hl(0, "NeoTreeFloatTitle", { fg = "#2a2d3e", bg = "#2a2d3e" })
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

  -- スクロールバー
  { "petertriho/nvim-scrollbar", event = "BufReadPost", opts = {} },

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

  -- Markdown
  {
    "OXY2DEV/markview.nvim",
    ft = { "markdown", "markdown.mdx" },
    opts = {
      markdown = { headings = require("markview.presets").headings.slanted },
    },
  },
}, {
  checker = { enabled = false },
  change_detection = { enabled = false },
})
