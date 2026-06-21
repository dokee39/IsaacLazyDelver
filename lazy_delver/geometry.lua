---@module "lazy_delver.geometry"

local C = require("lazy_delver.const")

local M = {}

local DIR_DELTA = {
  [C.DIR.LEFT]  = { R =  0, C = -1 },
  [C.DIR.UP]    = { R = -1, C =  0 },
  [C.DIR.RIGHT] = { R =  0, C =  1 },
  [C.DIR.DOWN]  = { R =  1, C =  0 },
}

local DOOR_INFO = {
  [DoorSlot.LEFT0]  = { DIR = C.DIR.LEFT,  I = 0 },
  [DoorSlot.LEFT1]  = { DIR = C.DIR.LEFT,  I = 1 },
  [DoorSlot.UP0]    = { DIR = C.DIR.UP,    I = 0 },
  [DoorSlot.UP1]    = { DIR = C.DIR.UP,    I = 1 },
  [DoorSlot.RIGHT0] = { DIR = C.DIR.RIGHT, I = 0 },
  [DoorSlot.RIGHT1] = { DIR = C.DIR.RIGHT, I = 1 },
  [DoorSlot.DOWN0]  = { DIR = C.DIR.DOWN,  I = 0 },
  [DoorSlot.DOWN1]  = { DIR = C.DIR.DOWN,  I = 1 },
}

local DIR_BAN_BIT = {
  [C.DIR.LEFT]  = 0x10,  -- bit 4
  [C.DIR.UP]    = 0x20,  -- bit 5
  [C.DIR.RIGHT] = 0x40,  -- bit 6
  [C.DIR.DOWN]  = 0x80,  -- bit 7
}

-- Lower 4 bits: occupancy mask (bit0=cell(0,0), bit1=cell(0,1), bit2=cell(1,0), bit3=cell(1,1)).
-- Upper 4 bits: direction ban mask (bit4=LEFT, bit5=UP, bit6=RIGHT, bit7=DOWN).
local SHAPE_DATA = {
  [RoomShape.ROOMSHAPE_1x1] = 0x01,
  [RoomShape.ROOMSHAPE_IH]  = 0x01 | 0xA0,
  [RoomShape.ROOMSHAPE_IV]  = 0x01 | 0x50,
  [RoomShape.ROOMSHAPE_1x2] = 0x05,
  [RoomShape.ROOMSHAPE_IIV] = 0x05 | 0x50,
  [RoomShape.ROOMSHAPE_2x1] = 0x03,
  [RoomShape.ROOMSHAPE_IIH] = 0x03 | 0xA0,
  [RoomShape.ROOMSHAPE_2x2] = 0x0F,
  [RoomShape.ROOMSHAPE_LTL] = 0x0E,
  [RoomShape.ROOMSHAPE_LTR] = 0x0D,
  [RoomShape.ROOMSHAPE_LBL] = 0x07,
  [RoomShape.ROOMSHAPE_LBR] = 0x0B,
}

---DoorSlot on the wall of a room of `shape`, facing the neighbor cell whose
---offset (cid - room.tl_cid) is `offset`.
---@param offset integer neighbor cell offset relative to room tl
---@param shape RoomShape
---@return DoorSlot?
function M.get_doorslot(offset, shape)
  local data = SHAPE_DATA[shape]
  if not data then return nil end

  local w = (data & 0x0A ~= 0) and 2 or 1
  local h = (data & 0x0C ~= 0) and 2 or 1

  for slot, info in pairs(DOOR_INFO) do
    if data & DIR_BAN_BIT[info.DIR] == 0 then
      local d = DIR_DELTA[info.DIR]
      local r, c
      if d.R == 0 then
        r, c = info.I, (d.C < 0) and 0 or (w - 1)
      else
        r, c = (d.R < 0) and 0 or (h - 1), info.I
      end
      if (data >> (r * 2 + c)) & 1 == 1 then
        if (r + d.R) * C.MAP.COLS + (c + d.C) == offset then
          return slot
        end
      end
    end
  end
  return nil
end

---@param cid LD_Cid
---@return table<LD_Dir, LD_Cid>
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

return M
