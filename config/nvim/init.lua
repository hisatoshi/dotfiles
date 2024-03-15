-- 見た目の調整
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.swapfile = false
vim.opt.laststatus = 3
vim.opt.tabstop=4
vim.opt.shiftwidth=4
vim.opt.expandtab = true
vim.opt.winblend = 5
vim.wo.signcolumn="number"
vim.opt.winblend = 5
vim.opt.smartcase = true
vim.opt.ignorecase = true

-- 絶妙な設定
-- (required:https://github.com/equalsraf/win32yank)
vim.opt.clipboard:prepend {"unnamedplus"}
if vim.fn.has("wsl") then
  vim.g.clipboard = {
    name = "win32yank-wsl",
    copy = {
      ["+"] = "win32yank.exe -i",
      ["*"] = "win32yank.exe -i"
    },
    paste = {
      ["+"] = "win32yank.exe -o",
      ["*"] = "win32yank.exe -of"
    },
    cache_enable = 0,
  }
end

-- 必須のキーマップ
vim.keymap.set("n", "<space>h", "<C-w>h")
vim.keymap.set("n", "<space>j", "<C-w>j")
vim.keymap.set("n", "<space>k", "<C-w>k")
vim.keymap.set("n", "<space>l", "<C-w>l")
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")


-- packer.nvimを自動でインストール
local install_path = vim.fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"
local packer_bootstrap = nil
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    packer_bootstrap = vim.fn.system {
        "git",
        "clone",
        "--depth",
        "1",
        "https://github.com/wbthomason/packer.nvim",
        install_path,
    }
end


-- 置換を楽にするやつ
-- https://zenn.dev/vim_jp/articles/2023-06-30-vim-substitute-tips
vim.cmd [[
    cnoreabbrev <expr> s getcmdtype() .. getcmdline() ==# ':s' ? [getchar(), ''][1] .. "%s///g<Left><Left>" : 's'
]]

-- プラグインをインストール
require("packer").startup(function(use)
    -- パッケージマネージャ
    use "wbthomason/packer.nvim"

    -- iconを追加
    use "nvim-tree/nvim-web-devicons"

    -- Lsp関係
    use "neovim/nvim-lspconfig"
    use "glepnir/lspsaga.nvim"
    use "j-hui/fidget.nvim"
    use "kevinhwang91/nvim-bqf"
    use {"creativenull/efmls-configs-nvim", requires = {"neovim/nvim-lspconfig"}}

    -- 補完関係
    use "hrsh7th/nvim-cmp"
    use "hrsh7th/cmp-nvim-lsp"
    use "hrsh7th/cmp-vsnip"
    use "hrsh7th/cmp-buffer"
    use "hrsh7th/cmp-path"
    use "hrsh7th/vim-vsnip"
    use "onsails/lspkind.nvim"

    -- git
    use "lewis6991/gitsigns.nvim"

    -- fuzzyfinder
    use {"nvim-telescope/telescope.nvim", requires = { {"nvim-lua/plenary.nvim"} }}

    -- TreeSitter
    use {"nvim-treesitter/nvim-treesitter", run = ":TSUpdate"}

    -- surround
    use {
        "kylechui/nvim-surround",
        tag = "*",
        config = function()
            require("nvim-surround").setup({}) end
    }

    -- ステータスライン
    use {"nvim-lualine/lualine.nvim", requires={ "nvim-tree/nvim-web-devicons", opt = true }}

    -- indent
    use "lukas-reineke/indent-blankline.nvim"

    -- テーマ
    -- use "sainnhe/sonokai"
    -- use { "catppuccin/nvim", as = "catppuccin" }
    use {"kaiuri/nvim-juliana", config = function() require "nvim-juliana".setup{} end}

    -- かっこよくするやつ
    use({ "folke/noice.nvim", requires = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify", } })

    -- filer
    vim.g.tree_remove_legacy_commands = 1
    use { "nvim-neo-tree/neo-tree.nvim", branch = "v2.x", requires = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim"}}

    -- 飛ぶやつ
    use { "phaazon/hop.nvim", branch = "v2"}

    -- メモるやつ
    use "glidenote/memolist.vim"

    -- エラー出るやつ
    use { "folke/trouble.nvim", requires = "nvim-tree/nvim-web-devicons"}

    -- lspの色
    use "folke/lsp-colors.nvim"

    -- scroll-bar
    use "petertriho/nvim-scrollbar"

    -- 括弧
    use "cohama/lexima.vim"

    if packer_bootstrap then
        require("packer").sync()
    end

end)


-- LSPクライアントがバッファにアタッチされたときに実行される
local on_attach = function(_, _)
    require "lspsaga".setup()
    local set = vim.keymap.set
    set("n", "[d", "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>")
    set("n", "]d", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>")
    set("n", "K", "<cmd>Lspsaga hover_doc<CR>")
    set("n", "<space>i", "<cmd>Lspsaga show_line_diagnostics<CR>")
    set("n", "<space>rn", "<cmd>Lspsaga rename<CR>")
    set("n", "<space>g", "<cmd>Lspsaga peek_definition<CR>")
    set("n", "<space>q", function() vim.lsp.buf.format({ timeout_ms = 5000 }) end)
end

local lspconfig = require "lspconfig"
lspconfig.pyright.setup {
    on_attach = on_attach,
    settings = {
        python = {
            analysis = {
                typeCheckingMode = "basic"
            }
        },
    }
}
local fs = require("efmls-configs.fs")
local flake8 = require("efmls-configs.linters.flake8")
local black = require("efmls-configs.formatters.black")
local jq = require("efmls-configs.formatters.jq")

-- 中身を見て気に入らなかったら色々とここで書き換える
-- print(flake8.lintCommand)
flake8.lintCommand = string.format('%s --max-line-length 200 -', fs.executable("flake8"))

local languages = {
    python = {flake8, black},
    json = {jq}
}
local efmls_config = {
    filetypes = vim.tbl_keys(languages),
    settings = {
        rootMarkers = {vim.fn.getcwd()},
        languages = languages
    },
    init_options = {
        documentFormatting = true,
        documentRangeFormatting = true
    }
}
lspconfig.efm.setup(vim.tbl_extend("force", efmls_config, {
    --- settings = { languages = { python = { lintCommand = "flake8 --max-line-length 200 -" } } }
}))

-- 補完の設定
vim.opt.completeopt = "menu,menuone,noselect"
local cmp = require "cmp"
local lspkind = require "lspkind"
cmp.setup {
    snippet = {
        expand = function(args)
            vim.fn["vsnip#anonymous"](args.body)
        end,
    },
    mapping = {
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<C-n>"] = cmp.mapping.select_next_item(),
        ["<C-e>"] = cmp.mapping.close(),
        ["<CR>"] = cmp.mapping.confirm { select = true },
    },
    sources = cmp.config.sources({
            { name = "nvim_lsp" },
            { name = "vsnip" },
            { name = "path" },
            { name = "buffer" },
    }),
    formatting = {
        format = lspkind.cmp_format({
              mode = 'symbol',
              maxwidth = 50,
              ellipsis_char = '...',
        })
    }
}


-- fuzzy finderの設定
local builtin = require "telescope.builtin"
vim.keymap.set("n", "<space>ff", builtin.find_files, {})
vim.keymap.set("n", "<space>fw", builtin.live_grep, {})
vim.keymap.set("n", "<space>fb", builtin.buffers, {})
local telescope = require "telescope"
local telescope_actions = require "telescope.actions"
telescope.setup {
    defaults = {
        mappings = {
            n = {
                ["<C-f>"] = telescope_actions.send_to_qflist + telescope_actions.open_qflist,
            },
            i = {
                ["<C-f>"] = telescope_actions.send_to_qflist + telescope_actions.open_qflist,
            }
        },
        pickers = {
        },
        winblend = 4,
        prompt_prefix = "   ",
        selection_caret = "  ",
        entry_prefix = "  ",
        initial_mode = "insert",
        selection_strategy = "reset",
        sorting_strategy = "ascending",
        layout_strategy = "horizontal",
        layout_config = {
          horizontal = {
            prompt_position = "top",
            preview_width = 0.55,
            results_width = 0.8,
          },
          vertical = {
            mirror = false,
          },
          width = 0.87,
          height = 0.80,
          preview_cutoff = 120,
        },
    },
}

local hop = require"hop"
hop.setup { keys = "etovxqpdygfblzhckisuran"}
vim.keymap.set('', 'f', function() hop.hint_char2({ hint_offset = 1}) end, {remap=true})


-- その他の設定
vim.keymap.set("n", "<space>e", ":Neotree float<CR>")
require "neo-tree".setup {
    filesystem = {
        filtered_items = {
            hide_dotfiles = false,
            hide_gitignored = false,
            hide_hidden = false,
            hide_by_name = {
                ".git",
                ".gitlab",
                ".vscode",
                ".pytest_cache",
                "__pycache__",
            }
        }
    }
}

require "nvim-web-devicons".setup {
    color_icons = true,
    default = true
}

require "nvim-treesitter.configs".setup {
    ensure_installed = {"python", "vim", "regex", "lua", "bash", "markdown", "markdown_inline", "rust"},
    highlight = {
        enable = true,
        disable = {}
    },
}

require('lualine').setup{
    options = {
      globalstatus = true
    },
    sections = {
      lualine_c = {{'filename', path = 1}}
    }
}

require("noice").setup({
    routes = {
        {
            filter = {
                event = "msg_show",
                kind = "",
                find = "written"
            },
            opts = {skip = true},
        }
    },
    presets = {
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = false,
    },
})

require("ibl").setup({
    scope = {enabled = false}

})

require "scrollbar".setup()
require "gitsigns".setup()
require "fidget".setup()
require "trouble".setup()
require "lsp-colors".setup()

-- color scheme--
-- vim.cmd "colorscheme catppuccin-frappe"
vim.cmd "colorscheme juliana"
