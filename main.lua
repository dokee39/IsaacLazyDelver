local mod = RegisterMod("Lazy Delver", 1)

local state = require("lazy_delver.state")
local map = require("lazy_delver.map")
local room = require("lazy_delver.room")
local render = require("lazy_delver.render")

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
  state.check()
  room.obstacle_check()
  render.refresh()
end)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
  render.tab_hold_check()
end)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
  render.render()
end)
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, function(_, effect)
  room.bomb_check(effect)
end, EffectVariant.BOMB_EXPLOSION)

for _, item in ipairs(state.items.active) do
  mod:AddCallback(item.mc, function()
    if item.clear then
      local lid = Game():GetLevel():GetCurrentRoomDesc().ListIndex
      map.clear_fake_neighbors(lid)
    end
    render.refresh()
  end, item.type)
end

mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
  if state.is_ignored() then return end

  for type, param in pairs(state.items.passive) do
    if player:HasCollectible(type) then
      if not param.possess then
        param.possess = true
        render.refresh()
      end
    else
      param.possess = false
    end
  end
end)
