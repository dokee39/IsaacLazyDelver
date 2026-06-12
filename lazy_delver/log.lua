---@module "lazy_delver.room"

local C = require("lazy_delver.const")

local M = {}

---@param info string
function M.info(info)
  print(info)
  Isaac.DebugString(info)
end

-- map

---@param cid LD_Cid
---@return string
local function to_point(cid)
  return "(" .. cid // C.MAP.ROWS .. ", " .. cid % C.MAP.COLS .. ")"
end

---@param cid LD_Cid
---@param map LD_Map
---@return string
local function to_sym(cid, map)
  local cell = map.cells[cid]
  if not cell then
    return " . "
  end

  if cell.category == C.CELL.CATEGORY.CANDIDATE then
    if cell.secret_type == C.SECRET_TYPE.REGULAR then
      return " R "
    elseif cell.secret_type == C.SECRET_TYPE.SUPER then
      return " S "
    elseif cell.secret_type == C.SECRET_TYPE.ULTRA then
      return " U "
    else
      return " ? "
    end
  elseif cell.category == C.CELL.CATEGORY.SECRET then
    return "<S>"
  end

  local offsets = C.CELL.SHAPE_OFFSETS[map.rooms[cell.lid].shape]
  local is_multi = (#offsets > 1)
  local lb, rb = "[", "]"
  if is_multi then
    lb, rb = "{", "}"
  end

  if cell.category == C.CELL.CATEGORY.NORMAL then
    return lb .. "N" .. rb
  elseif cell.category == C.CELL.CATEGORY.SPECIAL then
    return lb .. "C" .. rb
  elseif cell.category == C.CELL.CATEGORY.BOSS then
    return lb .. "B" .. rb
  else
    return lb .. "?" .. rb
  end
end


---@param lid LD_Lid
---@param map LD_Map
function M.print_room(lid, map)
  local room = map.rooms[lid]
  if not room then return end

  local cids = room.cids

  local _, s_cid = next(cids)
  assert(s_cid ~= nil)
  local sym = to_sym(s_cid, map)

  local parts = {}
  for _, cid in pairs(cids) do
    parts[#parts + 1] = to_point(cid)
  end
  local cells = " " .. table.concat(parts, " ")

  M.info(
    sym .. " room " .. lid .. 
    ", type: " .. room.type .. 
    ", cells:" .. cells)
end

---@param neighbors table<LD_Cid, LD_CellNeighbor>
function M.print_neighbors_to_check(neighbors)
  for cid, check in pairs(neighbors) do
    M.info(
      "need check " .. to_point(cid) ..
      "'s " .. C.DIR_TO_STRING[check.dir] ..
      ": " .. to_point(check.cid))
  end
end

---@param map LD_Map
function M.print_map(map)
  M.info("Total rooms: " .. #map.rooms + 1)

  for lid = 0, #map.rooms do
    M.print_room(lid, map)
  end

  for cid, cell in pairs(map.cells) do
    if cell.category == C.CELL.CATEGORY.CANDIDATE then
      M.info(to_sym(cid, map) .. " candidate in cell " .. to_point(cid))
    end
  end

  M.info("")
end

---@param map LD_Map
function M.draw_map(map)
  local lines = {}

  local header = "       "
  for col = 0, C.MAP.COLS - 1 do
    header = header .. string.format("%2d ", col)
  end
  table.insert(lines, header)

  for row = 0, C.MAP.ROWS - 1 do
    local line = string.format("Row %2d:", row)
    for col = 0, C.MAP.COLS - 1 do
      local cid = row * C.MAP.COLS + col
      line = line .. to_sym(cid, map)
    end
    table.insert(lines, line)
  end

  for _, line in ipairs(lines) do
    M.info(line)
  end

  M.info("")
end

return M
