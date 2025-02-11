local NicknameModule = {}

NicknameModule.title = "Player Nicknames"

function NicknameModule:CreateConfigPanel(parent)
    if self.configPanel then
        self.configPanel:SetParent(parent)
        self.configPanel:ClearAllPoints()
        self.configPanel:SetAllPoints(parent)
        self.configPanel:Show()
        return self.configPanel
    end

    local configPanel = CreateFrame("Frame", nil, parent)
    configPanel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    configPanel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

    local importLabel = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    importLabel:SetPoint("TOPLEFT", configPanel, "TOPLEFT", 20, -20)
    importLabel:SetText("Import Nicknames")

    local importBox = CreateFrame("EditBox", nil, configPanel, "InputBoxTemplate")
    importBox:SetMultiLine(true)
    importBox:SetSize(520, 60) 
    importBox:SetPoint("TOPLEFT", importLabel, "BOTTOMLEFT", 0, -10)
    importBox:SetAutoFocus(false)
    self.importBox = importBox

    local importButton = CreateFrame("Button", nil, configPanel, "UIPanelButtonTemplate")
    importButton:SetSize(120, 30)
    importButton:SetPoint("TOPLEFT", importBox, "BOTTOMLEFT", 0, -10)
    importButton:SetText("Import")
    importButton:SetScript("OnClick", function()
        local text = importBox:GetText()
        if text and text ~= "" then
            self:ProcessImportString(text)
            importBox:SetText("")
            self:RefreshContent()
            self:PromptReload()
        end
    end)

    local integrationCheckbox = CreateFrame("CheckButton", nil, configPanel, "UICheckButtonTemplate")
    integrationCheckbox:SetPoint("LEFT", importButton, "RIGHT", 20, 0)
    integrationCheckbox.text:SetText("Use Nickname Integration for Party/Raid Frames")
    integrationCheckbox:SetChecked(ACT.db.profile.useNicknameIntegration)
    integrationCheckbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        ACT.db.profile.useNicknameIntegration = checked
        NicknameModule:RefreshContent()
        NicknameModule:PromptReload()
    end)

    local headerFrame = CreateFrame("Frame", nil, configPanel)
    headerFrame:SetSize(520, 20)
    headerFrame:SetPoint("TOPLEFT", importButton, "BOTTOMLEFT", 0, -30)
    
    local nicknameHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nicknameHeader:SetPoint("LEFT", headerFrame, "LEFT", 0, 0)
    nicknameHeader:SetText("Nickname")
    
    local charHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    charHeader:SetPoint("LEFT", headerFrame, "LEFT", 130, 0)
    charHeader:SetText("Character Names")
    
    local actionsHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    actionsHeader:SetPoint("LEFT", headerFrame, "LEFT", 350, 0)
    actionsHeader:SetText("Actions")

    local scrollFrame = CreateFrame("ScrollFrame", nil, configPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(520, 320) 
    scrollFrame:SetPoint("TOPLEFT", headerFrame, "BOTTOMLEFT", 0, -10)
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(520, 320)
    scrollFrame:SetScrollChild(scrollChild)
    self.scrollChild = scrollChild

    local defaultButton = CreateFrame("Button", nil, configPanel, "UIPanelButtonTemplate")
    defaultButton:SetSize(150, 30)
    defaultButton:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 0, -15)
    defaultButton:SetText("Default Nicknames")
    defaultButton:SetScript("OnClick", function()
        StaticPopupDialogs["ACT_CONFIRM_WIPE_DEFAULT"] = {
            text = "Are you sure you want to reset to the default nicknames?\n\nThis will remove all your current nicknames.",
            button1 = "Confirm",
            button2 = "Cancel",
            OnAccept = function()
                wipe(ACT.db.profile.nicknames)
                local importString = table.concat(DefaultNicknames, "")
                NicknameModule:ProcessImportString(importString)
                NicknameModule:RefreshContent()
                ReloadUI()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("ACT_CONFIRM_WIPE_DEFAULT")
    end)

    self.configPanel = configPanel

    self:RefreshContent()

    return configPanel
end

function NicknameModule:RefreshContent()
    if not self.scrollChild then return end

    for _, child in ipairs({ self.scrollChild:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local nicknamesMap = ACT.db.profile.nicknames
    local sortedNicknames = {}
    for nickname in pairs(nicknamesMap) do
        table.insert(sortedNicknames, nickname)
    end
    table.sort(sortedNicknames)

    local yOffset = -10
    for _, nickname in ipairs(sortedNicknames) do
        local data = nicknamesMap[nickname]
        local row = CreateFrame("Frame", nil, self.scrollChild)
        row:SetSize(520, 30)
        row:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, yOffset)

        local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", row, "LEFT", 0, 0)
        label:SetSize(100, 30)
        label:SetJustifyH("LEFT")
        label:SetText(nickname)

        local dropdown = CreateFrame("Frame", nil, row, "UIDropDownMenuTemplate")
        dropdown:SetPoint("LEFT", row, "LEFT", 110, 0)
        dropdown:SetSize(200, 30)
        UIDropDownMenu_SetWidth(dropdown, 200)
        UIDropDownMenu_SetText(dropdown, "Select Character")
        dropdown.selectedValue = nil

        local function Dropdown_OnClick(self)
            UIDropDownMenu_SetSelectedID(dropdown, self:GetID())
            dropdown.selectedValue = self.value
            UIDropDownMenu_SetText(dropdown, self.value)
        end

        local function Initialize_DropDown(self, level)
            local info = UIDropDownMenu_CreateInfo()
            local list = NicknameModule:GetCharacterList(nickname)
            for _, v in pairs(list) do
                info = UIDropDownMenu_CreateInfo()
                info.text = v
                info.value = v
                info.func = Dropdown_OnClick
                UIDropDownMenu_AddButton(info, level)
            end
        end
        UIDropDownMenu_Initialize(dropdown, Initialize_DropDown)

        local actionsFrame = CreateFrame("Frame", nil, row)
        actionsFrame:SetSize(170, 30)
        actionsFrame:SetPoint("LEFT", row, "LEFT", 330, 0)
        actionsFrame:SetPoint("CENTER", row, "CENTER", 0, 0)

        local addBtn = CreateFrame("Button", nil, actionsFrame, "UIPanelButtonTemplate")
        addBtn:SetSize(50, 20)
        addBtn:SetPoint("LEFT", actionsFrame, "LEFT", 20, 3)
        addBtn:SetText("Add")
        addBtn:SetScript("OnClick", function()
            NicknameModule:ShowCharacterInputPopup(nickname, nil, function(characterName)
                if not ACT.db.profile.nicknames[nickname] then
                    ACT.db.profile.nicknames[nickname] = { characters = {} }
                end
                table.insert(ACT.db.profile.nicknames[nickname].characters, { character = characterName })
                NicknameModule:RefreshContent()
                NicknameModule:PromptReload()
            end)
        end)

        local editBtn = CreateFrame("Button", nil, actionsFrame, "UIPanelButtonTemplate")
        editBtn:SetSize(50, 20)
        editBtn:SetPoint("LEFT", addBtn, "RIGHT", 5, 0)
        editBtn:SetText("Edit")
        editBtn:SetScript("OnClick", function()
            if dropdown.selectedValue then
                NicknameModule:ShowCharacterInputPopup(nickname, dropdown.selectedValue, function(newName)
                    if ACT.db.profile.nicknames[nickname] and ACT.db.profile.nicknames[nickname].characters then
                        for i, charData in ipairs(ACT.db.profile.nicknames[nickname].characters) do
                            if charData.character == dropdown.selectedValue then
                                ACT.db.profile.nicknames[nickname].characters[i].character = newName
                                break
                            end
                        end
                        dropdown.selectedValue = newName
                        UIDropDownMenu_SetText(dropdown, newName)
                        NicknameModule:RefreshContent()
                        NicknameModule:PromptReload()
                    end
                end)
            end
        end)

        local deleteBtn = CreateFrame("Button", nil, actionsFrame, "UIPanelButtonTemplate")
        deleteBtn:SetSize(60, 20)
        deleteBtn:SetPoint("LEFT", editBtn, "RIGHT", 5, 0)
        deleteBtn:SetText("Delete")
        deleteBtn:SetScript("OnClick", function()
            if dropdown.selectedValue then
                if ACT.db.profile.nicknames[nickname] and ACT.db.profile.nicknames[nickname].characters then
                    for i, charData in ipairs(ACT.db.profile.nicknames[nickname].characters) do
                        if charData.character == dropdown.selectedValue then
                            table.remove(ACT.db.profile.nicknames[nickname].characters, i)
                            break
                        end
                    end
                    UIDropDownMenu_SetText(dropdown, "Select Character")
                    dropdown.selectedValue = nil
                    NicknameModule:RefreshContent()
                    NicknameModule:PromptReload()
                end
            end
        end)

        yOffset = yOffset - 40
    end
end

function NicknameModule:ProcessImportString(importString)
    local nicknamesMap = ACT.db.profile.nicknames
    local normalizedMap = {}

    for nickname, data in pairs(nicknamesMap) do
        local normalizedNick = nickname:lower()
        if not normalizedMap[normalizedNick] then
            normalizedMap[normalizedNick] = {
                originalCase = nickname,
                characters = data.characters or {}
            }
        else
            for _, char in ipairs(data.characters or {}) do
                local exists = false
                for _, existing in ipairs(normalizedMap[normalizedNick].characters) do
                    if existing.character:lower() == char.character:lower() then
                        exists = true
                        break
                    end
                end
                if not exists then
                    table.insert(normalizedMap[normalizedNick].characters, char)
                end
            end
        end
    end

    for entry in string.gmatch(importString, "[^;]+") do
        entry = strtrim(entry)
        if entry ~= "" then
            local nickname, characters = strsplit(":", entry)
            if nickname and characters then
                nickname = strtrim(nickname)
                local normalizedNick = nickname:lower()
                normalizedMap[normalizedNick] = normalizedMap[normalizedNick] or { originalCase = nickname, characters = {} }
                for charName in string.gmatch(characters, "[^,]+") do
                    charName = strtrim(charName)
                    if charName ~= "" then
                        local exists = false
                        for _, existing in ipairs(normalizedMap[normalizedNick].characters) do
                            if existing.character:lower() == charName:lower() then
                                exists = true
                                break
                            end
                        end
                        if not exists then
                            table.insert(normalizedMap[normalizedNick].characters, { character = charName })
                        end
                    end
                end
            end
        end
    end

    wipe(nicknamesMap)
    for _, data in pairs(normalizedMap) do
        nicknamesMap[data.originalCase] = { characters = data.characters }
    end
end

function NicknameModule:PromptReload()
    if not StaticPopupDialogs["ACT_RELOAD_UI"] then
        StaticPopupDialogs["ACT_RELOAD_UI"] = {
            text = "Please reload your UI to apply the changes.",
            button1 = "Reload Now",
            button2 = "Later",
            OnAccept = function() ReloadUI() end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
    end
    StaticPopup_Show("ACT_RELOAD_UI")
end

function NicknameModule:GetCharacterList(nickname)
    local list = {}
    local nickData = ACT.db.profile.nicknames[nickname]
    if nickData and nickData.characters then
        for _, charData in ipairs(nickData.characters) do
            list[charData.character] = charData.character
        end
    end
    if not next(list) then
        list["Select Character"] = "Select Character"
    end
    return list
end

function NicknameModule:ShowCharacterInputPopup(nickname, existingCharacter, callback)
    self.editPopupData = {
        nickname = nickname,
        existingCharacter = existingCharacter,
        callback = callback,
    }
    if not StaticPopupDialogs["ACT_EDIT_CHARACTER"] then
        StaticPopupDialogs["ACT_EDIT_CHARACTER"] = {
            text = (existingCharacter and "Edit Character" or "Add New Character") .. "\nPlease input character name:",
            button1 = existingCharacter and "Save" or "Add",
            button2 = "Cancel",
            hasEditBox = true,
            maxLetters = 50,
            OnShow = function(popup)
                if NicknameModule.editPopupData and NicknameModule.editPopupData.existingCharacter then
                    popup.editBox:SetText(NicknameModule.editPopupData.existingCharacter)
                else
                    popup.editBox:SetText("")
                end
            end,
            OnAccept = function(popup)
                local text = popup.editBox:GetText()
                if text and text ~= "" then
                    if NicknameModule.editPopupData and NicknameModule.editPopupData.callback then
                        NicknameModule.editPopupData.callback(text)
                    end
                end
                NicknameModule.editPopupData = nil
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
    end
    StaticPopup_Show("ACT_EDIT_CHARACTER")
end

if ACT and ACT.RegisterModule then
    ACT:RegisterModule(NicknameModule)
end