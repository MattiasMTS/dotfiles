---@type vim.lsp.Config
local root_files = {
  "settings.gradle", -- Gradle (multi-project)
  "settings.gradle.kts", -- Gradle (multi-project)
  "build.xml", -- Ant
  "pom.xml", -- Maven
  "build.gradle", -- Gradle
  "build.gradle.kts", -- Gradle
}

---@type vim.lsp.Config
return {
  cmd = { "kotlin-language-server" },
  filetypes = { "kotlin" },
  root_markers = root_files,
  init_options = {
    -- Enables caching and use project root to store cache data.
    storagePath = vim.fs.root(vim.fn.expand("%:p:h"), root_files),
  },
}
