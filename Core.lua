ACT = LibStub("AceAddon-3.0"):NewAddon("ACT", "AceConsole-3.0", "AceEvent-3.0")

ACT.modules = {}

function ACT:RegisterModule(mod)
    table.insert(self.modules, mod)
end

function ACT:OpenConfig()
    if self.configFrame then
        self.configFrame:Show()
        self:ShowFrontPage()
        return
    end

    local configFrame = CreateFrame("Frame", "ACT_ConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    configFrame:SetSize(800, 600)
    configFrame:SetPoint("CENTER")
    configFrame:SetFrameStrata("DIALOG")
    configFrame:EnableMouse(true)
    configFrame:SetMovable(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)
    
    if not tContains(UISpecialFrames, configFrame:GetName()) then
        tinsert(UISpecialFrames, configFrame:GetName())
    end

    configFrame:SetScript("OnHide", function(self)
    end)

    configFrame.CloseButton:SetScript("OnClick", function()
        configFrame:Hide()
    end)

    configFrame.title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    configFrame.title:SetPoint("LEFT", configFrame.TitleBg, "LEFT", 5, 0)
    configFrame.title:SetText("Advance Custom Tools")

    local sidebar = CreateFrame("Frame", nil, configFrame)
    sidebar:SetSize(200, 540)
    sidebar:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, -40)

    local content = CreateFrame("Frame", nil, configFrame)
    content:SetSize(560, 540)
    content:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 220, -40)
    configFrame.content = content

    local divider = configFrame:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.5, 0.5, 0.5, 1) 
    divider:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 5, 0)
    divider:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMRIGHT", 5, 0)
    divider:SetWidth(2)

    local homeBtn = CreateFrame("Button", nil, sidebar, "UIPanelButtonTemplate")
    homeBtn:SetSize(180, 25)
    homeBtn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 10, -10)
    homeBtn:SetText("Home")
    homeBtn:SetScript("OnClick", function()
        ACT:ShowFrontPage()
    end)

    for i, mod in ipairs(self.modules) do
        local btn = CreateFrame("Button", nil, sidebar, "UIPanelButtonTemplate")
        btn:SetSize(180, 25)
        btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 10, -10 - (i * 30))
        btn:SetText(mod.title or ("Module " .. i))
        btn:SetScript("OnClick", function()
            ACT:ShowModule(mod)
        end)
    end

    self.configFrame = configFrame
    configFrame:Show()

    self:ShowFrontPage()
end

function ACT:ShowFrontPage()
    if not self.configFrame or not self.configFrame.content then return end
    local content = self.configFrame.content

    for _, child in ipairs({ content:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local front = CreateFrame("Frame", nil, content)
    front:SetAllPoints(content)

    local logo = front:CreateTexture(nil, "ARTWORK")
    logo:SetSize(200, 200)
    logo:SetPoint("TOP", front, "TOP", 0, -20)
    logo:SetTexture("Interface\\AddOns\\ACT\\media\\screaming.png")
    logo:SetTexCoord(0.05, 0.95, 0.05, 0.95)

    local info = front:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    info:SetPoint("TOP", logo, "BOTTOM", 0, -10)
    info:SetPoint("CENTER", front, "CENTER", 0, -20)
    info:SetText("Advance Custom Tools\n\nThe #1 way to upset your raiders")

    front:Show()
end

function ACT:ShowModule(mod)
    if not self.configFrame or not self.configFrame.content then return end
    local content = self.configFrame.content
    for _, child in ipairs({ content:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end
    if mod.CreateConfigPanel then
        mod:CreateConfigPanel(content)
    end
end

function ACT:OpenConfigCommand(input)
    self:OpenConfig()
end

function ACT:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("ACTDB", {
        profile = {
            nicknames = {},
            useNicknameIntegration = true,
        }
    }, true)

    if DefaultNicknames then
        local importString = table.concat(DefaultNicknames, "")
        for _, mod in ipairs(self.modules) do
            if mod.ProcessImportString then
                mod:ProcessImportString(importString)
            end
        end
    end
end

function ACT:OnEnable()
    self:RegisterChatCommand("act", "OpenConfigCommand")
end