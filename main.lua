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
  local function check(param, has)
    if not has then
      param.possess = false
      return
    end
    if not param.possess then
      param.possess = true
      render.refresh()
    end
  end

  local active0, active1 = player:GetActiveItem(0), player:GetActiveItem(1)
  check(state.items.red[CollectibleType.COLLECTIBLE_RED_KEY],
    (active0 == CollectibleType.COLLECTIBLE_RED_KEY) or
    (active1 == CollectibleType.COLLECTIBLE_RED_KEY)
  )

  local card0, card1 = player:GetCard(0), player:GetCard(1)
  check(state.items.red[Card.CARD_CRACKED_KEY],
    (card0 == Card.CARD_CRACKED_KEY) or
    (card1 == Card.CARD_CRACKED_KEY)
  )
  check(state.items.red[Card.CARD_SOUL_CAIN],
    (card0 == Card.CARD_SOUL_CAIN) or
    (card1 == Card.CARD_SOUL_CAIN)
  )

  for type, param in pairs(state.items.passive) do
    check(param, player:HasCollectible(type))
  end
end)
