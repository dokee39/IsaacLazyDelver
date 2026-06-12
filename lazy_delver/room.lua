---@module "lazy_delver.room"

local C = require("lazy_delver.const")
local log = require("lazy_delver.log")
local map = require("lazy_delver.map")

local M = {}

function M.check()
  if map.has_changed() then
    map.reload()
  end
  if map.is_ignored() then return end

  local lid = Game():GetLevel():GetCurrentRoomDesc().ListIndex
  local neighbors = map.get_neighbors_to_check(lid)
  log.info("=== Entered New Room ===")
  log.print_room(lid, map)
  log.print_neighbors_to_check(neighbors)



  log.info("")
end

return M
