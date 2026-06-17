---@module "lazy_delver.map"

local C = require("lazy_delver.const")
local log = require("lazy_delver.log")

---@class LD_Map
local M = {}

---@type integer?
local seed = nil
---@type LevelStage?
local stage = nil
---@type StageType?
local stage_type = nil

local dimension = C.DIMENSION.MAIN
function M.get_dimension()
  return dimension
end

local ignored = false
function M.is_ignored()
  return ignored or dimension == C.DIMENSION.OTHER
end

---@alias LD_Cid integer cid: `cell` index in [`cells` / grid]
---@alias LD_Lid integer lid: [`room` / list] index in `rooms`

---@class LD_CellNeighbor
---@field dir LD_Dir
---@field cid LD_Cid
---@alias LD_CellNeighbors table<LD_Dir, LD_Cid>
---@alias LD_RoomNeighbors LD_CellNeighbor[]

---@class LD_ProspectInfo
---@field secret_type LD_SecretType
---@field neighbors_to_check LD_CellNeighbors
---@field marker_status LD_MarkerStatus

---@class LD_Cell
---@field cid LD_Cid
---@field lid LD_Lid?
---@field category LD_CellCategory?
---@field prospect_info LD_ProspectInfo?
---@type table<LD_Cid, LD_Cell>
M.cells = {}

---@class LD_Room
---@field lid integer
---@field mirror_lid integer?
---@field tl_cid integer top-left cid
---@field cids integer[]
---@field shape RoomShape
---@field type RoomType
---@type table<LD_Lid, LD_Room>
M.rooms = {}

M.special_items = {
  [CollectibleType.COLLECTIBLE_BLUE_MAP]      = false,
  [CollectibleType.COLLECTIBLE_XRAY_VISION]   = false,
  [CollectibleType.COLLECTIBLE_MIND]          = false,
  [CollectibleType.COLLECTIBLE_DOG_TOOTH]     = false,
  [CollectibleType.COLLECTIBLE_YO_LISTEN]     = false,
  [CollectibleType.COLLECTIBLE_SPELUNKER_HAT] = false,
}

---@param level Level
local function get_current_dimension(level)
  local desc = level:GetCurrentRoomDesc()
  if not desc or not desc.Data then
    return C.DIMENSION.MAIN
  end
  for dim = 1, 2 do
    local dim_desc = level:GetRoomByIdx(desc.SafeGridIndex, dim)
    if dim_desc and dim_desc.Data and
       GetPtrHash(dim_desc) == GetPtrHash(desc) then
      if dim == 1 and stage == LevelStage.STAGE1_2 and
         (stage_type == StageType.STAGETYPE_REPENTANCE or
          stage_type == StageType.STAGETYPE_REPENTANCE_B) then
        return C.DIMENSION.MIRROR
      else
        return C.DIMENSION.OTHER
      end
    end
  end
  return C.DIMENSION.MAIN
end

---@param level Level
local function init(level)
  seed = Game():GetSeeds():GetStartSeed()
  stage = level:GetStage()
  stage_type = level:GetStageType()
  dimension = get_current_dimension(level)
  M.cells = {}
  M.rooms = {}
  for type, _ in pairs(M.special_items) do M.special_items[type] = false end
end


---@param room_desc RoomDescriptor
local function parse_room(room_desc)
  local data = room_desc.Data
  local lid = room_desc.ListIndex
  local shape_offsets = C.CELL.SHAPE_OFFSETS[data.Shape]
  local category = C.CELL.ROOM_TYPE_TO_CATEGORY[data.Type]
  local secret_type = category == C.CELL.CATEGORY.SECRET and data.Type or nil

  local cids = {}
  for i = 1, #shape_offsets do
    cids[i] = shape_offsets[i] + room_desc.GridIndex

    if M.cells[cids[i]] then
      M.rooms[lid] = M.rooms[M.cells[cids[i]].lid]
      M.rooms[lid].mirror_lid = lid
      return
    end

    M.cells[cids[i]] = {
      cid = cids[i],
      lid = lid,
      category = category,
      prospect_info = secret_type and {
        secret_type = secret_type,
        neighbors_to_check = {},
        marker_status = C.MARKER.STATUS.HIDDEN,
      } or nil,
    }
  end

  M.rooms[lid] = {
    lid = lid,
    tl_cid = room_desc.GridIndex,
    cids = cids,
    shape = data.Shape,
    type = data.Type,
  }
end


---@param cid integer
---@return LD_CellNeighbors
function M.get_neighbors(cid)
  local neighbors = {}
  local col = cid % C.MAP.COLS
  if col > 0 then
    neighbors[C.DIR.LEFT] = cid + C.CELL.DIR_OFFSETS[C.DIR.LEFT]
  end
  if col < C.MAP.COLS - 1 then
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

---@param cid integer
---@param secret_type LD_SecretType
---@return LD_CellNeighbors
local function get_neighbors_to_check(cid, secret_type)
  local result = {}
  local neighbors = M.get_neighbors(cid)
  for dir, n_cid in pairs(neighbors) do
    local n_cell = M.cells[n_cid]
    if n_cell and
      (n_cell.category == C.CELL.CATEGORY.NORMAL or
       (secret_type == C.SECRET_TYPE.REGULAR and
        n_cell.category == C.CELL.CATEGORY.SPECIAL)) then
      result[dir] = n_cid
    end
  end
  return result
end


---@param cid LD_Cid
---@return LD_SecretType?
local function candidate_type(cid)
  local normal_count = 0
  local special_count = 0

  local neighbors = M.get_neighbors(cid)
  for dir, n_cid in pairs(neighbors) do
    local n_cell = M.cells[n_cid]
    if n_cell then
      if n_cell.category == C.CELL.CATEGORY.BOSS then
        return nil
      elseif n_cell.category == C.CELL.CATEGORY.NORMAL or
             n_cell.category == C.CELL.CATEGORY.SPECIAL then
        local shape = M.rooms[n_cell.lid].shape
        if (dir == C.DIR.UP or dir == C.DIR.DOWN) and
           (shape == RoomShape.ROOMSHAPE_IH or
            shape == RoomShape.ROOMSHAPE_IIH) then
          return nil
        end
        if (dir == C.DIR.LEFT or dir == C.DIR.RIGHT) and
           (shape == RoomShape.ROOMSHAPE_IV or
            shape == RoomShape.ROOMSHAPE_IIV) then
          return nil
        end

        if n_cell.category == C.CELL.CATEGORY.NORMAL then
          normal_count = normal_count + 1
        elseif n_cell.category == C.CELL.CATEGORY.SPECIAL then
          special_count = special_count + 1
        end
      end
    end
  end

  local total_count = normal_count + special_count
  if total_count == 1 and normal_count == 1 then
    return C.SECRET_TYPE.SUPER
  elseif total_count > 1 then
    return C.SECRET_TYPE.REGULAR
  end

  return nil
end

local function find_candidates()
  for cid = 0, C.MAP.SIZE - 1 do
    if M.cells[cid] then
      goto continue
    end

    local type = candidate_type(cid)
    if type == nil then
      goto continue
    end

    M.cells[cid] = {
      cid = cid,
      lid = nil,
      category = C.CELL.CATEGORY.CANDIDATE,
      prospect_info = {
        secret_type = type,
        neighbors_to_check = get_neighbors_to_check(cid, type),
        marker_status = C.MARKER.STATUS.HIDDEN,
      },
    }

    ::continue::
  end
end


local function reload()
  local level = Game():GetLevel()
  init(level)

  log.info("<=== New Level: " .. C.STAGE_NAME[stage][stage_type] .. " ===>")
  if level:IsAscent() or
     level:GetStage() == LevelStage.STAGE8 or
     Game():IsGreedMode() then
    ignored = true
    log.info("This level was ignored.")
    return
  else
    ignored = false
  end

  local rooms_raw = level:GetRooms()

  for lid = 0, #rooms_raw - 1 do
    parse_room(rooms_raw:Get(lid))
  end
  for cid, cell in pairs(M.cells) do
    if cell.category == C.CELL.CATEGORY.SECRET then
     local pi = cell.prospect_info
      if pi then
        pi.neighbors_to_check = get_neighbors_to_check(cid, pi.secret_type)
      end
    end
  end

  find_candidates()

  log.info("Map loading complete!\n")
  log.print_map(M):info()
  log.draw_map(M):info()
end

function M.refresh()
  if Game():GetSeeds():GetStartSeed() ~= seed then
    reload()
  end

  local level = Game():GetLevel()
  if level:GetStage() ~= stage or level:GetStageType() ~= stage_type then
    reload()
  end

  dimension = get_current_dimension(level)
end


---@param lid LD_Lid
---@return LD_RoomNeighbors
function M.get_neighbors_to_check(lid)
  local result = {}
  local room = M.rooms[lid]
  if not room then return result end

  local cids = room.cids;
  for _, cid in ipairs(cids) do
    for dir, n_cid in pairs(M.get_neighbors(cid)) do
      local n_cell = M.cells[n_cid]
      local dir_reverse = C.DIR_REVERSE[dir]
      if n_cell and
         n_cell.prospect_info and
         n_cell.prospect_info.neighbors_to_check[dir_reverse] == cid then
        result[#result + 1] = { dir = dir, cid = n_cid }
      end
    end
  end

  return result
end

---@param lid LD_Lid
function M.clear_neighbors_to_check(lid)
  local room = M.rooms[lid]
  if not room then return end

  for _, cid in ipairs(room.cids) do
    local neighbors = M.get_neighbors(cid)

    for _, n_cid in pairs(neighbors) do
      local n_cell = M.cells[n_cid]
      if n_cell and n_cell.category == C.CELL.CATEGORY.CANDIDATE then
        M.cells[n_cid] = nil
      end
    end
  end
end

function M.clear_if_found_secret()
  local rooms = Game():GetLevel():GetRooms()

  for _, secret_type in pairs(C.SECRET_TYPE) do
    local all_found = true
    for _, room in pairs(M.rooms) do
      local desc = rooms:Get(room.lid)
      if desc and desc.Data.Type == secret_type and desc.DisplayFlags == 0 then
        all_found = false
      end
    end

    if all_found then
      for cid, cell in pairs(M.cells) do
        if cell.prospect_info and
           cell.prospect_info.secret_type == secret_type then
          if cell.category == C.CELL.CATEGORY.CANDIDATE then
            M.cells[cid] = nil
          elseif cell.category == C.CELL.CATEGORY.SECRET then
            cell.prospect_info.marker_status = C.MARKER.STATUS.FOUND
          end
        end
      end
    end
  end
end


return M
