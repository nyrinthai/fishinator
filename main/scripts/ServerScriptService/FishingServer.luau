 

local OffshoreFish = {
	-- COMMON: High spawn rate (approx. 35% total)
	RedSnapper = {
		Values = {Small = 100, Medium = 200, Large = 400},
		Rarity = "Common",
		Weight = 35 -- % chance
	},

	-- RARE: Lower spawn rate (approx. 45% total)
	Sailfish = {
		Values = {Small = 500, Medium = 1000, Large = 2000},
		Rarity = "Rare",
		Weight = 18
	},
	Tuna = {
		Values = {Small = 800, Medium = 1600, Large = 3200},
		Rarity = "Rare",
		Weight = 15
	},
	Swordfish = {
		Values = {Small = 1000, Medium = 2000, Large = 4000},
		Rarity = "Rare",
		Weight = 12
	},

	Marlin = {
		Values = {Small = 3000, Medium = 6000, Large = 9000},
		Rarity = "Legendary",
		Weight = 12
	},

	Fih = {
		Values = {Small = 100000, Medium = 250000, Large = 500000},
		Rarity = "Secret",
		Weight = 8
	}
}
-- have models for all. also have a commonfish and a coelocanth. and anglerfish

local SubFish = {
	Anglerfish = {
		Values = {Small = 3000, Medium = 6000, Large = 9000},
		Rarity = "Rare",
		Weight = 60
	},
	Coelocanth = {
		Values = {Small = 6000, Medium = 9000, Large = 12000},
		Rarity = "Legendary",
		Weight = 40
	}
}


-- Function to pick a random fish name based on chanceweights
function OffshoreFish.getRandomOffshoreFish()
	local roll = math.random() * 100
	local counter = 0

	for name, data in pairs(OffshoreFish) do
		-- Only process if 'data' is a table (the fish) and not a function
		if type(data) == "table" and data.Weight then
			counter = counter + data.Weight
			if roll <= counter then
				return name
			end
		end
	end
end

function OffshoreFish.getRandomSubFish()
	local roll = math.random() * 100
	local counter = 0

	for name, data in pairs(SubFish) do
		-- Only process if 'data' is a table (the fish) and not a function
		if type(data) == "table" and data.Weight then
			counter = counter + data.Weight
			if roll <= counter then
				return name
			end
		end
	end
end


-- TODO MAKE FISHES CAUGHT HAVE RANDOM SIZES AS WELL
-- Function to pick a size
function OffshoreFish.getRandomFishSize()
	local sizes = {"Small", "Medium", "Large"}
	return sizes[math.random(1, #sizes)]
end

return OffshoreFish
 