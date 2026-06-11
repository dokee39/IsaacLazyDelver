local mod = RegisterMod("Lazy Delver", 1)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, require("lazy_delver.room").check)
