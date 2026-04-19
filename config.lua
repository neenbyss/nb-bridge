-- ================================================
-- NB-BRIDGE CONFIGURATION
-- Default values used when the consumer script
-- does not provide its own Config table.
-- ================================================

BridgeConfig = {
    -- Enable debug prints for nb-bridge modules
    Debug = false,

    -- Default admin groups (used by Bridge.IsAdmin when
    -- the consumer script has no Config.AdminGroups)
    AdminGroups = { 'admin', 'superadmin', 'god' },

    -- Default stash settings (used by Bridge.RegisterStash
    -- when the consumer script has no Config.Stash)
    Stash = {
        Slots = 50,
        MaxWeight = 100000,
    },

    -- Inventory image paths per system (used by Bridge.GetImagePath)
    --
    -- origen_inventory ships in two NUI layouts depending on the release
    -- branch. The default below targets **v2** (the current branch), which
    -- serves icons from `ui/images/`. Servers still running the legacy
    -- **v1** build serve them from `html/images/` — override from the
    -- consumer script's Config.InventoryImagePaths if that's your case:
    --
    --     Config.InventoryImagePaths = {
    --         origen_inventory = 'nui://origen_inventory/html/images/%s.png',
    --     }
    --
    -- There is no reliable way to autodetect the origen branch at runtime,
    -- so we pick v2 as the default and leave v1 opt-in.
    InventoryImagePaths = {
        ox_inventory      = 'nui://ox_inventory/web/images/%s.png',
        ['qb-inventory']  = 'nui://qb-inventory/html/images/%s.png',
        ['ps-inventory']  = 'nui://ps-inventory/html/images/%s.png',
        ['lj-inventory']  = 'nui://lj-inventory/html/images/%s.png',
        ['qs-inventory']  = 'nui://qs-inventory/html/images/%s.png',
        origen_inventory  = 'nui://origen_inventory/ui/images/%s.png',
    },
}
