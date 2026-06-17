---@module "lazy_delver.log"

local C = require("lazy_delver.const")

local M = {}

---@param s string
function M.info(s)
  print(s)
  Isaac.DebugString(s)
end
---@param s string
function M.error(s)
  print("[ERROR] " .. s)
  Isaac.DebugString("[ERROR] " .. s)
end

---@class LD_Log
---@field _lines string[]
local Log = {}
Log.__index = Log

---@param lines string[]
---@return LD_Log
function Log:new(lines)
  return setmetatable({ _lines = lines }, self)
end

function Log:info()
  for _, line in ipairs(self._lines) do
    M.info(line)
  end
end

function Log:error()
  for _, line in ipairs(self._lines) do
    M.error(line)
  end
end


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

  if cell.category == C.CELL.CATEGORY.FAKE then
    local cnt = 0
    for _ in pairs(cell.candidate_info.neighbors_to_check) do
      cnt = cnt + 1
    end
    return C.CELL.FAKE_SYM[cell.candidate_info.secret_type][cnt == 0]
  elseif cell.category == C.CELL.CATEGORY.SECRET then
    return C.CELL.SECRET_SYM[cell.candidate_info.secret_type]
  end

  local offsets = C.CELL.SHAPE_OFFSETS[map.rooms[cell.lid].shape]
  local is_multi = (#offsets > 1)
  local lb, rb = "[", "]"
  if is_multi then
    lb, rb = "{", "}"
  end

  return lb .. C.CELL.OTHER_SYM[cell.category] .. rb
end


---@param lid LD_Lid
---@param map LD_Map
---@return LD_Log
function M.print_room(lid, map)
  local room = map.rooms[lid]
  if not room then return Log:new({}) end

  local cids = room.cids

  local _, s_cid = next(cids)
  assert(s_cid ~= nil)
  local sym = to_sym(s_cid, map)

  local parts = {}
  for _, cid in pairs(cids) do
    parts[#parts + 1] = to_point(cid)
  end
  local cells = " " .. table.concat(parts, " ")

  local line = sym .. " room " .. lid ..
              ", type: " .. room.type ..
              ", cells:" .. cells
  return Log:new({ line })
end

---@param neighbors LD_RoomNeighbors
---@return LD_Log
function M.print_candidate_neighbors(neighbors)
  local lines = {}
  for _, n in pairs(neighbors) do
    lines[#lines + 1] = "need check " .. to_point(n.cid) ..
                        " (" .. C.DIR_TO_STRING[n.dir] .. ")"
  end
  return Log:new(lines)
end

---@param map LD_Map
---@return LD_Log
function M.print_map(map)
  local lines = {}
  lines[#lines + 1] = "Total rooms: " .. #map.rooms + 1

  for lid = 0, #map.rooms do
    local out = M.print_room(lid, map)
    for _, line in ipairs(out._lines) do
      lines[#lines + 1] = line
    end
  end

  for cid, cell in pairs(map.cells) do
    if cell.category == C.CELL.CATEGORY.FAKE then
      lines[#lines + 1] =
        to_sym(cid, map) .. " candidate in cell " .. to_point(cid)
    end
  end

  lines[#lines + 1] = ""
  return Log:new(lines)
end

---@param map LD_Map
---@return LD_Log
function M.draw_map(map)
  local lines = {}

  local header = "       "
  for col = 0, C.MAP.COLS - 1 do
    header = header .. string.format("%2d ", col)
  end
  lines[#lines + 1] = header

  for row = 0, C.MAP.ROWS - 1 do
    local line = string.format("Row %2d:", row)
    for col = 0, C.MAP.COLS - 1 do
      local cid = row * C.MAP.COLS + col
      line = line .. to_sym(cid, map)
    end
    lines[#lines + 1] = line
  end

  lines[#lines + 1] = ""
  return Log:new(lines)
end

return M
