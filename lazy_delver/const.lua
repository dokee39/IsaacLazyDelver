---@module "lazy_delver.const"

local M = {}

-- GENERAL

---@alias LD_Dir integer
---@type { LEFT: LD_Dir, UP: LD_Dir, RIGHT: LD_Dir, DOWN: LD_Dir }
M.DIR = {
  LEFT  = DoorSlot.LEFT0,
  UP    = DoorSlot.UP0,
  RIGHT = DoorSlot.RIGHT0,
  DOWN  = DoorSlot.DOWN0,
}

---@type table<LD_Dir, LD_Dir>
M.DIR_REVERSE = {
  [M.DIR.LEFT]  = M.DIR.RIGHT,
  [M.DIR.UP]    = M.DIR.DOWN,
  [M.DIR.RIGHT] = M.DIR.LEFT,
  [M.DIR.DOWN]  = M.DIR.UP,
}

---@type table<LD_Dir, string>
M.DIR_TO_STRING = {
  [M.DIR.LEFT]  = "left",
  [M.DIR.UP]    = "up",
  [M.DIR.RIGHT] = "right",
  [M.DIR.DOWN]  = "down",
}

---@alias LD_SecretType integer
---@type { REGULAR: LD_SecretType, SUPER: LD_SecretType, ULTRA: LD_SecretType }
M.SECRET_TYPE = {
  REGULAR = RoomType.ROOM_SECRET,
  SUPER = RoomType.ROOM_SUPERSECRET,
  ULTRA = RoomType.ROOM_ULTRASECRET,
}

---@type table<LevelStage, table<StageType, string>>
M.STAGE_NAME = {
  [LevelStage.STAGE1_1] = {
    [StageType.STAGETYPE_ORIGINAL]     = "Basement 1",
    [StageType.STAGETYPE_WOTL]         = "Cellar 1",
    [StageType.STAGETYPE_AFTERBIRTH]   = "Burning Basement 1",
    [StageType.STAGETYPE_REPENTANCE]   = "Downpour 1",
    [StageType.STAGETYPE_REPENTANCE_B] = "Dross 1",
  },
  [LevelStage.STAGE1_2] = {
    [StageType.STAGETYPE_ORIGINAL]     = "Basement 2",
    [StageType.STAGETYPE_WOTL]         = "Cellar 2",
    [StageType.STAGETYPE_AFTERBIRTH]   = "Burning Basement 2",
    [StageType.STAGETYPE_REPENTANCE]   = "Downpour 2",
    [StageType.STAGETYPE_REPENTANCE_B] = "Dross 2",
  },
  [LevelStage.STAGE2_1] = {
    [StageType.STAGETYPE_ORIGINAL]     = "Caves 1",
    [StageType.STAGETYPE_WOTL]         = "Catacombs 1",
    [StageType.STAGETYPE_AFTERBIRTH]   = "Flooded Caves 1",
    [StageType.STAGETYPE_REPENTANCE]   = "Mines 1",
    [StageType.STAGETYPE_REPENTANCE_B] = "Ashpit 1",
  },
  [LevelStage.STAGE2_2] = {
    [StageType.STAGETYPE_ORIGINAL]     = "Caves 2",
    [StageType.STAGETYPE_WOTL]         = "Catacombs 2",
    [StageType.STAGETYPE_AFTERBIRTH]   = "Flooded Caves 2",
    [StageType.STAGETYPE_REPENTANCE]   = "Mines 2",
    [StageType.STAGETYPE_REPENTANCE_B] = "Ashpit 2",
  },
  [LevelStage.STAGE3_1] = {
    [StageType.STAGETYPE_ORIGINAL]     = "Depths 1",
    [StageType.STAGETYPE_WOTL]         = "Necropolis 1",
    [StageType.STAGETYPE_AFTERBIRTH]   = "Dank Depths 1",
    [StageType.STAGETYPE_REPENTANCE]   = "Mausoleum 1",
    [StageType.STAGETYPE_REPENTANCE_B] = "Gehenna 1",
  },
  [LevelStage.STAGE3_2] = {
    [StageType.STAGETYPE_ORIGINAL]     = "Depths 2",
    [StageType.STAGETYPE_WOTL]         = "Necropolis 2",
    [StageType.STAGETYPE_AFTERBIRTH]   = "Dank Depths 2",
    [StageType.STAGETYPE_REPENTANCE]   = "Mausoleum 2",
    [StageType.STAGETYPE_REPENTANCE_B] = "Gehenna 2",
  },
  [LevelStage.STAGE4_1] = {
    [StageType.STAGETYPE_ORIGINAL]     = "Womb 1",
    [StageType.STAGETYPE_WOTL]         = "Utero 1",
    [StageType.STAGETYPE_AFTERBIRTH]   = "Scarred Womb 1",
    [StageType.STAGETYPE_REPENTANCE]   = "Corpse 1",
  },
  [LevelStage.STAGE4_2] = {
    [StageType.STAGETYPE_ORIGINAL]     = "Womb 2",
    [StageType.STAGETYPE_WOTL]         = "Utero 2",
    [StageType.STAGETYPE_AFTERBIRTH]   = "Scarred Womb 2",
    [StageType.STAGETYPE_REPENTANCE]   = "Corpse 2",
  },
  [LevelStage.STAGE4_3] = {
    [StageType.STAGETYPE_ORIGINAL]     = "Blue Womb",
  },
  [LevelStage.STAGE5] = {
    [StageType.STAGETYPE_ORIGINAL]     = "Sheol",
    [StageType.STAGETYPE_WOTL]         = "Cathedral",
  },
  [LevelStage.STAGE6] = {
    [StageType.STAGETYPE_ORIGINAL]     = "Dark Room",
    [StageType.STAGETYPE_WOTL]         = "The Chest",
  },
  [LevelStage.STAGE7] = {
    [StageType.STAGETYPE_ORIGINAL]     = "The Void",
  },
  [LevelStage.STAGE8] = {
    [StageType.STAGETYPE_ORIGINAL]     = "Home",
  },
}

-- MAP

M.MAP = {}

---@type integer
M.MAP.COLS = 13
---@type integer
M.MAP.ROWS = 13
---@type integer
M.MAP.SIZE = M.MAP.COLS * M.MAP.ROWS

-- CELL

M.CELL = {}

---@type table<LD_Dir, integer>
M.CELL.DIR_OFFSETS = {
  [M.DIR.LEFT]  = -1,
  [M.DIR.UP]    = -M.MAP.COLS,
  [M.DIR.RIGHT] = 1,
  [M.DIR.DOWN]  = M.MAP.COLS,
}

---@type table<RoomShape, integer[]>
M.CELL.SHAPE_OFFSETS = {
  [RoomShape.ROOMSHAPE_1x1] = { 0 },
  [RoomShape.ROOMSHAPE_IH]  = { 0 },
  [RoomShape.ROOMSHAPE_IV]  = { 0 },
  [RoomShape.ROOMSHAPE_1x2] = { 0, M.MAP.COLS },
  [RoomShape.ROOMSHAPE_IIV] = { 0, M.MAP.COLS },
  [RoomShape.ROOMSHAPE_2x1] = { 0, 1 },
  [RoomShape.ROOMSHAPE_IIH] = { 0, 1 },
  [RoomShape.ROOMSHAPE_2x2] = { 0, 1, M.MAP.COLS, M.MAP.COLS + 1 },
  [RoomShape.ROOMSHAPE_LTL] = { 1, M.MAP.COLS, M.MAP.COLS + 1 },
  [RoomShape.ROOMSHAPE_LTR] = { 0, M.MAP.COLS, M.MAP.COLS + 1 },
  [RoomShape.ROOMSHAPE_LBL] = { 0, 1, M.MAP.COLS + 1 },
  [RoomShape.ROOMSHAPE_LBR] = { 0, 1, M.MAP.COLS },
}

---@alias LD_CellCategory integer
---@type { NORMAL: integer, SPECIAL: integer, BOSS: integer, SECRET: integer, CANDIDATE: integer }
M.CELL.CATEGORY = {
  NORMAL = 1,
  SPECIAL = 2,
  BOSS = 3,
  SECRET = 4,
  CANDIDATE = 5,
}

---@type table<RoomType, LD_CellCategory>
M.CELL.ROOM_TYPE_TO_CATEGORY = {
  [RoomType.ROOM_DEFAULT]         = M.CELL.CATEGORY.NORMAL,
  [RoomType.ROOM_SHOP]            = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_ERROR]           = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_TREASURE]        = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_BOSS]            = M.CELL.CATEGORY.BOSS,
  [RoomType.ROOM_MINIBOSS]        = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_SECRET]          = M.CELL.CATEGORY.SECRET,
  [RoomType.ROOM_SUPERSECRET]     = M.CELL.CATEGORY.SECRET,
  [RoomType.ROOM_ARCADE]          = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_CURSE]           = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_CHALLENGE]       = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_LIBRARY]         = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_SACRIFICE]       = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_DEVIL]           = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_ANGEL]           = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_DUNGEON]         = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_BOSSRUSH]        = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_ISAACS]          = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_BARREN]          = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_CHEST]           = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_DICE]            = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_BLACK_MARKET]    = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_GREED_EXIT]      = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_PLANETARIUM]     = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_TELEPORTER]      = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_TELEPORTER_EXIT] = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_SECRET_EXIT]     = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_BLUE]            = M.CELL.CATEGORY.SPECIAL,
  [RoomType.ROOM_ULTRASECRET]     = M.CELL.CATEGORY.SECRET,
}

return M
