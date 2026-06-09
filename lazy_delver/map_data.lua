local C = require("lazy_delver.const")
local debug = require("lazy_delver.debug")

local M = {}

-- cid: `cell` index in [`cells` / grid]
-- lid: [`room` / list] index in `rooms`

-- map.cells[cid]:
--   cid
--   lid
--   category
--   secret_type
-- map.rooms[lid]:
--   lid
--   cids
--   shape
--   type
local map = {}

local function init()
  map = {
    cells = {},
    rooms = {}
  }
end

local function parse_room(room_raw)
  local data = room_raw.Data
  local lid = room_raw.ListIndex
  local shape_offsets = C.CELL.SHAPE_OFFSETS[data.Shape]
  local category = C.CELL.ROOM_TYPE_TO_CATEGORY[data.Type]
  local secret_type = category == C.CELL.CATEGORY.SECRET and data.Type or nil

  local cids = {}
  for i = 1, #shape_offsets do
    cids[i] = shape_offsets[i] + room_raw.GridIndex
    map.cells[cids[i]] = {
      cid = cids[i],
      lid = lid,
      category = category,
      secret_type = secret_type,
    }
  end

  map.rooms[lid] = {
    lid = lid,
    cids = cids,
    shape = data.Shape,
    type = data.Type,
  }
end

local function get_neighbors(cid)
  local neighbors = {}
  local col = cid % C.MAP.COLS
  if col ~= 0 then
    neighbors[C.DIR.LEFT] = cid + C.CELL.DIR_OFFSETS[C.DIR.LEFT]
  end
  if col ~= C.MAP.COLS - 1 then
    neighbors[C.DIR.RIGHT] = cid + C.CELL.DIR_OFFSETS[C.DIR.RIGHT]
  end
  if cid >= C.MAP.COLS then
    neighbors[C.DIR.UP] = cid + C.CELL.DIR_OFFSETS[C.DIR.UP]
  end
  if cid < C.MAP.SIZE - C.MAP.COLS then
    neighbors[C.DIR.DOWN] = cid + C.CELL.DIR_OFFSETS[C.DIR.DOWN]
  end

  return neighbors
end

local function candidate_type(cid)
  local normal_count = 0
  local special_count = 0

  local neighbors = get_neighbors(cid)
  for dir, n_cid in pairs(neighbors) do
    local n_cell = map.cells[n_cid]
    if n_cell then
      if n_cell.category == C.CELL.CATEGORY.BOSS then
        return nil
      elseif n_cell.category == C.CELL.CATEGORY.NORMAL or
             n_cell.category == C.CELL.CATEGORY.SPECIAL then
        local shape = map.rooms[n_cell.lid].shape
        if (dir == C.DIR.UP or dir == C.DIR.DOWN) and
          (shape == RoomShape.ROOMSHAPE_IH or shape == RoomShape.ROOMSHAPE_IIH) then
          return nil
        end
        if (dir == C.DIR.LEFT or dir == C.DIR.RIGHT) and
          (shape == RoomShape.ROOMSHAPE_IV or shape == RoomShape.ROOMSHAPE_IIV) then
          return nil
        end

        if n_cell.category == C.CELL.CATEGORY.NORMAL then normal_count = normal_count + 1 end
        if n_cell.category == C.CELL.CATEGORY.SPECIAL then special_count = special_count + 1 end
      end
    end
  end

  local total_count = normal_count + special_count
  if total_count == 0 then
    return nil
  elseif total_count == 1 and normal_count == 1 then
    return C.SECRET_TYPE.SUPER
  else
    return C.SECRET_TYPE.REGULAR
  end
end

local function find_candidates()
  for cid = 0, C.MAP.SIZE - 1 do
    if map.cells[cid] == nil then
      local type = candidate_type(cid)
      if type then
        map.cells[cid] = {
          cid = cid,
          lid = nil,
          category = C.CELL.CATEGORY.CANDIDATE,
          secret_type = type,
        }
      end
    end
  end
end

function M.load()
  init()

  local level = Game():GetLevel()
  if level:IsAscent() or level:GetStage() == LevelStage.STAGE8 or Game():IsGreedMode() then
    return
  end

  local rooms_raw = level:GetRooms()

  for lid = 0, #rooms_raw - 1 do
    parse_room(rooms_raw:Get(lid))
  end

  find_candidates()

  debug.info("=== New Level: " .. level:GetStage() .. " ===")
  debug.map_print(map)
  debug.map_draw(map)
end

function M.get()
  return map
end

return M
