return {
  {
    "cameron-wags/rainbow_csv.nvim",
    ft = {
      "csv",
      "tsv",
      "csv_semicolon",
      "csv_whitespace",
      "csv_pipe",
      "rfc_csv",
      "rfc_semicolon",
    },
    module = {
      "rainbow_csv",
      "rainbow_csv.fns",
    },
    opts = {},
  },
  {
    "hat0uma/csvview.nvim",
    cmd = "CsvViewEnable",
    config = function()
      require("csvview").setup()
    end,
  },
}
