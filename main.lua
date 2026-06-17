local mod = RegisterMod("Lazy Delver", 1)

local map = require("lazy_delver.map")
local room = require("lazy_delver.room")
local render = require("lazy_delver.render")

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
  map.refresh()
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

mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, type)
  if type == CollectibleType.COLLECTIBLE_CRYSTAL_BALL or
     type == CollectibleType.COLLECTIBLE_BOOK_OF_SECRETS then
    render.refresh()
  elseif type == CollectibleType.COLLECTIBLE_DADS_KEY then
    local lid = Game():GetLevel():GetCurrentRoomDesc().ListIndex
    map.clear_neighbors_to_check(lid)
    render.refresh()
  end
end)

mod:AddCallback(ModCallbacks.MC_USE_CARD, function(_, type)
  if type == Card.CARD_SUN or
     type == Card.CARD_WORLD or
     type == Card.RUNE_ANSUZ then
    render.refresh()
  elseif type == Card.CARD_GET_OUT_OF_JAIL then
    local lid = Game():GetLevel():GetCurrentRoomDesc().ListIndex
    map.clear_neighbors_to_check(lid)
    render.refresh()
  end
end)

mod:AddCallback(ModCallbacks.MC_USE_PILL, function(_, type)
  if type == PillEffect.PILLEFFECT_SEE_FOREVER then
    render.refresh()
  end
end)

mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
  if map.is_ignored() then return end

  for type, collected in pairs(map.special_items) do
    if player:HasCollectible(type) then
      if not collected then
        map.special_items[type] = true
        render.refresh()
      end
    else
      map.special_items[type] = false
    end
  end
end)
