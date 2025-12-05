----------------------------------------------------------------------
--  基本設定
----------------------------------------------------------------------
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.swapfile = false
vim.opt.laststatus = 3
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.winblend = 5
vim.opt.signcolumn = "yes"
vim.opt.smartcase = true
vim.opt.ignorecase = true
vim.opt.completeopt = "menu,menuone,noselect"

-- クリップボード（WSL）
vim.opt.clipboard:prepend({ "unnamedplus" })
if vim.fn.has("wsl") == 1 then
  vim.g.clipboard = {
    name = "win32yank-wsl",
    copy = { ["+"] = "win32yank.exe -i", ["*"] = "win32yank.exe -i" },
    paste = { ["+"] = "win32yank.exe -o", ["*"] = "win32yank.exe -o" },
    cache_enable = 0,
  }
end

----------------------------------------------------------------------
--  キーマップ
----------------------------------------------------------------------
local map = vim.keymap.set
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
  require("lspsaga").setup()
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
    "olimorris/onedarkpro.nvim",
    priority = 1000,
    config = function() vim.cmd("colorscheme onedark") end,
  },

  -- アイコン
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
    opts = { color_icons = true, default = true },
  },

  -- ステータスライン
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = "nvim-tree/nvim-web-devicons",
    opts = {
      options = { globalstatus = true, theme = "eldritch" },
      sections = { lualine_c = { { "filename", path = 1 } } },
    },
  },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "glepnir/lspsaga.nvim",
      "j-hui/fidget.nvim",
      "kevinhwang91/nvim-bqf",
      "creativenull/efmls-configs-nvim",
    },
    config = function()
      local lspconfig = require("lspconfig")

      -- Pyright
      lspconfig.pyright.setup({
        on_attach = on_attach,
        settings = { python = { analysis = { typeCheckingMode = "strict" } } },
      })

      -- TypeScript
      local ts_server = lspconfig.ts_ls or lspconfig.tsserver
      if ts_server then
        ts_server.setup({ on_attach = on_attach })
      end

      -- EFM
      local fs = require("efmls-configs.fs")
      local flake8 = require("efmls-configs.linters.flake8")
      flake8.lintCommand = string.format("%s --max-line-length 200 --ignore=W391,W503 -", fs.executable("flake8"))

      local languages = {
        python = { flake8, require("efmls-configs.formatters.black") },
        json = { require("efmls-configs.formatters.jq") },
      }

      lspconfig.efm.setup({
        filetypes = vim.tbl_keys(languages),
        settings = { rootMarkers = { vim.fn.getcwd() }, languages = languages },
        init_options = { documentFormatting = true, documentRangeFormatting = true },
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
      ensure_installed = { "python", "vim", "regex", "lua", "bash", "markdown", "markdown_inline", "rust" },
      highlight = { enable = true },
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

  -- メモ
  { "glidenote/memolist.vim", cmd = { "MemoNew", "MemoList" } },

  -- Trouble
  {
    "folke/trouble.nvim",
    keys = { { "<space>xx", "<cmd>Trouble diagnostics toggle<CR>" } },
    dependencies = "nvim-tree/nvim-web-devicons",
    opts = {},
  },

  -- LSP Colors
  { "folke/lsp-colors.nvim", event = "VeryLazy", opts = {} },

  -- スクロールバー
  { "petertriho/nvim-scrollbar", event = "VeryLazy", opts = {} },

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

  -- Fidget
  { "j-hui/fidget.nvim", event = "VeryLazy", opts = {} },
}, {
  checker = { enabled = true },
  change_detection = { enabled = true, notify = false },
})
