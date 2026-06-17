---@module "lazy_delver.room"

local C = require("lazy_delver.const")
local state = require("lazy_delver.state")
local log = require("lazy_delver.log")
local map = require("lazy_delver.map")

local M = {}

local BOMB_RADIUS = 80

---@param offset integer
---@param dir LD_Dir
---@param w integer
---@return integer
local function door_gid(offset, dir, w)
  local r = (offset // C.MAP.COLS) * 7
  local c = (offset % C.MAP.COLS == 0) and 0 or 13

  if     dir == C.DIR.LEFT  then return (r + 4) * w + (c + 1)
  elseif dir == C.DIR.RIGHT then return (r + 4) * w + (c + 13)
  elseif dir == C.DIR.UP    then return (r + 1) * w + (c + 7)
  elseif dir == C.DIR.DOWN  then return (r + 7) * w + (c + 7)
  else error("invalid dir: " .. dir) end
end

---@param dir LD_Dir
---@param offset integer
---@return DoorSlot
local function dir_to_doorslot(dir, offset)
  local row = offset // C.MAP.COLS
  if dir == C.DIR.LEFT then
    return row == 0 and DoorSlot.LEFT0 or DoorSlot.LEFT1
  elseif dir == C.DIR.RIGHT then
    return row == 0 and DoorSlot.RIGHT0 or DoorSlot.RIGHT1
  elseif dir == C.DIR.UP then
    local col = offset % C.MAP.COLS
    return col == 0 and DoorSlot.UP0 or DoorSlot.UP1
  elseif dir == C.DIR.DOWN then
    local col = offset % C.MAP.COLS
    return col == 0 and DoorSlot.DOWN0 or DoorSlot.DOWN1
  end
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
local function obstacle_check(room, neighbors)
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
    local d_gid = door_gid(cid - room.tl_cid, n.dir, w)
    local slot = dir_to_doorslot(n.dir, cid - room.tl_cid)

    if visited[d_gid // w][d_gid % w] and room_obj:IsDoorSlotAllowed(slot) then
      map.cells[n.cid].candidate_info
        .neighbors_to_check[C.DIR_REVERSE[n.dir]] = nil
      goto continue
    end

    if map.cells[n.cid].category == C.CELL.CATEGORY.FAKE then
      map.cells[n.cid] = nil
    else
      log.error("Try to remove a real secret room: ")
      log.print_room(map.cells[n.cid].lid, map):error()
    end

    ::continue::
  end
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

  local neighbors = map.get_candidate_neighbors(lid)
  obstacle_check(room, neighbors)

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

  for _, cid in pairs(room.cids) do
    local neighbors = map.get_neighbors(cid)
    for dir, n_cid in pairs(neighbors) do
      local n_cell = map.cells[n_cid]
      if not n_cell or not n_cell.candidate_info then
        goto continue
      end

      if n_cell.category == C.CELL.CATEGORY.SECRET then
        map.clear_fake_if_all_found()
        goto continue
      end

      local d_gid = door_gid(cid - room.tl_cid, dir, room_obj:GetGridWidth())
      local dist = (bomb_pos - room_obj:GetGridPosition(d_gid)):Length()
      if dist < BOMB_RADIUS then
        map.cells[n_cid] = nil
        return
      end

      ::continue::
    end
  end

end

return M
