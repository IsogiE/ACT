ACT = LibStub("AceAddon-3.0"):NewAddon("ACT", "AceConsole-3.0", "AceEvent-3.0")

UI = _G["UI"]

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

    local configFrame = CreateFrame("Frame", "ACT_ConfigFrame", UIParent)
    configFrame:SetSize(800, 600)
    configFrame:SetPoint("CENTER")
    configFrame:SetFrameStrata("DIALOG")
    configFrame:EnableMouse(true)
    configFrame:SetMovable(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)
    configFrame:SetScript("OnHide", function(self)
    end)

    if not tContains(UISpecialFrames, configFrame:GetName()) then
        tinsert(UISpecialFrames, configFrame:GetName())
    end

    configFrame.bg = configFrame:CreateTexture(nil, "BACKGROUND")
    configFrame.bg:SetAllPoints()
    configFrame.bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)

    configFrame.border = CreateFrame("Frame", nil, configFrame, "BackdropTemplate")
    configFrame.border:SetAllPoints()
    configFrame.border:SetBackdrop({
        edgeFile = "Interface\\AddOns\\MRT\\media\\border", 
        edgeSize = 2,
    })

    local closeButton = CreateFrame("Button", nil, configFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -5, -5)


    local sidebar = CreateFrame("Frame", nil, configFrame, "BackdropTemplate")
    sidebar:SetSize(200, 600)
    sidebar:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, -40)

    local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("CENTER", sidebar, "TOP", 0, 10)
    title:SetText("Advance Custom Tools")

    local content = CreateFrame("Frame", nil, configFrame)
    content:SetSize(560, 540)
    content:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 220, -40)
    configFrame.content = content

    local divider = configFrame:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.5, 0.5, 0.5, 0.7)
    divider:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 0, 40)
    divider:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMRIGHT", 0, 40)
    divider:SetWidth(1)

    local homeBtn = UI:CreateButton(sidebar, "Home", 180, 25)
    homeBtn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 10, -10)
    homeBtn:SetScript("OnClick", function()
        ACT:ShowFrontPage()
    end)

        for i, mod in ipairs(self.modules) do
        text = (mod.title or ("Module " .. i))
        local btn = UI:CreateButton(sidebar, text, 180, 25)
        btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 10, -10 - (i * 30))
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
    logo:SetSize(256, 256)
    logo:SetPoint("CENTER", front, "CENTER", 0, 160)
    logo:SetTexture("Interface\\AddOns\\ACT\\media\\logo.tga")
    logo:SetTexCoord(0.05, 0.95, 0.05, 0.95)

    local info = front:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    info:SetPoint("TOP", logo, "BOTTOM", 0, -10)
    info:SetPoint("CENTER", front, "CENTER", 0, -20)
    info:SetText("|cff00ccffAdvance Custom Tools|r\n\n|cffffcc00The #1 way to upset your raiders|r")

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
