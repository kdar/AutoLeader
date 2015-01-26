AutoLeader = LibStub("AceAddon-3.0"):NewAddon("Auto Leader", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0")

local options = {
  name = "AutoLeader",
  handler = AutoLeader,
  type = 'group',
  args = {
    enable = {
      type = 'toggle',
      order = 1,
      name = 'Enabled',
      width = 'double',
      desc = 'Enable or disable this addon.',
      get = function(info) return AutoLeader.db.profile.enabled end,
      set = function(info, val) if (val) then AutoLeader:Enable() else AutoLeader:Disable() end end,
    }
  }
}

local defaults = {
  profile = {
    enabled = true
  }
}

function AutoLeader:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("AutoLeaderDB", defaults)
  local parent = LibStub("AceConfig-3.0"):RegisterOptionsTable("AutoLeader", options, {"AutoLeader", "al"})
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions("AutoLeader", "AutoLeader")
  profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
  LibStub("AceConfig-3.0"):RegisterOptionsTable("AutoLeader.profiles", profiles)
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions("AutoLeader.profiles", "Profiles", "AutoLeader")

  UnitPopupButtons["AUTO_LEADER"] = { text = "Auto Leader", dist = 0, checkable = true }
  table.insert(UnitPopupMenus["PARTY"], #UnitPopupMenus["FRIEND"]-1, "AUTO_LEADER")
  table.insert(UnitPopupMenus["RAID_PLAYER"], #UnitPopupMenus["FRIEND"]-1, "AUTO_LEADER")
  self:SecureHook("ToggleDropDownMenu", self.ToggleDropDownMenuHook)

  self.leader = nil

  -- self:SecureHook("UnitPopup_ShowMenu", self.UnitPopup_ShowMenu)
end

function AutoLeader:OnEnable()
  self:RegisterEvent("GROUP_ROSTER_UPDATE")
  self:ScheduleRepeatingTimer(self.PassLead, 10)
  self.db.profile.enabled = true
end

function AutoLeader:OnDisable()
  self:UnregisterEvent("GROUP_ROSTER_UPDATE")
  self:CancelTimer(self.timer)
  self.db.profile.enabled = false
end

function AutoLeader:PassLead()
  local instanceType = select(2, IsInInstance())
  if instanceType ~= "arena" then
    return
  end

  found = false
  for i = 0, MAX_RAID_MEMBERS do
    name = select(1, GetRaidRosterInfo(i))
    if AutoLeader.leader == name then
      found = true
      break
    end
  end

  if found and AutoLeader.leader ~= nil and not UnitIsGroupLeader(AutoLeader.leader) and UnitIsGroupLeader("player") then
    AutoLeader:Print("Gave leader to", AutoLeader.leader)
    PromoteToLeader(AutoLeader.leader)
  end
end

function AutoLeader:GROUP_ROSTER_UPDATE()
  local instanceType = select(2, IsInInstance())
  if instanceType ~= "none" then
    return
  end

  found = false
  for i = 0, MAX_RAID_MEMBERS do
    name = select(1, GetRaidRosterInfo(i))
    -- if there is a server in the name, just get the person's name
    if name ~= nil and string.find(name, "-") then
      name = string.gmatch(name, "%a+")()
    end
    if self.leader == name then
      found = true
      break
    end
  end

  if not found then
    self.leader = nil
  end
end

-- function AutoLeader:UnitPopup_ShowMenu(dropdownMenu, which, unit, name, userData)
--   local info = UIDropDownMenu_CreateInfo()
--   info.text, info.checked = "Blue Pill", true
--   UIDropDownMenu_AddButton(info)
-- end

function AutoLeader:ToggleDropDownMenuHook(level, value, dropDownFrame, anchorName, xOffset, yOffset, menuList, button, autoHideDelay)
  -- Make sure we have what we need to continue
  if dropDownFrame then
    if level == nil then
      level = 1
    end
    local listFrame = _G["DropDownList"..level];
    local index = listFrame and (listFrame.numButtons + 1) or 1;
    local listFrameName = listFrame:GetName();
    local buttonPrefix = "DropDownList" .. level .. "Button";
    -- Start at 2 because 1 is always going to be the title (i.e. player name) in our case
    local i = 2;
    while (1) do
      -- Get the button at index i in the dropdown
      local button = _G[buttonPrefix..i];
      if (not button) then break end;
      -- If the button is our button...
      if (button:GetText() == UnitPopupButtons["AUTO_LEADER"].text) then
        player = _G[buttonPrefix.."1"]:GetText()
        if player == AutoLeader.leader then
          button:LockHighlight();
          _G[buttonPrefix..i.."Check"]:Show();
          _G[buttonPrefix..i.."UnCheck"]:Hide();
        else
          button:UnlockHighlight();
          _G[buttonPrefix..i.."UnCheck"]:Show();
          _G[buttonPrefix..i.."Check"]:Hide();
        end

        button.func = function()          
          if AutoLeader.leader == nil or AutoLeader.leader ~= player then
            --AutoLeader:Print("Enabled for:", player)
            AutoLeader.leader = player            
          elseif AutoLeader.leader == player then
            --AutoLeader:Print("Disabled for:", AutoLeader.leader)
            AutoLeader.leader = nil            
          end
        end
        break;
      end
      i = i + 1;
    end
  end
end
