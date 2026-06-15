---@module "lazy_delver.render"

local C = require("lazy_delver.const")
local map = require("lazy_delver.map")

local M = {}

local TAB_HOLD_THRESHOLD = 3
local TAB_HOLD_MAX = 9
local tab_hold_cnt = -TAB_HOLD_THRESHOLD

local CELL_W = 17
local CELL_H = 15

local FLAG_VISIBLE = 1

---@type Vector
local pos_origin = Vector.Zero

---@param rooms CppList_RoomDescriptor
local function update_pos_origin(rooms)
  local top_row, right_col = 13, -1
  for lid = 0, rooms.Size - 1 do
    local desc = rooms:Get(lid)
    if desc and (desc.DisplayFlags & FLAG_VISIBLE) ~= 0 then
      local tf_cid = desc.GridIndex
      local offsets = C.CELL.SHAPE_OFFSETS[desc.Data.Shape]
      for _, offset in ipairs(offsets) do
        local cid = tf_cid + offset
        local r, c = cid // C.MAP.COLS, cid % C.MAP.COLS
        top_row = r < top_row and r or top_row
        right_col = c > right_col and c or right_col
      end
    end
  end
  local center_pos = Isaac.WorldToRenderPosition(Vector(320, 280))
  pos_origin = Vector(
    center_pos.X * 2 - (right_col + 1) * CELL_W - 5 - Options.HUDOffset * 24,
    -top_row * CELL_H + 5 + Options.HUDOffset * 13
  )
end

---@param rooms CppList_RoomDescriptor
local function clear_if_found_secret(rooms)
  for _, secret_type in pairs(C.SECRET_TYPE) do
    local all_found = true
    for _, room in pairs(map.rooms) do
      local desc = rooms:Get(room.lid)
      if desc and desc.Data.Type == secret_type and desc.VisitedCount == 0 then
        all_found = false
      end
    end

    if all_found then
      for cid, cell in pairs(map.cells) do
        if cell.prospect_info and
           cell.prospect_info.secret_type == secret_type then
          if cell.category == C.CELL.CATEGORY.CANDIDATE then
            map.cells[cid] = nil
          elseif cell.category == C.CELL.CATEGORY.SECRET then
            cell.prospect_info.marker_status = C.MARKER.STATUS.FOUND
          end
        end
      end
    end
  end
end

---@param rooms CppList_RoomDescriptor
local function update_marker(rooms)
  for _, cell in pairs(map.cells) do
    local pi = cell.prospect_info
    if not pi or pi.marker_status == C.MARKER.STATUS.FOUND then
      goto continue
    end

    local all_visible = true
    local all_checked = true
    for _, n_cid in pairs(pi.neighbors_to_check) do
      all_checked = false
      local desc = rooms:Get(map.cells[n_cid].lid)
      if desc and (desc.DisplayFlags & FLAG_VISIBLE) == 0 then
        all_visible = false
        break
      end
    end

    if not all_visible then
      pi.marker_status = C.MARKER.STATUS.HIDDEN
    elseif not all_checked then
      pi.marker_status = C.MARKER.STATUS.DIM
    else
      pi.marker_status = C.MARKER.STATUS.BRIGHT
    end

    ::continue::
  end
end


function M.tab_hold_check()
  local controller_id = Isaac.GetPlayer(0).ControllerIndex
  if Input.IsActionPressed(ButtonAction.ACTION_MAP, controller_id) then
    tab_hold_cnt = math.min(tab_hold_cnt + 1, TAB_HOLD_MAX)
  else
    tab_hold_cnt = math.max(tab_hold_cnt - 2, -TAB_HOLD_THRESHOLD)
  end
end


function M.refresh()
  local rooms = Game():GetLevel():GetRooms()
  update_pos_origin(rooms)
  clear_if_found_secret(rooms)
  update_marker(rooms)
end

function M.render()
  if map.is_ignored() then return end
  if tab_hold_cnt <= 0 then return end

  for cid, cell in pairs(map.cells) do
    local pi = cell.prospect_info
    if pi and pi.marker_status ~= C.MARKER.STATUS.HIDDEN and
              pi.marker_status ~= C.MARKER.STATUS.FOUND then
      local r, c = cid // C.MAP.COLS, cid % C.MAP.COLS
      local pos = Vector(pos_origin.X + c * CELL_W + 7,
                         pos_origin.Y + r * CELL_H + 2)
      local colors = C.MARKER.COLORS[pi.secret_type]
      local alpha = C.MARKER.ALPHA[pi.marker_status]
      Isaac.RenderScaledText(
        "*", pos.X, pos.Y, 1, 1,
        colors[1], colors[2], colors[3],
        alpha * (tab_hold_cnt / TAB_HOLD_MAX)
      )
    end
  end
end

return M
