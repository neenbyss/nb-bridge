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
    InventoryImagePaths = {
        ox_inventory      = 'nui://ox_inventory/web/images/%s.png',
        ['qb-inventory']  = 'nui://qb-inventory/html/images/%s.png',
        ['ps-inventory']  = 'nui://ps-inventory/html/images/%s.png',
        ['lj-inventory']  = 'nui://lj-inventory/html/images/%s.png',
        ['qs-inventory']  = 'nui://qs-inventory/html/images/%s.png',
        origen_inventory  = 'nui://origen_inventory/html/images/%s.png',
    },
}
