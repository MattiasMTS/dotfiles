return {
  -- disable <C-k> lsp function signature -> prefer to use it for cmp navigation
  {
    "neovim/nvim-lspconfig",
    opts = function()
      local Keys = require("lazyvim.plugins.lsp.keymaps").get()
      vim.list_extend(Keys, {
        {
          "<c-k>",
          false,
          mode = "i",
          desc = "Signature Help",
          has = "signatureHelp",
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = { virtual_text = { prefix = "icons" } },
      inlay_hints = { enabled = false },
      capabilities = {
        workspace = {
          didChangeWatchedFiles = {
            dynamicRegistration = false,
          },
        },
      },
      servers = {
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = { globals = { "vim" }, disable = { "different-requires" } },
              workspace = { checkThirdParty = false },
              completion = { callSnippet = "Replace" },
            },
          },
        },
        terraformls = {},
        helm_ls = {},
        gopls = {
          filetypes = { "go", "gomod", "gowork", "gotmpl" },
          settings = {
            -- env = { GOEXPERIMENT = "rangefunc" },
            formatting = { gofumpt = false }, -- managed by conform
            -- https://github.com/golang/tools/blob/master/gopls/doc/inlayHints.md
            hints = {},
          },
        },
        kotlin_language_server = {
          root_dir = function(name)
            return require("lspconfig").util.root_pattern("settings.gradle.kts", "build.gradle.kts", ".git")(name)
              or vim.fn.getcwd()
          end,
          single_file_support = true,
          init_options = { storagePath = "/tmp/kotlin-language-server" },
        },
      },
    },
  },

  -- handle installation of linters, formatters etc
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "actionlint",
        "bash-language-server",
        "codelldb",
        "debugpy",
        "delve",
        "docker-compose-language-service",
        "dockerfile-language-server",
        "gofumpt",
        "goimports",
        "golangci-lint",
        "golines",
        "gopls",
        "gotests",
        "graphql-language-service-cli",
        "hadolint",
        "hclfmt",
        "helm-ls",
        "html-lsp",
        "java-debug-adapter",
        "java-test",
        "jdtls",
        "js-debug-adapter",
        "json-lsp",
        "jsonnet-language-server",
        "kotlin-debug-adapter",
        "kotlin-language-server",
        "ktfmt",
        "ktlint",
        "lua-language-server",
        "markdown-toc",
        -- "markdownlint",
        "markdownlint-cli2",
        "marksman",
        "nil",
        "nixpkgs-fmt",
        -- "opa",
        "prettier",
        "pyright",
        "ruff",
        -- "ruff-lsp",
        "shellcheck",
        "shfmt",
        "sqlfmt",
        "stylua",
        "tailwindcss-language-server",
        "taplo",
        "terraform-ls",
        "tflint",
        "tfsec",
        "typescript-language-server",
        "vim-language-server",
        "vtsls",
        "yaml-language-server",
        "yamllint",
      })
    end,
  },
}
