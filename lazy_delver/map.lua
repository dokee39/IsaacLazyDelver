---@module "lazy_delver.map"

local C = require("lazy_delver.const")
local geo = require("lazy_delver.geometry")
local log = require("lazy_delver.log")
local state = require("lazy_delver.state")

---@class LD_Map
local M = {}

---@alias LD_Cid integer cid: `cell` index in [`cells` / grid]
---@alias LD_Lid integer lid: [`room` / list] index in `rooms`

---@class LD_Cell
---@field cid LD_Cid
---@field lid LD_Lid
---@field category LD_CellCategory
---@type table<LD_Cid, LD_Cell>
M.cells = {}

---@class LD_Entry
---@field source_lid LD_Lid
---@field via_cid LD_Cid?  -- ULTRA only; nil for REGULAR/SUPER
---@field doorslot DoorSlot
---@field checked boolean
---@alias LD_Entries table<LD_Dir, LD_Entry>

---@class LD_Candidate
---@field cid LD_Cid
---@field secret_type LD_SecretType
---@field lid LD_Lid?  -- real SECRET ListIndex; nil for fake candidates
---@field marker_status LD_MarkerStatus
---@field entries LD_Entries

---@type table<LD_Cid, LD_Candidate>
M.candidates = {}

---@class LD_Room
---@field lid integer
---@field mirror_lid integer?
---@field tl_cid integer top-left cid
---@field cids integer[]
---@field shape RoomShape
---@field type RoomType
---@type table<LD_Lid, LD_Room>
M.rooms = {}


---@param room_desc RoomDescriptor
local function parse_room(room_desc)
  local data = room_desc.Data
  if not data then return end

  local lid = room_desc.ListIndex
  local shape_offsets = geo.SHAPE_OFFSETS[data.Shape]
  local category = C.CELL.ROOM_TYPE_TO_CATEGORY[data.Type]

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

---@param cid LD_Cid
local function build_entries(cid)
  local result = {}
  local neighbors = geo.get_neighbors(cid)
  for dir, n_cid in pairs(neighbors) do
    local n_cell = M.cells[n_cid]
    if n_cell and n_cell.category ~= C.CELL.CATEGORY.SECRET then
      local room = M.rooms[n_cell.lid]
      local door_dir = (dir + 2) % 4
      local doorslot = geo.get_doorslot(door_dir, cid - room.tl_cid, room.shape)
      if doorslot then
        result[door_dir] = {
          source_lid = n_cell.lid,
          doorslot = doorslot,
          checked = false,
        }
      end
    end
  end
  return result
end

---@param cid LD_Cid
---@return LD_SecretType?
local function fake_type(cid)
  local normal_count = 0
  local special_count = 0

  local neighbors = geo.get_neighbors(cid)
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

local function find_fakes()
  for cid = 0, C.MAP.SIZE - 1 do
    if M.cells[cid] then
      goto continue
    end

    local secret_type = fake_type(cid)
    if secret_type == nil then
      goto continue
    end

    M.candidates[cid] = {
      cid = cid,
      secret_type = secret_type,
      lid = nil,
      marker_status = C.MARKER.STATUS.HIDDEN,
      entries = build_entries(cid),
    }

    ::continue::
  end
end


function M.reload()
  local level = Game():GetLevel()
  state.update(level)

  M.cells = {}
  M.candidates = {}
  M.rooms = {}

  local rooms_raw = level:GetRooms()
  for lid = 0, rooms_raw.Size - 1 do
    parse_room(rooms_raw:Get(lid))
  end
  for cid, cell in pairs(M.cells) do
    if cell.category == C.CELL.CATEGORY.SECRET then
      local secret_type = M.rooms[cell.lid].type
      M.candidates[cid] = {
        cid = cid,
        secret_type = secret_type,
        lid = cell.lid,
        marker_status = C.MARKER.STATUS.HIDDEN,
        entries = build_entries(cid),
      }
    end
  end

  find_fakes()

  log.info("Map loading complete!\n")
  log.print_map(M):info()
  log.draw_map(M):info()

  state.done()
end


---@param lid LD_Lid
function M.clear_fake_neighbors(lid)
  local room = M.rooms[lid]
  if not room then return end

  for _, cid in ipairs(room.cids) do
    local neighbors = geo.get_neighbors(cid)

    for _, n_cid in pairs(neighbors) do
      local cand = M.candidates[n_cid]
      if cand and cand.lid == nil then
        M.candidates[n_cid] = nil
      end
    end
  end
end

return M
