return {
  {
    "rachartier/tiny-cmdline.nvim",
    opts = {

      width = {
        value = "60%", -- "N%" = fraction of editor columns, integer = absolute columns
        min = 40, -- minimum width in columns
        max = 80, -- maximum width in columns
      },

      -- Window position ("N%" = fraction of available space, integer = absolute columns/rows)
      position = {
        x = "50%", -- horizontal: "0%" = left, "50%" = center, "100%" = right
        y = "10%", -- vertical:   "0%" = top,  "50%" = center, "100%" = bottom
      },
    },
  },
}
