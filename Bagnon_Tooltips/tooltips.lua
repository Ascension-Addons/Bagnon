--[[
	Bagnon Tooltips
		Does ownership tooltips based on Bagnon_Forever data
--]]

local currentPlayer = UnitName('player')
local itemInfo = {}
local SILVER = '|cffc7c7cf%s|r'
local TEAL = '|cff00ff9a%s|r'

local function CountsToInfoString(invCount, bankCount, equipCount, pbankCount, rbankCount)
	local info
	local total = invCount + bankCount + equipCount + pbankCount

	if invCount > 0 then
		info = BAGNON_NUM_BAGS:format(invCount)
	end

	if bankCount > 0 then
		local count = BAGNON_NUM_BANK:format(bankCount)
		if info then
			info = strjoin(', ', info, count)
		else
			info = count
		end
	end
	
	if pbankCount > 0 then
		local count = BAGNON_NUM_PBANK:format(pbankCount)
		if info then
			info = strjoin(', ', info, count)
		else
			info = count
		end
	end
	
	if rbankCount > 0 then
		local count = BAGNON_NUM_RBANK:format(rbankCount)
		if info then
			info = strjoin(', ', info, count)
		else
			info = count
		end
	end

	if equipCount > 0 then
		if info then
			info = strjoin(', ', info, BAGNON_EQUIPPED)
		else
			info = BAGNON_EQUIPPED
		end
	end

	if info then
		if total and not(total == invCount or total == bankCount or total == equipCount) then
			--split into two steps for debugging purposes
			local totalStr = format(TEAL, total)
			return totalStr .. format(SILVER, format(' (%s)', info))
		end
		return format(TEAL, info)
	end
end

local currentRealm = GetRealmName() --what currentRealm we're on

--make up the self populating table
do
	for player in BagnonDB:GetPlayers() do
		if player ~= currentPlayer and player ~= currentRealm then
			itemInfo[player] = setmetatable({}, {__index = function(self, link)
			
				local invCount = BagnonDB:GetItemCount(link, KEYRING_CONTAINER, player)
				for bag = 0, NUM_BAG_SLOTS do
					invCount = invCount + BagnonDB:GetItemCount(link, bag, player)
				end

				local bankCount = BagnonDB:GetItemCount(link, BANK_CONTAINER, player)
				for i = 1, NUM_BANKBAGSLOTS do
					bankCount = bankCount + BagnonDB:GetItemCount(link, NUM_BAG_SLOTS + i, player)
				end
				
				local personalBankCount = 0
				for i = 1, 6 do
					personalBankCount = personalBankCount + BagnonDB:GetItemCount(link, i + ASC_PERSONAL_BANK_OFFSET, player)
				end
				
				local realmBankCount = 0
				for i = 1, 6 do
					realmBankCount = realmBankCount + BagnonDB:GetItemCount(link, i + ASC_REALM_BANK_OFFSET, player)
				end		

				local equipCount = BagnonDB:GetItemCount(link, 'e', player)

				self[link] = CountsToInfoString(invCount or 0, bankCount or 0, equipCount or 0, personalBankCount or 0, realmBankCount or 0) or ''
				return self[link]
			end})
		end
	end
end

local function AddOwners(frame, link)
	for player in BagnonDB:GetPlayers() do
		local infoString
		
		
		if player == currentRealm then
			local realmBankCount = 0
			for i = 1, 6 do
				realmBankCount = realmBankCount + BagnonDB:GetItemCount(link, i + ASC_REALM_BANK_OFFSET, player)
			end

			infoString = CountsToInfoString(0,0,0,0, realmBankCount or 0)
		elseif player == currentPlayer then
			local invCount = BagnonDB:GetItemCount(link, KEYRING_CONTAINER, player)
			for bag = 0, NUM_BAG_SLOTS do
				invCount = invCount + BagnonDB:GetItemCount(link, bag, player)
			end

			local bankCount = BagnonDB:GetItemCount(link, BANK_CONTAINER, player)
			for i = 1, NUM_BANKBAGSLOTS do
				bankCount = bankCount + BagnonDB:GetItemCount(link, NUM_BAG_SLOTS + i, player)
			end
			
			local personalBankCount = 0
			for i = 1, 6 do
				personalBankCount = personalBankCount + BagnonDB:GetItemCount(link, i + ASC_PERSONAL_BANK_OFFSET, player)
			end
			
			local equipCount = BagnonDB:GetItemCount(link, 'e', player)

			infoString = CountsToInfoString(invCount or 0, bankCount or 0, equipCount or 0, personalBankCount or 0, 0)
		else
			infoString = itemInfo[player][link]
		end

		if infoString and infoString ~= '' then
			frame:AddDoubleLine(format(TEAL, player), infoString)
		end
	end
	frame:Show()
end

local function HookTip(tooltip)
	tooltip:HookScript('OnTooltipSetItem', function(self, ...)
		local itemLink = select(2, self:GetItem())
		if itemLink and GetItemInfo(itemLink) then --fix for blizzard doing craziness when doing getiteminfo
			AddOwners(self, itemLink)
		end
	end)
end

HookTip(GameTooltip)
HookTip(ItemRefTooltip)
