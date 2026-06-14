---@module "lazy_delver.room"

local C = require("lazy_delver.const")
local log = require("lazy_delver.log")
local map = require("lazy_delver.map")

local M = {}

---@param offset integer
---@param dir LD_Dir
---@param w integer
---@return integer
local function door_gid(offset, dir, w)
  local ox = (offset % C.MAP.COLS == 0) and 0 or 13
  local oy = (offset // C.MAP.COLS) * 7

  if     dir == C.DIR.LEFT  then return (oy + 4) * w + (ox + 1)
  elseif dir == C.DIR.RIGHT then return (oy + 4) * w + (ox + 13)
  elseif dir == C.DIR.UP    then return (oy + 1) * w + (ox + 7)
  elseif dir == C.DIR.DOWN  then return (oy + 7) * w + (ox + 7)
  else error("invalid dir: " .. dir) end
end

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

---@param room LD_Room
---@param neighbors LD_RoomNeighbors
local function check(room, neighbors)
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

  for _, n in pairs(neighbors) do
    if not map.cells[n.cid] then goto continue end

    local cid = n.cid - C.CELL.DIR_OFFSETS[n.dir]
    local d_gid = door_gid(cid - room.tf_cid, n.dir, w)
    if visited[d_gid // w][d_gid % w] then
      map.cells[n.cid].neighbors_to_check[C.DIR_REVERSE[n.dir]] = nil
    else
      if map.cells[n.cid].category == C.CELL.CATEGORY.CANDIDATE then
        map.cells[n.cid] = nil
      else
        log.error("Try to remove a non-candidate room: ")
        log.print_room(map.cells[n.cid].lid, map):error()
      end
    end

    ::continue::
  end
end

function M.check()
  if map.has_changed() then
    map.reload()
  end
  if map.is_ignored() then return end

  local lid = Game():GetLevel():GetCurrentRoomDesc().ListIndex
  local neighbors = map.get_neighbors_to_check(lid)
  log.info("=== Entered New Room ===")
  log.print_room(lid, map):info()
  log.print_neighbors_to_check(neighbors):info()

  local room = map.rooms[lid]
  check(room, neighbors)

  log.draw_map(map):info()
end

return M
