-- Example: custom job requirement.
-- Put this in a shared Lua file that loads after SimpleF4.

hook.Add("InitPostEntity", "SimpleF4.ExampleJobRequirement", function()
    if not TEAM_CHIEF then return end

    SimpleF4.AddJobRequirement(TEAM_CHIEF, {
        Text = "Must currently be Civil Protection",

        Check = function(ply)
            return TEAM_POLICE and ply:Team() == TEAM_POLICE
        end,
    })
end)
