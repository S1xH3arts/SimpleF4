-- Shared example: integrate a custom inventory/limit addon.
-- Return current count and maximum count.

hook.Add(
    "SimpleF4_GetPurchaseLimit",
    "SimpleF4.ExampleCustomLimit",
    function(kind, data, ply)
        if kind ~= "Entities" then return end
        if data.name ~= "Money Printer" then return end

        -- Replace these values with your real addon data.
        local current = 1
        local maximum = 3

        return current, maximum
    end
)

-- You can also provide a custom eligibility reason.
hook.Add(
    "SimpleF4_EntityEligibility",
    "SimpleF4.ExampleVIPRequirement",
    function(data, ply)
        if data.name ~= "VIP Printer" then return end

        if not ply:IsUserGroup("vip") then
            return "VIP rank required"
        end
    end
)
