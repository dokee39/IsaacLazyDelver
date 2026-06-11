local map = require("lazy_delver.map")

local M = {}

function M.check()
  if map.has_changed() then
    map.reload()
  end
end

return M
