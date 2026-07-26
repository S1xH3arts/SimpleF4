-- CLIENT example: replace an empty-state message.
-- This is not loaded automatically.

SimpleF4.RegisterEmptyState("Weapons", {
    CanShow = function(ply, context)
        return context.NoAccess == true
    end,

    Title = "Armoury unavailable",
    Text = "Change to an eligible role to access armoury equipment.",
})

SimpleF4.RegisterEmptyState("Entities", {
    CanShow = function(ply, context)
        return context.Affordability == "Affordable"
    end,

    Title = "Nothing affordable",
    Text = "You cannot currently afford any available entities.",
})
