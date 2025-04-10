--- Helper function to pretty print lua objects
---@param v any
---@return any
function P(v)
  print(vim.inspect(v))
  return v
end

---  Helper function to reload lua modules
---@param name any
---@return any
function R(name)
  require("plenary.reload").reload_module(name)
  return require(name)
end
