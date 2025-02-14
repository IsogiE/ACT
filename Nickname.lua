local NicknameModule = {}

NicknameModule.title = "Nicknames"

function NicknameModule:GetConfigSize()
    return 800, 600 
end

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
    importLabel:SetPoint("TOPLEFT", configPanel, "TOPLEFT", 20, 16)
    importLabel:SetText("Nicknames")

    -- Create multiline edit box using UI helper
    local importBoxFrame, importBoxEdit = UI:CreateMultilineEditBox(configPanel, 520, 40)
    importBoxFrame:SetPoint("TOPLEFT", importLabel, "BOTTOMLEFT", 0, -10)
    self.importBoxFrame = importBoxFrame
    self.importBoxEdit = importBoxEdit

    local importButton = UI:CreateButton(configPanel, "Import", 120, 30)
    importButton:SetPoint("TOPLEFT", importBoxFrame, "BOTTOMLEFT", 0, -10)

    importButton:SetScript("OnClick", function()
        local text = self.importBoxEdit:GetText()
        if text and text ~= "" then
            self:ProcessImportString(text)
            self.importBoxEdit:SetText("")
            self:RefreshContent()
            self:PromptReload()
        end
    end)

    local integrationCheckbox = CreateFrame("CheckButton", nil, configPanel, "UICheckButtonTemplate")
    integrationCheckbox:SetPoint("LEFT", importButton, "RIGHT", 20, 0)
    integrationCheckbox:SetSize(22, 22) 

    integrationCheckbox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    integrationCheckbox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    integrationCheckbox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    integrationCheckbox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

    integrationCheckbox.Text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    integrationCheckbox.Text:SetText("Show nicknames on Party/Raid Frames & MRT Raid CDs")
    integrationCheckbox.Text:ClearAllPoints()
    integrationCheckbox.Text:SetPoint("LEFT", integrationCheckbox, "RIGHT", 5, 0)

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
    nicknameHeader:SetPoint("LEFT", headerFrame, "LEFT", 0, -10)
    nicknameHeader:SetText("Nickname")
    
    local charHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    charHeader:SetPoint("LEFT", headerFrame, "LEFT", 113, -10)
    charHeader:SetText("Character Names")
    
    local actionsHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    actionsHeader:SetPoint("LEFT", headerFrame, "LEFT", 350, -10)
    actionsHeader:SetText("Actions")

    local scrollFrame = CreateFrame("ScrollFrame", nil, configPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(520, 320)
    scrollFrame:SetPoint("TOPLEFT", headerFrame, "BOTTOMLEFT", 0, -10)
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(520, 320)
    scrollFrame:SetScrollChild(scrollChild)
    self.scrollChild = scrollChild

    local defaultButton = UI:CreateButton(configPanel, "Default Nicknames", 120, 30)
    defaultButton:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 0, -15)
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
        local row = CreateFrame("Frame", nil, self.scrollChild, "BackdropTemplate")
        row:SetSize(520, 30)
        row:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, yOffset)

        row:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1
        })
        row:SetBackdropColor(0.15, 0.15, 0.15, 1)
        row:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", row, "LEFT", 5, 0)
        label:SetSize(150, 30)
        label:SetJustifyH("LEFT")
        label:SetText(nickname)

        local dropdown = UI:CreateDropdown(row, 200, 30)
        dropdown:SetPoint("LEFT", row, "LEFT", 110, 0)
        
        local options = {}
        local list = NicknameModule:GetCharacterList(nickname)
        for _, v in pairs(list) do
            table.insert(options, {
                text = v,
                value = v,
                onClick = function()
                    dropdown.selectedValue = v
                    dropdown.button.text:SetText(v)
                end
            })
        end
        UI:SetDropdownOptions(dropdown, options)
        
        dropdown.button.text:SetText("Select Character")
        dropdown.selectedValue = nil

        local actionsFrame = CreateFrame("Frame", nil, row)
        actionsFrame:SetSize(170, 30)
        actionsFrame:SetPoint("LEFT", row, "LEFT", 330, 0)
        actionsFrame:SetPoint("CENTER", row, "CENTER", 0, 0)

        local addBtn = UI:CreateButton(actionsFrame, "Add", 50, 20)
        addBtn:SetPoint("LEFT", actionsFrame, "LEFT", 20, 0)

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

        local editBtn = UI:CreateButton(actionsFrame, "Edit", 50, 20)
        editBtn:SetPoint("LEFT", addBtn, "RIGHT", 5, 0)

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
                        NicknameModule:RefreshContent()
                        NicknameModule:PromptReload()
                    end
                end)
            end
        end)

        local deleteBtn = UI:CreateButton(actionsFrame, "Delete", 50, 20)
        deleteBtn:SetPoint("LEFT", editBtn, "RIGHT", 5, 0)

        deleteBtn:SetScript("OnClick", function()
            if dropdown.selectedValue then
                if ACT.db.profile.nicknames[nickname] and ACT.db.profile.nicknames[nickname].characters then
                    for i, charData in ipairs(ACT.db.profile.nicknames[nickname].characters) do
                        if charData.character == dropdown.selectedValue then
                            table.remove(ACT.db.profile.nicknames[nickname].characters, i)
                            break
                        end
                    end
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