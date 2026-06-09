local C = require("lazy_delver.const")

local M = {}

function M.info(info)
  print(info)
  Isaac.DebugString(info)
end

-- map_data

local function to_sym(cid, map)
  local cell = map.cells[cid]
  if not cell or cell.category == C.CELL.CATEGORY.EMPTY then
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

  local room = map.rooms[cell.lid]
  local offsets = C.CELL.SHAPE_OFFSETS[room.shape]
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

function M.map_print(map)
  local to_point = function(cid)
    return "(" .. cid // C.MAP.ROWS .. ", " .. cid % C.MAP.COLS .. ")"
  end

  M.info("Total rooms: " .. #map.rooms)
  for cid, cell in pairs(map.cells) do
    if cell.lid then
      M.info(
        to_sym(cid, map) ..
        ": room " .. cell.lid ..
        " in cell " .. to_point(cid) ..
        ", type: " .. map.rooms[cell.lid].type
      )
    end
  end
  for cid, cell in pairs(map.cells) do
    if cell.category == C.CELL.CATEGORY.CANDIDATE then
      M.info(to_sym(cid, map) .. ": candidate in cell " .. to_point(cid))
    end
  end
end

function M.map_draw(map)
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
end

return M
