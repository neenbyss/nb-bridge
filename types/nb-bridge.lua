--- @meta
-- nb-bridge v2.0.0 type definitions
-- Do NOT require() this file — it is a type stub only.
-- LuaLS loads it automatically when .luarc.json includes "types/" in workspace.library.

-- ============================================================
-- HELPER CLASSES (used as return types throughout the API)
-- ============================================================

--- Canonical job table returned by bridge.player.getJob() on both server and client.
--- @class BridgeJobData
--- @field name string Job identifier, e.g. 'police'
--- @field label string Display name, e.g. 'Police'
--- @field grade number Grade level number
--- @field grade_name string Grade internal name
--- @field grade_label string Grade display name
--- @field grade_salary number Salary for this grade
--- @field onDuty boolean true if the player is on duty

--- Canonical gang table returned by bridge.player.getGang() on both server and client.
--- QBCore/QBX only — nil on ESX.
--- @class BridgeGangData
--- @field name string Gang identifier
--- @field label string Display name
--- @field grade number Grade level number
--- @field grade_name string Grade internal name
--- @field grade_label string Grade display name

--- Identity data returned by bridge.license.getIdentity().
--- ESX: dob and sex are always nil. QBCore/QBX: sex is 'M' or 'F'.
--- @class BridgeIdentityData
--- @field firstname string
--- @field lastname string
--- @field dob string|nil Date of birth (QBCore/QBX only)
--- @field sex 'M'|'F'|nil Gender (QBCore/QBX only)

--- License status table returned by bridge.license.getDriverLicense() and bridge.license.getWeaponLicense().
--- @class BridgeLicenseData
--- @field hasLicense boolean Whether the player holds this license
--- @field label string License display label, or '' when not held

--- Diagnostics result returned by Bridge.diagnostics().
--- @class BridgeDiagnosticsResult
--- @field version string Bridge version string
--- @field framework 'ESX'|'QBCore'|'QBX'|nil Detected framework
--- @field frameworkVersion string|nil Framework version string
--- @field inventorySystem 'ox_inventory'|'qb-inventory'|'qs-inventory'|'origen_inventory'|'default'|nil Detected inventory system
--- @field side 'server'|'client' Execution side
--- @field features table<string, boolean> Feature capability flags
--- @field uptime number Resource uptime in seconds

-- ============================================================
-- NAMESPACE CLASSES
-- ============================================================

--- Server and client player management methods.
--- Server methods require `source` (player server ID) as first arg.
--- Client methods operate on the local player and take no source.
--- @class BridgePlayer

-- ---- SERVER-SIDE PLAYER METHODS ----

--- Get the raw framework player object (xPlayer for ESX, Player for QBCore/QBX).
--- Use the normalised methods below for portable code.
--- @field getPlayer fun(source: number): table|nil

--- Get player identifier. Returns license:XXXX for ESX, citizenid for QBCore/QBX.
--- @field getIdentifier fun(source: number): string|nil

--- Get player SSN in format XXX-XX-XXXX. ESX only — returns nil on QBCore/QBX.
--- @field getSSN fun(source: number): string|nil

--- Get player full character name (firstname lastname).
--- Falls back to GetPlayerName(source) when framework object is unavailable.
--- @field getPlayerName fun(source: number): string

--- Get player permission group.
--- ESX: reads xPlayer.getGroup(). QBCore/QBX: walks BridgeConfig.GroupMap ACE nodes.
--- Returns 'user' when no higher group matches.
--- @field getGroup fun(source: number): 'god'|'superadmin'|'admin'|'mod'|'user'

--- Set player group. ESX only — returns false on QBCore/QBX.
--- @field setGroup fun(source: number, group: string): boolean

--- Check whether player is in Config.AdminGroups (or BridgeConfig.AdminGroups).
--- @field isAdmin fun(source: number): boolean

--- Get player money for one account. Never returns nil — 0 on error.
--- ESX maps 'cash' to the internal 'money' account.
--- @field getMoney fun(source: number, moneyType: 'cash'|'bank'): number

--- Add money to player account.
--- NOTE: ESX returns true whenever xPlayer is non-nil (addAccountMoney has no return value).
--- Guards: returns false when amount <= 0 or nil.
--- @field addMoney fun(source: number, moneyType: 'cash'|'bank', amount: number, reason?: string): boolean

--- Remove money from player account.
--- ESX pre-checks balance and returns false on insufficient funds.
--- @field removeMoney fun(source: number, moneyType: 'cash'|'bank', amount: number, reason?: string): boolean

--- Set player account to exact amount.
--- @field setMoney fun(source: number, moneyType: 'cash'|'bank', amount: number, reason?: string): boolean

--- Get all player accounts in normalised format {cash=number, bank=number, ...}.
--- ESX maps the 'money' account key to 'cash'. Returns {} on error.
--- @field getAccounts fun(source: number): table<string, number>

--- Get player job in canonical BridgeJobData format. Returns nil when player not found.
--- @field getJob fun(source: number): BridgeJobData|nil

--- Set player job. onDuty is ESX-only — ignored on QBCore/QBX.
--- @field setJob fun(source: number, job: string, grade: number, onDuty?: boolean): boolean

--- Get player gang in canonical BridgeGangData format. QBCore/QBX only — returns nil on ESX.
--- @field getGang fun(source: number): BridgeGangData|nil

--- Set player gang. QBCore/QBX only — always returns false on ESX.
--- QBX uses exports.qbx_core:SetGang with pcall + fallback to Player.Functions.SetGang.
--- @field setGang fun(source: number, gangName: string, grade: number): boolean

--- Get all online player source IDs as a number array.
--- QBX: uses GetQBPlayers() (hash table) and extracts keys. ESX: extracts .source from xPlayer array.
--- @field getAllPlayers fun(): number[]

--- Get player playtime in seconds. ESX only — returns nil on QBCore/QBX.
--- @field getPlayTime fun(source: number): number|nil

--- Get player world coordinates.
--- @field getCoords fun(source: number): vector3|nil

--- Set / teleport player to coordinates.
--- @field setCoords fun(source: number, coords: vector3|vector4|table): boolean

--- Trigger a client event for this player.
--- ESX prefers xPlayer.triggerEvent when available; falls back to TriggerClientEvent.
--- @field triggerClientEvent fun(source: number, eventName: string, ...: any)

--- Get or set an xPlayer variable. ESX only — returns nil on QBCore/QBX.
--- Get: playerVar(source, key) → value|nil
--- Set: playerVar(source, key, value) → true
--- @field playerVar fun(source: number, key: string, value?: any): any|nil

--- Set player metadata. subIndex uses dot notation on QBX.
--- @field setMeta fun(source: number, index: string, value: any, subIndex?: string): boolean

--- Get player metadata. index=nil returns full metadata table.
--- @field getMeta fun(source: number, index?: string, subIndex?: string): any

--- Clear player metadata key (or sub-key).
--- @field clearMeta fun(source: number, index: string, subIndex?: string): boolean

--- Execute a command on behalf of player. ESX only — returns false on QBCore/QBX.
--- @field executeCommand fun(source: number, command: string): boolean

--- Create a bill/invoice via the server's billing system.
--- ESX: requires jobName or returns false. Falls back to okokBilling when primary is unavailable.
--- @field createBill fun(src: number, targetId: number, amount: number, description?: string, jobName?: string): boolean

--- Register a chat command with optional permission gating and autocomplete suggestion.
--- @field registerCommand fun(name: string, group: 'admin'|'mod'|'god'|'user'|nil, cb: fun(source: number, args: table, rawCommand: string|nil), suggestion?: { help: string, params: { name: string, help: string }[] })

--- Register a server-side callback fired when a player's character data loads.
--- Callback receives (source: number, identifier: string|nil).
--- @field onPlayerLoaded fun(cb: fun(source: number, identifier: string|nil))

--- Register a server-side callback fired when a player disconnects or logs out.
--- QBX: debounced 1 second — cb is called at most once per source per second.
--- @field onPlayerUnloaded fun(cb: fun(source: number))

-- ---- CLIENT-SIDE PLAYER METHODS (no source arg) ----
-- These methods are also members of BridgePlayer.
-- LuaLS resolves them from the same @class block.
-- Overloads that take no source are disambiguated at call sites by arg count.

--- Get raw framework player data (not normalised). ESX: GetPlayerData(). QBX: exports.qbx_core:GetPlayerData().
--- @field getPlayerData fun(): table|nil

--- Register a client-side callback fired when local player data loads. Callback takes no args.
--- @field onPlayerLoaded fun(cb: fun())

--- Register a client-side callback fired when local player logs out. Callback takes no args.
--- @field onPlayerUnloaded fun(cb: fun())

--- Register a client-side callback fired when local player's job changes.
--- Callback receives a BridgeJobData table.
--- @field onJobUpdate fun(cb: fun(job: BridgeJobData))

--- Register a client-side callback fired when local player's gang changes. QBCore/QBX only.
--- Callback receives a BridgeGangData table.
--- @field onGangUpdate fun(cb: fun(gang: BridgeGangData))


--- Server and client inventory management methods.
--- Server methods require `source`; client methods operate on the local player.
--- @class BridgeInventory

-- ---- SERVER-SIDE INVENTORY METHODS ----

--- Add item(s) to a player's inventory.
--- NOTE: qs-inventory arg order is (source, item, count, slot, metadata) — slot before metadata.
--- @field addItem fun(source: number, item: string, count: number, metadata?: table|string, slot?: number): boolean

--- Remove item(s) from a player's inventory.
--- NOTE: qs-inventory RemoveItem has no return — always returns true. Pre-validate with hasItem.
--- @field removeItem fun(source: number, item: string, count: number, metadata?: table|string, slot?: number): boolean

--- Check whether a player has at least `count` of an item. count defaults to 1.
--- @field hasItem fun(source: number, item: string, count?: number): boolean

--- Check whether a player can carry `count` more of an item.
--- Returns true unconditionally on qb-inventory and default (no weight check available).
--- @field canCarry fun(source: number, item: string, count?: number, metadata?: table|string): boolean

--- Register a stash with the active inventory system.
--- Slots and MaxWeight are read from Config.Stash or BridgeConfig.Stash.
--- Idempotent — calling twice for the same stashId is a no-op.
--- Not needed for qb-inventory / default — those systems skip server-side registration.
--- @field registerStash fun(stashId: string, label: string, jobName?: string, coords?: vector3)

--- Check whether registerStash was already called for this stashId in this session.
--- @field isStashRegistered fun(stashId: string): boolean

--- Force open a stash for a player from server side.
--- origen_inventory: fires nb-bridge:client:origenOpenInventory (opens client-side).
--- @field forceOpenStash fun(source: number, stashId: string)

--- Force open another player's inventory for `source` from server side.
--- @field forceOpenPlayerInventory fun(source: number, targetServerId: number): boolean

--- Get the full item registry from the active inventory system.
--- @field getAllItems fun(): table

--- Register a usable item handler. Idempotent — registering the same item twice is ignored.
--- origen_inventory: registers ONLY through origen (not framework) to prevent double-fire.
--- Callback receives (source, item) where item = {name: string, slot: number?}.
--- @field registerUsableItem fun(itemName: string, cb: fun(source: number, item: table)): boolean

--- Check whether registerUsableItem was called for this item in this resource session.
--- @field isUsableItemRegistered fun(itemName: string): boolean

--- Get item metadata for the first matching slot in a player's inventory.
--- ox_inventory ONLY — returns nil on all other inventory systems.
--- @field getItemMetadata fun(source: number, itemName: string): table|nil

-- ---- CLIENT-SIDE INVENTORY METHODS ----

--- Open a stash for the local player.
--- @field openStash fun(stashId: string)

--- Open another player's inventory from the client side.
--- @field openPlayerInventory fun(targetServerId: number)

--- Get count of `item` in the local player's inventory.
--- @field getItemCount fun(item: string): number

--- Get the NUI image URL template for the active inventory system.
--- Use string.format with the item name: path:format('water') → full URL.
--- @field getImagePath fun(): string


--- Client-side vehicle management methods.
--- @class BridgeVehicleClient

--- Resolve a model name string to its numeric hash. Passes numbers through unchanged.
--- @field resolveModelHash fun(model: string|number): number

--- Spawn a vehicle at coords and optionally apply properties and plate.
--- Uses a 5-second wall-clock timeout (GetGameTimer). Calls cb(nil) on timeout.
--- Returns the vehicle entity handle or false on failure.
--- @field spawnVehicle fun(model: string|number, coords: vector3, heading: number, props?: table, plate?: string, cb?: fun(vehicle: number|nil)): number|false

--- Get vehicle properties. Prefers lib.getVehicleProperties (ox_lib) then framework fallback.
--- @field getVehicleProperties fun(vehicle: number): table

--- Set vehicle properties. Prefers lib.setVehicleProperties (ox_lib) then framework fallback.
--- @field setVehicleProperties fun(vehicle: number, props: table)

--- Get a vehicle's human-readable display label from its model name or hash.
--- Returns 'Unknown' when the model is not found.
--- @field getVehicleLabel fun(model: string|number): string


--- Server-side vehicle management methods.
--- @class BridgeVehicleServer

--- Generate a random 8-character uppercase alphanumeric plate string.
--- @field generatePlate fun(): string

--- Normalize a GTA plate string by stripping trailing spaces.
--- @field normalizePlate fun(plate: string|nil): string

--- Insert a vehicle into the framework's ownership database (MySQL.insert.await).
--- ESX: owned_vehicles. QBCore/QBX: player_vehicles.
--- plate is auto-generated if not present in props.
--- @field giveVehicle fun(source: number, model: string, props?: table): boolean

--- Query the DB for the full name of the player who owns `plate`. Returns nil when not found.
--- @field getVehicleOwnerName fun(plate: string): string|nil


--- Vehicle namespace — contains methods that differ between server and client.
--- normalizePlate is available on both sides.
--- @class BridgeVehicle
--- @field normalizePlate fun(plate: string|nil): string
--- @field generatePlate fun(): string
--- @field giveVehicle fun(source: number, model: string, props?: table): boolean
--- @field getVehicleOwnerName fun(plate: string): string|nil
--- @field resolveModelHash fun(model: string|number): number
--- @field spawnVehicle fun(model: string|number, coords: vector3, heading: number, props?: table, plate?: string, cb?: fun(vehicle: number|nil)): number|false
--- @field getVehicleProperties fun(vehicle: number): table
--- @field setVehicleProperties fun(vehicle: number, props: table)
--- @field getVehicleLabel fun(model: string|number): string


--- Notification methods for sending and showing notifications.
--- @class BridgeNotify

--- Send a notification to a specific player from server-side code.
--- Internally fires a client event routed to Bridge.notify.show.
--- @field send fun(source: number, message: string, type: 'success'|'error'|'info'|'warning')

--- Show a notification on the local client.
--- Detection order: ox_lib → QBX exports → ESX native → QBCore → GTA DrawNotification.
--- NOTE: ESX native does not support type/color — use ox_lib for consistent styled notifications.
--- @field show fun(message: string, type: 'success'|'error'|'info'|'warning')


--- Server-side callback registration and client-side callback triggering.
--- @class BridgeCallback

--- Register a server callback handler. Always call respond() — client times out after 15 seconds.
--- @field register fun(name: string, cb: fun(source: number, respond: fun(...: any), ...: any))

--- Trigger a server callback from the client.
--- cb is called with the server response, or nil after a 15-second timeout.
--- Always nil-guard the first argument inside cb.
--- @field trigger fun(name: string, cb: fun(...: any), ...: any)


--- Server-side license and identity resolution.
--- Supports bcs_licensemanager, okokLicenses, esx_license, QBCore/QBX metadata, ESX default.
--- @class BridgeLicense

--- Get full character identity for a player.
--- ESX: dob and sex are always nil. QBCore/QBX: sex is 'M' or 'F'.
--- @field getIdentity fun(source: number): BridgeIdentityData|nil

--- Get driver license status for a player.
--- @field getDriverLicense fun(source: number): BridgeLicenseData

--- Get weapon / firearms license status for a player.
--- @field getWeaponLicense fun(source: number): BridgeLicenseData


--- Client-side progress bar display.
--- @class BridgeProgress

--- Show a blocking progress bar and return when it completes or is cancelled.
--- ox_lib: canCancel=true — returns false when the player cancels.
--- Native fallback: non-cancellable — always returns true.
--- @field show fun(duration: number, label: string, anim?: { dict: string, name: string }): boolean


--- Event utilities (reserved for future use in Bridge.event.*).
--- @class BridgeEvent


-- ============================================================
-- ROOT Bridge CLASS
-- ============================================================

--- The root Bridge table returned by exports['nb-bridge']:get().
--- Obtain a reference at the top of each script:
---     local bridge = exports['nb-bridge']:get()
--- @class Bridge
--- @field player BridgePlayer Server and client player management
--- @field inventory BridgeInventory Server and client inventory management
--- @field vehicle BridgeVehicle Vehicle utilities (server DB + client spawn/props)
--- @field notify BridgeNotify Notification send (server) and show (client)
--- @field callback BridgeCallback Server callback register and client trigger
--- @field license BridgeLicense Server-side license and identity checks
--- @field progress BridgeProgress Client-side progress bar
--- @field event BridgeEvent Event utilities
--- @field Framework 'ESX'|'QBCore'|'QBX'|nil Detected framework (safe after exports:get())
--- @field FrameworkObject table|nil Raw framework shared object / exports ref
--- @field InventorySystem 'ox_inventory'|'qb-inventory'|'qs-inventory'|'origen_inventory'|'default'|nil Detected inventory system (set ~500ms after boot; safe to read inside events/threads)
--- @field diagnostics fun(): BridgeDiagnosticsResult Return runtime diagnostics snapshot

--- Global Bridge table populated by loader.lua (deprecated v2.0.0).
--- Prefer exports['nb-bridge']:get() in new resources.
--- @type Bridge
Bridge = {}

--- Global configuration table used by nb-bridge modules.
--- Consumer scripts may override keys before Bridge is accessed.
--- @class BridgeConfigTable
--- @field Debug boolean Enable debug prints (default false)
--- @field AdminGroups string[] Groups considered admin for isAdmin() (default {'admin','superadmin','god'})
--- @field Stash { Slots: number, MaxWeight: number } Default stash slot/weight settings
--- @field InventoryImagePaths table<string, string> NUI image URL templates keyed by inventory system
--- @field GroupMap table<string, string> ACE node map for QBCore/QBX group resolution

--- @type BridgeConfigTable
BridgeConfig = {}

--- Global debug printer. Prints only when BridgeConfig.Debug or Config.Debug is true.
--- Tables are auto-encoded to JSON.
--- @param module string Module label for the print prefix
--- @param ... any Values to print
Debugger = function(module, ...) end
