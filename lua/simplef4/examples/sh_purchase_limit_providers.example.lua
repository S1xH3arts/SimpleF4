-- SHARED example: custom purchase-limit providers.
-- These are templates only and are not loaded automatically.

-- Providers run after the SimpleF4_GetPurchaseLimit hook.
-- Lower Priority values run first.
SimpleF4.RegisterPurchaseLimitProvider(
    "MyInventory",
    function(kind, data, ply)
        if kind ~= "Entities" then return end
        if data.name ~= "Money Printer" then return end

        -- Replace these with values from your inventory/limit addon.
        local currentOwned = 1
        local maximumAllowed = 4

        return currentOwned, maximumAllowed
    end,
    50
)

-- A provider can return only a maximum when the current count
-- cannot safely be determined:
SimpleF4.RegisterPurchaseLimitProvider(
    "ShipmentMaximumOnly",
    function(kind, data, ply)
        if kind ~= "Weapons" then return end
        if not data.max then return end

        return nil, data.max
    end,
    200
)

-- The original hook remains supported:
--
-- hook.Add("SimpleF4_GetPurchaseLimit", "MyLimits", function(kind, data, ply)
--     return currentOwned, maximumAllowed
-- end)
