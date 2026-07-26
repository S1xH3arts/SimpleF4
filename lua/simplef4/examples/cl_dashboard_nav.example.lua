-- CLIENT example: dashboard card + dropdown navbar item.

SimpleF4.RegisterDashboardCard("example_status", {
    Title = "Community",
    Value = "Online",
    Subtitle = "Welcome to the server",
    Order = 50,
})

-- Navbar dropdown is configured in sh_config.lua:
--
-- C.NavDropdown = {
--     Enabled = true,
--     Name = "More",
--     Items = {
--         {
--             Name = "Forums",
--             Type = "url",
--             Value = "https://example.com/forums",
--         },
--     },
-- }
