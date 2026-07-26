-- CLIENT example: extra entity / weapon actions.

SimpleF4.AddEntityButton("Money Printer", {
    Text = "INFO",
    Tooltip = "Open custom printer information.",
    Order = 10,

    DoClick = function(ply, entData)
        print("Entity action:", entData.name)
    end,
})

SimpleF4.AddWeaponButton("AK-47", {
    Text = "PREVIEW",
    Tooltip = "Open a custom weapon preview.",
    Order = 10,

    DoClick = function(ply, shipment)
        print("Weapon action:", shipment.name)
    end,
})
