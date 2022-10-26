--[[
	sortBtn.lua
		imagine a button that sorts your inventory in Bagnon, crazy am I right?!1
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon')
local SortBtn = Bagnon.Classy:New('Button')
Bagnon.SortBtn = SortBtn

local SIZE = 20
local NORMAL_TEXTURE_SIZE = 64 * (SIZE / 36)

-- Bag Sorter code from Sushi Regular
local moves = {};
local frame = CreateFrame("Frame");
local t = 0;
local current = nil;

local function GetIDFromLink(link)
	return link and tonumber(string.match(link, "item:(%d+)"));
end

local function DoMoves()
	while (current ~= nil or #moves > 0) do
		if current ~= nil then
			if CursorHasItem() then
				local _, id = GetCursorInfo();
				if (current ~= nil and current.id == id) then
					if (current.sourcebag ~= nil) then
						PickupContainerItem(current.targetbag, current.targetslot);
						local link = select(7, GetContainerItemInfo(current.targetbag, current.targetslot));
						if (current.id ~= GetIDFromLink(link)) then
							return;
						end
					end
				else
					moves = {};
					current = nil;
					frame:Hide();
					return;
				end
			else
				if (current.sourcebag ~= nil) then
					local link = select(7, GetContainerItemInfo(current.targetbag, current.targetslot));
					if (current.id ~= GetIDFromLink(link)) then
						return;
					end
				end
				current = nil;
			end
		else
			if (#moves > 0) then
				current = table.remove(moves, 1);
				if (current.sourcebag ~= nil) then
					PickupContainerItem(current.sourcebag, current.sourceslot);
					if CursorHasItem() == false then
						return;
					end
					PickupContainerItem(current.targetbag, current.targetslot);
					local link = select(7, GetContainerItemInfo(current.targetbag, current.targetslot));
					if (current.id == GetIDFromLink(link)) then
						current = nil;
					else
						return;
					end
				end

			end
		end
	end
	frame:Hide();
end

local function CompareItems(lItem, rItem)
	if (rItem.id == nil) then
		return true;
	elseif (lItem.id == nil) then
		return false;
	elseif (lItem.class ~= rItem.class) then
		return (lItem.class < rItem.class);
	elseif (lItem.subclass ~= rItem.subclass) then
		return (lItem.subclass < rItem.subclass);
	elseif (lItem.quality ~= rItem.quality) then
		return (lItem.quality > rItem.quality);
	elseif (lItem.name ~= rItem.name) then
		return (lItem.name < rItem.name);
	elseif ((lItem.count) ~= (rItem.count)) then
		return ((lItem.count) >= (rItem.count));
	else
		return true;
	end
end

local function BeginSort()
	current = nil;
	moves = {};
	ClearCursor();
end

local function SortBag(bag)
	for i = 1, #bag, 1 do
		local lowest = i;
		for j = #bag, i + 1, -1 do
			if (CompareItems(bag[lowest], bag[j]) == false) then
				lowest = j;
			end
		end
		if (i ~= lowest) then
			-- store move
			move = {};
			move.id = bag[lowest].id;
			move.name = bag[lowest].name;
			move.sourcebag = bag[lowest].bag;
			move.sourcetab = bag[lowest].tab;
			move.sourceslot = bag[lowest].slot;
			move.targetbag = bag[i].bag;
			move.targettab = bag[i].tab;
			move.targetslot = bag[i].slot;
			table.insert(moves, move);

			-- swap items
			local tmp = bag[i];
			bag[i] = bag[lowest];
			bag[lowest] = tmp;

			-- swap slots
			tmp = bag[i].slot;
			bag[i].slot = bag[lowest].slot;
			bag[lowest].slot = tmp;
			tmp = bag[i].bag;
			bag[i].bag = bag[lowest].bag;
			bag[lowest].bag = tmp;
			tmp = bag[i].tab;
			bag[i].tab = bag[lowest].tab;
			bag[lowest].tab = tmp;
		end
	end
end

local function CreateBagFromID(bagID)
	local items = GetContainerNumSlots(bagID);
	local bag = {};

	for i = 1, items, 1 do
		local item = {};
		local _, count, _, _, _, _, link = GetContainerItemInfo(bagID, i);
		item.bag = bagID;
		item.slot = i;
		item.name = "<EMPTY>";
		item.id = GetIDFromLink(link);
		if (item.id ~= nil) then
			item.count = count;
			item.name, _, item.quality, _, _, item.class, item.subclass, _, item.type, _, item.price = GetItemInfo(item.id);
		end
		table.insert(bag, item);
	end
	return bag;
end

frame:SetScript("OnUpdate", function()
	t = t + arg1;
	if t > 0.03 then
		t = 0
		DoMoves();
	end
end)
frame:Hide();
--

--[[ Constructor ]] --
function SortBtn:New(frameID, parent)
	local b = self:Bind(CreateFrame('Button', nil, parent))
	b:SetWidth(SIZE)
	b:SetHeight(SIZE)
	b:RegisterForClicks('anyUp')

	local nt = b:CreateTexture()
	nt:SetTexture([[Interface\Buttons\UI-Quickslot2]])
	nt:SetWidth(NORMAL_TEXTURE_SIZE)
	nt:SetHeight(NORMAL_TEXTURE_SIZE)
	nt:SetPoint('CENTER', 0, -1)
	b:SetNormalTexture(nt)

	local pt = b:CreateTexture()
	pt:SetTexture([[Interface\Buttons\UI-Quickslot-Depress]])
	pt:SetAllPoints(b)
	b:SetPushedTexture(pt)

	local ht = b:CreateTexture()
	ht:SetTexture([[Interface\Buttons\ButtonHilight-Square]])
	ht:SetAllPoints(b)
	b:SetHighlightTexture(ht)

	local icon = b:CreateTexture()
	icon:SetAllPoints(b)
	icon:SetTexture([[Interface\Icons\ability_racial_bagoftricks]])

	b:SetScript('OnClick', b.OnClick)
	b:SetScript('OnEnter', b.OnEnter)
	b:SetScript('OnLeave', b.OnLeave)
	b:SetFrameID(frameID)

	return b
end

--[[ Frame Events ]] --
function SortBtn:OnClick()
	local bags = {};
	for i = 0, NUM_BAG_FRAMES, 1 do
		local bag = CreateBagFromID(i);
		local type = select(2, GetContainerNumFreeSlots(i));
		if type == nil then
			type = "ALL"
		else
			type = tostring(type);
		end
		if bags[type] == nil then
			bags[type] = bag;
		else
			for j = 1, #bag, 1 do
				table.insert(bags[type], bag[j]);
			end
		end
	end

	BeginSort();
	for k, v in pairs(bags) do
		if v ~= nil then
			SortBag(v);
		end
	end
	frame:Show();
end

function SortBtn:OnEnter()
	if self:GetRight() > (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end
	self:UpdateTooltip()
end

function SortBtn:OnLeave()
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
end

--[[ Update Methods ]] --

function SortBtn:UpdateTooltip()
	if GameTooltip:IsOwned(self) then
		GameTooltip:SetText(L.TipShowSortBtn)
	end
end

--[[ Properties ]] --

function SortBtn:SetFrameID(frameID)
	if self:GetFrameID() ~= frameID then
		self.frameID = frameID
	end
end

function SortBtn:GetFrameID()
	return self.frameID
end
