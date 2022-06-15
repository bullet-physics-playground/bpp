module("metal", package.seeall);

metals = { "Chrome_Metal", "Brass_Metal", "Bronze_Metal", "Gold_Metal", "Silver_Metal", "Copper_Metal", "Polished_Chrome", "Polished_Brass", "New_Brass", "Spun_Brass", "Brushed_Aluminum", "Silver1", "Silver2", "Silver3", "Brass_Valley", "Rust", "Rusty_Iron", "Soft_Silver", "New_Penny", "Tinny_Brass", "Gold_Nugget", "Aluminum", "Bright_Bronze" }

function random()
  return metals[ math.random( #metals ) ]
end
