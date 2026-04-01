return {
  {
    "danymat/neogen",
    cmd = "Neogen",
    dependencies = { "L3MON4D3/LuaSnip", version = "v2.*" },
    keys = {
      {
        "<leader>ne",
        function()
          require("neogen").generate()
        end,
        desc = "Neogen Comment",
      },
    },
    opts = {
      snippet_engine = "luasnip",
      input_after_comment = false,
      languages = {
        python = {
          template = {
            annotation_convention = "google_docstrings",
          },
        },
        go = {
          template = {
            annotation_convention = "godoc",
          },
        },
        lua = {
          template = {
            annotation_convention = "emmylua",
          },
        },
      },
    },
  },
}
