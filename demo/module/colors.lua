local M = {}

M.colors = { "Red", "Green", "Blue", "Yellow", "Cyan", "Magenta", "Clear", "White", "Black", "Gray05", "Gray10", "Gray15", "Gray20", "Gray25", "Gray30", "Gray35", "Gray40", "Gray45", "Gray50", "Gray55", "Gray60", "Gray65", "Gray70", "Gray75", "Gray80", "Gray85", "Gray90", "Gray95", "DimGray", "DimGrey", "Gray", "Grey", "LightGray", "LightGrey", "VLightGray", "VLightGrey", "Aquamarine", "BlueViolet", "Brown", "CadetBlue", "Coral", "CornflowerBlue", "DarkGreen", "DarkOliveGreen", "DarkOrchid", "DarkSlateBlue", "DarkSlateGray", "DarkSlateGrey", "DarkTurquoise", "Firebrick", "ForestGreen", "Gold", "Goldenrod", "GreenYellow", "IndianRed", "Khaki", "LightBlue", "LightSteelBlue", "LimeGreen", "Maroon", "MediumAquamarine", "MediumBlue", "MediumForestGreen", "MediumGoldenrod", "MediumOrchid", "MediumSeaGreen", "MediumSlateBlue", "MediumSpringGreen", "MediumTurquoise", "MediumVioletRed", "MidnightBlue", "Navy", "NavyBlue", "Orange", "OrangeRed", "Orchid", "PaleGreen", "Pink", "Plum", "Salmon", "SeaGreen", "Sienna", "SkyBlue", "SlateBlue", "SpringGreen", "SteelBlue", "Tan", "Thistle", "Turquoise", "Violet", "VioletRed", "Wheat", "YellowGreen", "SummerSky", "RichBlue", "Brass", "Copper", "Bronze", "Bronze2", "Silver", "BrightGold", "OldGold", "Feldspar", "Quartz", "Mica", "NeonPink", "DarkPurple", "NeonBlue", "CoolCopper", "MandarinOrange", "LightWood", "MediumWood", "DarkWood", "SpicyPink", "SemiSweetChoc", "BakersChoc", "Flesh", "NewTan", "NewMidnightBlue", "VeryDarkBrown", "DarkBrown", "DarkTan", "GreenCopper", "DkGreenCopper", "DustyRose", "HuntersGreen", "Scarlet", "Med_Purple", "Light_Purple", "Very_Light_Purple" }

function M.random()
  return M.colors[ math.random( #M.colors ) ]
end

return M

