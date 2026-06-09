local mod = RegisterMod("Lazy Delver", 1)

mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, require("lazy_delver.map_data").load)
