local UI = {}

-- Template: Standard Button
function UI:CreateButton(parent, text, width, height, onClickCallback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, height)
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.text:SetPoint("CENTER")
    button.text:SetText(text)
    button:SetScript("OnClick", onClickCallback)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1
    })
    button:SetBackdropColor(0.1, 0.1, 0.1, 1)
    button:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.2, 0.2, 0.2, 1)
        self:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    end)

    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.1, 0.1, 0.1, 1)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end)


    return button
end

-- Template: Dropdown
local activeDropdown = nil  

function UI:CreateDropdown(parent, width, height)
    local dropdown = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    dropdown:SetSize(width, height)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1
    })
    dropdown:SetBackdropColor(0.1, 0.1, 0.1, 1)
    dropdown:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    dropdown.button = UI:CreateButton(dropdown, "Select", width, height)
    dropdown.button:SetAllPoints(dropdown)
    dropdown.button.text:SetJustifyH("LEFT")
    dropdown.button.text:SetPoint("LEFT", 5, 0)

    dropdown.button.arrow = dropdown.button:CreateTexture(nil, "OVERLAY")
    dropdown.button.arrow:SetSize(12, 12)
    dropdown.button.arrow:SetPoint("RIGHT", -5, 0)
    dropdown.button.arrow:SetTexture("Interface\\Buttons\\UI-SortArrow")
    dropdown.button.arrow:SetTexCoord(0, 1, 0, 1)

    dropdown.list = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    dropdown.list:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    dropdown.list:SetSize(width, 150)
    dropdown.list:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1
    })
    dropdown.list:SetBackdropColor(0, 0, 0, 0.9)
    dropdown.list:SetBackdropBorderColor(0, 0, 0, 1)
    dropdown.list:SetFrameStrata("TOOLTIP") 
    dropdown.list:Hide()

    dropdown.scrollFrame = CreateFrame("ScrollFrame", nil, dropdown.list, "UIPanelScrollFrameTemplate")
    dropdown.scrollFrame:SetPoint("TOPLEFT", 5, -5)
    dropdown.scrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)
    
    dropdown.scrollChild = CreateFrame("Frame")
    dropdown.scrollChild:SetSize(width - 20, 150)
    dropdown.scrollFrame:SetScrollChild(dropdown.scrollChild)

    dropdown.button:SetScript("OnClick", function()
        if activeDropdown and activeDropdown ~= dropdown then
            activeDropdown.list:Hide() 
        end

        dropdown.list:SetShown(not dropdown.list:IsShown())

        if dropdown.list:IsShown() then
            activeDropdown = dropdown
        else
            activeDropdown = nil
        end

        if dropdown.list:IsShown() then
            local frame = CreateFrame("Frame")
            frame:SetScript("OnMouseDown", function(_, button)
                if button == "LeftButton" and not MouseIsOver(dropdown.list) and not MouseIsOver(dropdown) then
                    dropdown.list:Hide()
                    activeDropdown = nil
                    frame:SetScript("OnMouseDown", nil)
                end
            end)
        end
    end)

    dropdown:SetScript("OnHide", function() 
        dropdown.list:Hide()
        if activeDropdown == dropdown then
            activeDropdown = nil
        end
    end)

    return dropdown
end

function UI:AddDropdownOption(dropdown, text, value, onClick)
    local option = CreateFrame("Frame", nil, dropdown.scrollChild, "BackdropTemplate")
    option:SetSize(dropdown:GetWidth() - 10, 20)
    option:SetPoint("TOPLEFT", dropdown.scrollChild, "TOPLEFT", 5, -((#dropdown.scrollChild.buttons or 0) * 20))

    option.text = option:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    option.text:SetText(text)
    option.text:SetJustifyH("LEFT")
    option.text:SetPoint("LEFT", option, "LEFT", 5, 0)

    option:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8"
    })
    option:SetBackdropColor(0, 0, 0, 0) 

    option:SetScript("OnEnter", function(self)
        self:SetBackdropColor(1, 1, 1, 0.2) 
    end)
    option:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0, 0, 0, 0)  
    end)

    option:SetScript("OnMouseUp", function()
        dropdown.button.text:SetText(text)
        dropdown.selectedValue = value
        dropdown.list:Hide()
        if onClick then onClick() end
    end)

    dropdown.scrollChild.buttons = dropdown.scrollChild.buttons or {}
    table.insert(dropdown.scrollChild.buttons, option)
end


function UI:SetDropdownOptions(dropdown, options)
    if dropdown.scrollChild.buttons then
        for _, btn in ipairs(dropdown.scrollChild.buttons) do
            btn:Hide()
            btn:SetParent(nil)
        end
    end
    dropdown.scrollChild.buttons = {}

    for _, opt in pairs(options) do
        UI:AddDropdownOption(dropdown, opt.text, opt.value, opt.onClick)
    end
end

_G["UI"] = UI