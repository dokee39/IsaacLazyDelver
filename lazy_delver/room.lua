---@module "lazy_delver.room"

local C = require("lazy_delver.const")
local state = require("lazy_delver.state")
local log = require("lazy_delver.log")
local map = require("lazy_delver.map")

local M = {}

local BOMB_RADIUS = 80


---@param room_obj Room
---@return { w: integer, h: integer, [integer]: { [integer]: boolean } }
local function make_grid(room_obj)
  local w, h = room_obj:GetGridWidth(), room_obj:GetGridHeight()
  local size = room_obj:GetGridSize()
  local grid = { w = w, h = h }
  for r = 0, h - 1 do grid[r] = {} end

  for gid = 0, size - 1 do
    local ge = room_obj:GetGridEntity(gid)
    if ge and not C.GRID_ENTITY.NOT_BLOCKED[ge:GetType()] then
      grid[gid // w][gid % w] = true
    end
  end

  for _, re in ipairs(Isaac.GetRoomEntities()) do
    if C.ROOM_ENTITY.IS_BLOCKED[re.Type] then
      local gid = re.SpawnGridIndex
      if gid >= 0 and gid < size then
        grid[gid // w][gid % w] = true
      end
    end
  end

  return grid
end

---@param visited { [integer]: { [integer]: boolean } }
---@param grid { w: integer, h: integer, [integer]: { [integer]: boolean } }
---@param r integer
---@param c integer
local function dfs(visited, grid, r, c)
  if r < 0 or r >= grid.h or c < 0 or c >= grid.w then return end
  if visited[r][c] then return end
  if grid[r][c] then return end
  visited[r][c] = true
  dfs(visited, grid, r - 1, c)
  dfs(visited, grid, r + 1, c)
  dfs(visited, grid, r, c - 1)
  dfs(visited, grid, r, c + 1)
end

function M.obstacle_check()
  if state.has_changed() then map.reload() end
  if state.is_ignored() then return end

  local lid = Game():GetLevel():GetCurrentRoomDesc().ListIndex
  log.info("=== Entered New Room ===")
  local room = map.rooms[lid]
  if not room then
    log.info("list id: " .. lid)
    log.info("")
    return
  end

  local room_obj = Game():GetRoom()
  local w, h = room_obj:GetGridWidth(), room_obj:GetGridHeight()
  local size = room_obj:GetGridSize()
  local grid = make_grid(room_obj)

  local visited = {}
  for r = 0, h - 1 do visited[r] = {} end
  for gid = 0, size - 1 do
    local ge = room_obj:GetGridEntity(gid)
    if ge and ge:GetType() == GridEntityType.GRID_DOOR then
      local r, c = gid // w, gid % w
      if r == 0      then dfs(visited, grid, 1,     c) end
      if r == h - 1  then dfs(visited, grid, h - 2, c) end
      if c == 0      then dfs(visited, grid, r,     1) end
      if c == w - 1  then dfs(visited, grid, r, w - 2) end
    end
  end

  for cid, cand in pairs(map.candidates) do
    for _, entry in pairs(cand.entries) do
      if entry.source_lid ~= lid or entry.checked then
        goto continue
      end

      local door_pos = room_obj:GetDoorSlotPosition(entry.doorslot)
      local door_gid = room_obj:GetGridIndex(door_pos)
      if door_gid >= 0 and visited[door_gid // w][door_gid % w]
        and room_obj:IsDoorSlotAllowed(entry.doorslot) then
        entry.checked = true
      elseif cand.lid == nil then
        map.candidates[cid] = nil
        break
      else
        log.error("Try to remove a real secret room: ")
        log.print_room(cand.lid, map):error()
      end

      ::continue::
    end
  end

  log.print_room(lid, map):info()
end

---@param effect EntityEffect
function M.bomb_check(effect)
  if state.is_ignored() then return end

  local lid = Game():GetLevel():GetCurrentRoomDesc().ListIndex
  local room = map.rooms[lid]
  if not room then return end

  local room_obj = Game():GetRoom()
  local bomb_pos = effect.Position
  local bomb_gid = room_obj:GetGridIndex(bomb_pos)
  if bomb_gid < 0 then return end

  for cid, cand in pairs(map.candidates) do
    for _, entry in pairs(cand.entries) do
      if entry.source_lid ~= lid then
        goto continue
      end

      if cand.lid ~= nil then
        map.clear_fake_if_all_found()
        goto next_cand
      end

      local door_pos = room_obj:GetDoorSlotPosition(entry.doorslot)
      local dist = (bomb_pos - door_pos):Length()
      if dist < BOMB_RADIUS then
        map.candidates[cid] = nil
        return
      end

      ::continue::
    end
    ::next_cand::
  end
end

return M
