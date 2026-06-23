---@module "lazy_delver.render"

local C = require("lazy_delver.const")
local geo = require("lazy_delver.geometry")
local log = require("lazy_delver.log")
local state = require("lazy_delver.state")
local map = require("lazy_delver.map")

local M = {}

local need_refresh = false

local TAB_HOLD_THRESHOLD = 3
local TAB_HOLD_MAX = 9
local tab_hold_cnt = -TAB_HOLD_THRESHOLD

local CELL_W = 17
local CELL_H = 15

local marker_sprite = Sprite()
marker_sprite:Load("gfx/lazy_delver/marker.anm2", true)
marker_sprite:SetFrame(marker_sprite:GetDefaultAnimation(), 1)

local pos_origin = Vector.Zero
local mirror_offset = 0

local function update_pos_origin()
  local rooms = Game():GetLevel():GetRooms()
  local top_row, left_col, right_col = 13, 13, -1

  for lid = 0, rooms.Size - 1 do
    local desc = rooms:Get(lid)
    if desc and desc.DisplayFlags ~= 0 then
      local tl_cid = desc.GridIndex
      local offsets = geo.SHAPE_OFFSETS[desc.Data.Shape]
      for _, offset in ipairs(offsets) do
        local cid = tl_cid + offset
        local r, c = cid // C.MAP.COLS, cid % C.MAP.COLS
        top_row = r < top_row and r or top_row
        left_col = c < left_col and c or left_col
        right_col = c > right_col and c or right_col
      end
    end
  end
  local center_pos = Isaac.WorldToRenderPosition(Vector(320, 280))
  pos_origin = Vector(
    center_pos.X * 2 - (right_col + 1) * CELL_W - 5 - Options.HUDOffset * 24,
    -top_row * CELL_H + 5 + Options.HUDOffset * 13
  )
  mirror_offset = left_col + right_col
end

local function check_real_and_clear_fake()
  local rooms = Game():GetLevel():GetRooms()

  for _, secret_type in pairs(C.SECRET_TYPE) do
    local all_found = true
    for _, cand in pairs(map.candidates) do
      local lid = cand.lid
      if lid ~= nil and state.get_dimension() == C.DIMENSION.MIRROR then
        lid = map.rooms[lid].mirror_lid or lid
      end
      if lid ~= nil and cand.secret_type == secret_type then
        local desc = rooms:Get(lid)
        if desc and desc.DisplayFlags == 0 then
          all_found = false
          break
        end
      end
    end

    if all_found then
      for cid, cand in pairs(map.candidates) do
        if cand.secret_type == secret_type then
          if cand.lid == nil then
            map.candidates[cid] = nil
          else
            cand.marker_status = C.MARKER.STATUS.FOUND
          end
        end
      end
    end
  end
end

local function update_marker()
  local rooms = Game():GetLevel():GetRooms()

  for _, cand in pairs(map.candidates) do
    if cand.marker_status == C.MARKER.STATUS.FOUND then
      goto continue
    end

    local all_visible = true
    local all_checked = true
    for _, entry in pairs(cand.entries) do
      if not entry.checked then
        all_checked = false
      end

      local lid
      if state.get_dimension() == C.DIMENSION.MIRROR then
        lid = map.rooms[entry.source_lid].mirror_lid
      else
        lid = entry.source_lid
      end
      if not lid then
        log.error("room " .. entry.source_lid .. " should have a mirror lid")
        goto continue
      end

      local desc = rooms:Get(lid)
      if desc and desc.DisplayFlags == 0 then
        all_visible = false
        break
      end
    end

    if not all_visible then
      cand.marker_status = C.MARKER.STATUS.HIDDEN
    elseif not all_checked then
      cand.marker_status = C.MARKER.STATUS.DIM
    else
      cand.marker_status = C.MARKER.STATUS.BRIGHT
    end

    ::continue::
  end
end

function M.tab_hold_check()
  if state.is_ignored() then return end

  local controller_id = Isaac.GetPlayer(0).ControllerIndex
  if Input.IsActionPressed(ButtonAction.ACTION_MAP, controller_id) then
    tab_hold_cnt = math.min(tab_hold_cnt + 1, TAB_HOLD_MAX)
  else
    tab_hold_cnt = math.max(tab_hold_cnt - 2, -TAB_HOLD_THRESHOLD)
  end
end


local function refresh()
  update_pos_origin()
  check_real_and_clear_fake()
  if state.can_see_entrance() or state.can_see_red() then
    local lid = Game():GetLevel():GetCurrentRoomDesc().ListIndex
    map.clear_fake_neighbors(lid)
  end
  update_marker()
  need_refresh = false
end

function M.refresh()
  if state.is_ignored() then return end
  need_refresh = true
end

function M.render()
  if state.is_ignored() then return end

  if state.is_lost_cursed() or state.is_off_grid() then return end

  if tab_hold_cnt <= 0 then return end

  if need_refresh then refresh() end

  local is_mirror = state.get_dimension() == C.DIMENSION.MIRROR
  local show_red = state.can_see_red()

  for cid, cand in pairs(map.candidates) do
    if not show_red and cand.secret_type == C.SECRET_TYPE.ULTRA then
      goto continue
    end
    if cand.marker_status == C.MARKER.STATUS.HIDDEN or
       cand.marker_status == C.MARKER.STATUS.FOUND then
      goto continue
    end

    local r, c = cid // C.MAP.COLS, cid % C.MAP.COLS
    if is_mirror then
      c = mirror_offset - c
    end
    local pos = Vector(pos_origin.X + c * CELL_W + 8,
                        pos_origin.Y + r * CELL_H + 7)
    local colors = C.MARKER.COLORS[cand.secret_type]
    local alpha = C.MARKER.ALPHA[cand.marker_status]
    marker_sprite.Color = Color(
      colors[1], colors[2], colors[3],
      alpha * (tab_hold_cnt / TAB_HOLD_MAX),
      0, 0, 0
    )
    marker_sprite:Render(pos)

    ::continue::
  end
end

return M
