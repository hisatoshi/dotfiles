vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.laststatus = 3
vim.cmd 'colorscheme sonokai'

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

-- プラグインをインストール
require("packer").startup(function(use)
    -- パッケージマネージャ
    use "wbthomason/packer.nvim"

    -- 色々はいってるやつ
    use "nvim-lua/plenary.nvim"

    -- iconとか入っているやつ
    use "kyazdani42/nvim-web-devicons"

    -- Lsp関係
    use "neovim/nvim-lspconfig"
    use "williamboman/mason.nvim"
    use "williamboman/mason-lspconfig.nvim"
    use "chapel-lang/mason-registry"
    use "j-hui/fidget.nvim"

    -- 補完関係
    use "hrsh7th/nvim-cmp"
    use "hrsh7th/cmp-nvim-lsp"
    use "hrsh7th/cmp-vsnip"
    use "hrsh7th/cmp-buffer"
    use "hrsh7th/cmp-path"
    use "hrsh7th/vim-vsnip"

    -- git
    use "lewis6991/gitsigns.nvim"

    -- null-ls
    use { "jose-elias-alvarez/null-ls.nvim", requires = { "nvim-lua/plenary.nvim" } }

    -- fuzzyfinder
    use {"nvim-telescope/telescope.nvim", requires = { {"nvim-lua/plenary.nvim"} }}
    use {"nvim-telescope/telescope-file-browser.nvim"}

    -- TreeSitter
    use {"nvim-treesitter/nvim-treesitter", run = ":TSUpdate"}

    -- 括弧閉じる
    use "cohama/lexima.vim"

    -- ステータスライン
    use {"nvim-lualine/lualine.nvim", requires={ "kyazdani42/nvim-web-devicons", opt = true }}

    -- indent-lineが見えるやつ
    use "lukas-reineke/indent-blankline.nvim"

    -- テーマ
    use "sainnhe/sonokai"

    if packer_bootstrap then
      require("packer").sync()
    end

end)

-- LSPクライアントがバッファにアタッチされたときに実行される
local on_attach = function(client, bufnr)

  local set = vim.keymap.set
  set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
  set("n", "gD", "<cmd>lua vim.lsp.buf.type_definition()<CR>")
  set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
  set("n", "<space>rn", "<cmd>lua vim.lsp.buf.rename()<CR>")
  set("n", "<space>wa", "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>")
  set("n", "<space>wr", "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>")
  set("n", "<space>wl", "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>")
  set("n", "[d", "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>")
  set("n", "]d", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>")
  set("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>")
end

-- masonで管理されたLSPの設定
require("mason").setup()
require("mason-lspconfig").setup()
local lspconfig = require "lspconfig"
lspconfig.pyright.setup {
    on_attach = on_attach,
    settings = {
        python = {
	    analysis = {
                typeCheckingMode = "strict"
	    }
        }
    }
}
lspconfig.rust_analyzer.setup {
	on_attach = on_attach,
}

-- masonで管理されたLSP以外の設定
local mason_package = require"mason-core.package"
local mason_registry = require"mason-registry"
local null_ls = require "null-ls"
local null_sources = {}
for _, package in ipairs(mason_registry.get_installed_packages()) do
    local package_categories = package.spec.categories[1]
    if package_categories == mason_package.Cat.Formatter then
        table.insert(null_sources, null_ls.builtins.formatting[package.name])
    end
    if package_categories == mason_package.Cat.Linter then
	-- flake8にline_too_longを無視する設定を追加
	if package.name == "flake8" then
            table.insert(null_sources, null_ls.builtins.diagnostics.flake8.with({
                extra_args = {"--ignore=E501"}
            }))
	else
	    table.insert(null_sources, null_ls.builtins.diagnostics[package.name])
	end
    end
end
null_ls.setup ({
  sources = null_sources
})


-- 補完の設定
vim.opt.completeopt = "menu,menuone,noselect"
local cmp = require "cmp"
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
    }, {
        { name = "path" },
        { name = "buffer" },
  }),
}


-- fuzzy finderの設定
local builtin = require "telescope.builtin"
vim.keymap.set("n", "<space>ff", builtin.find_files, {})
vim.keymap.set("n", "<space>fw", builtin.live_grep, {})
vim.keymap.set("n", "<space>fb", builtin.buffers, {})
vim.keymap.set("n", "<space>e", ":Telescope file_browser<CR>", { noremap = true })

local telescope = require "telescope"
telescope.setup {
    extensions = {
        file_browser = {
            hijak_netrw = true
	}
    }
}
telescope.load_extension "file_browser"


-- その他の設定
require "nvim-treesitter.configs".setup {
  highlight = {
    enable = true,
    disable = {}
  }
}
require "indent_blankline".setup()
require "gitsigns".setup()
require "lualine".setup()
require "fidget".setup()
