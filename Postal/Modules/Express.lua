local Postal = LibStub("AceAddon-3.0"):GetAddon("Postal")
local Postal_Express = Postal:NewModule("Express", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Postal")
Postal_Express.description = L["Mouse click short cuts for mail."]
Postal_Express.description2 = L[ [[|cFFFFCC00*|r Shift-Click to take item/money from mail.
|cFFFFCC00*|r Alt-Click to move an item from your inventory to the current outgoing mail (same as right click in default UI).]] ]

local _G = getfenv(0)

function Postal_Express:OnEnable()
	self:SecureHook("InboxFrameItem_OnEnter")
	self:SecureHookScript(GameTooltip, "OnTooltipSetItem")
	self:SecureHook("ContainerFrameItemButton_OnModifiedClick")
end

-- Disabling modules unregisters all events/hook automatically
--function Postal_Express:OnDisable()
--end

local CreateTextureMarkup = function(file, fileWidth, fileHeight, width, height, left, right, top, bottom, xOffset, yOffset)
	return ("|T%s:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d|t"):format(
		  file
		, height
		, width
		, xOffset or 0
		, yOffset or 0
		, fileWidth
		, fileHeight
		, left * fileWidth
		, right * fileWidth
		, top * fileHeight
		, bottom * fileHeight
	);
end

function Postal_Express:InboxFrameItem_OnEnter(this, motion)
	local tooltip = GameTooltip

	local money, COD, _, hasItem = select(5, GetInboxHeaderInfo(this.index))
	if Postal.db.profile.Express.MultiItemTooltip and hasItem and hasItem > 1 then
		for i = 1, ATTACHMENTS_MAX_RECEIVE do
			local name, itemTexture, count, quality, canUse = GetInboxItem(this.index, i);
			if name then
				local itemLink = GetInboxItemLink(this.index, i) or name;
				local icon = CreateTextureMarkup(itemTexture, 64, 64, 12, 12, 0, 1, 0, 1)
				if count > 1 then
					tooltip:AddLine(("%s %sx%d"):format(icon, itemLink, count))
				else
					tooltip:AddLine(("%s %s"):format(icon, itemLink))
				end
			end
		end
	end
	if ((money or 0) > 0 or hasItem) and (not COD or COD == 0) then
		tooltip:AddLine(L["|cffeda55fShift-Click|r to take the contents."])
	end
	tooltip:Show()
end

function Postal_Express:OnTooltipSetItem(tooltip, ...)
	local recipient = SendMailNameEditBox:GetText()
	if Postal.db.profile.Express.EnableAltClick and Postal.db.profile.Express.AutoSend and recipient ~= "" and SendMailFrame:IsVisible() and not CursorHasItem() then
		tooltip:AddLine(string.format(L["|cffeda55fAlt-Click|r to send this item to %s."], recipient))
	end
end

function Postal_Express:ContainerFrameItemButton_OnModifiedClick(this, button, ...)
	if button == "LeftButton" and IsAltKeyDown() and Postal.db.profile.Express.EnableAltClick and SendMailFrame:IsVisible() and not CursorHasItem() then
		local bag = this.GetBagID and this:GetBagID() or this:GetParent():GetID()
		local slot = this:GetID()
		local texture, count = GetContainerItemInfo(bag, slot)
		PickupContainerItem(bag, slot)
		ClickSendMailItemButton()
		if Postal.db.profile.Express.AutoSend then
			for i = 1, ATTACHMENTS_MAX_SEND do
				-- get info about the attachment
				local itemName, itemTexture, stackCount, quality = GetSendMailItem(i)
				if SendMailNameEditBox:GetText() ~= "" and texture == itemTexture and count == stackCount then
					SendMailFrame_SendMail()
				end
			end
		end
	end
end

function Postal_Express.SetEnableAltClick(dropdownbutton, arg1, arg2, checked)
	Postal.db.profile.Express.EnableAltClick = checked
	-- A hack to get the next button to disable/enable
	local i, j = string.match(dropdownbutton:GetName(), "DropDownList(%d+)Button(%d+)")
	j = tonumber(j) + 1
	if checked then
		_G["DropDownList"..i.."Button"..j]:Enable()
		_G["DropDownList"..i.."Button"..j.."InvisibleButton"]:Hide()
	else
		_G["DropDownList"..i.."Button"..j]:Disable()
		_G["DropDownList"..i.."Button"..j.."InvisibleButton"]:Show()
	end
end

function Postal_Express.SetAutoSend(dropdownbutton, arg1, arg2, checked)
	Postal.db.profile.Express.AutoSend = checked
end

function Postal_Express.ModuleMenu(self, level)
	if not level then return end
	local info = self.info
	wipe(info)
	if level == 1 + self.levelAdjust then
		local db = Postal.db.profile.Express
		info.keepShownOnClick = 1

		info.text = L["Enable Alt-Click to send mail"]
		info.func = Postal_Express.SetEnableAltClick
		info.checked = db.EnableAltClick
		UIDropDownMenu_AddButton(info, level)

		info.text = L["Auto-Send on Alt-Click"]
		info.func = Postal_Express.SetAutoSend
		info.checked = db.AutoSend
		info.disabled = not Postal.db.profile.Express.EnableAltClick
		UIDropDownMenu_AddButton(info, level)

		info.text = L["Add multiple item mail tooltips"]
		info.func = Postal.SaveOption
		info.checked = db.MultiItemTooltip
		info.arg1 = "Express"
		info.arg2 = "MultiItemTooltip"
		info.disabled = nil
		UIDropDownMenu_AddButton(info, level)
	end
end
