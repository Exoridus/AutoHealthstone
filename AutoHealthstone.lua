local AddonName, Addon = ...;
local AceAddon = LibStub("AceAddon-3.0");
local AceConfig = LibStub("AceConfig-3.0");
local AceConfigDialog = LibStub("AceConfigDialog-3.0");
local AceDB = LibStub("AceDB-3.0");
local AceDBOptions = LibStub("AceDBOptions-3.0");
local healthstoneIDs = { 36894, 36893, 36892, 36891, 36890, 36889, 22105, 22104, 22103 };
local nightmareSeedID = 22797;
local macroTemplate = [[
#showtooltip
/use item:%d
]];

Addon = AceAddon:NewAddon(Addon, AddonName, "AceEvent-3.0", "AceConsole-3.0", "LibAboutPanel-2.0");

Addon.defaults = {
  profile = {
    macroName = "AutoHealthstone",
    preferNightmareSeeds = false,
  },
};

Addon.options = {
  type = 'group',
  name = AddonName,
  handler = Addon,
  args = {
    macroName = {
      order = 1.0,
      type = "input",
      name = "Macro Name",
      get = "OptsGetter",
      set = function(_, value)
        local prevName = Addon.conf.macroName;

        Addon.conf.macroName = strsub(strtrim(value or ""), 1, 16);

        if Addon.conf.macroName ~= prevName and GetMacroInfo(prevName) then
          DeleteMacro(prevName);
        end

        Addon:UpdateMacro();
      end,
    },
    preferNightmareSeeds = {
      type = "toggle",
      order = 1.1,
      name = "Prefer Nightmare Seeds",
      get = "OptsGetter",
      set = function(_, value)
        Addon.conf.preferNightmareSeeds = value;
        Addon:UpdateMacro();
      end
    },
  },
};

function Addon:OnInitialize()
  self.db = AceDB:New(AddonName.."DB", self.defaults, true);

  self.conf = setmetatable({}, {
    __index = self.db.profile,
    __newindex = self.db.profile,
  });

  AceConfig:RegisterOptionsTable(AddonName, self.options);
  self.optionsFrame = AceConfigDialog:AddToBlizOptions(AddonName, AddonName);

  AceConfig:RegisterOptionsTable(AddonName.."_Profiles", AceDBOptions:GetOptionsTable(self.db));
  AceConfigDialog:AddToBlizOptions(AddonName.."_Profiles", "Profiles", AddonName);

  AceConfig:RegisterOptionsTable(AddonName.."_About", self:AboutOptionsTable(AddonName));
  AceConfigDialog:AddToBlizOptions(AddonName.."_About", "About", AddonName);
end

function Addon:OnEnable()
  self:RegisterEvent("PLAYER_ENTERING_WORLD");
  self:RegisterEvent("BAG_UPDATE_DELAYED");

  self:RegisterChatCommand("autohealthstone", "OnChatCommand");
  self:RegisterChatCommand("ah", "OnChatCommand");
end

function Addon:OnDisable()
  self:UnregisterEvent("PLAYER_ENTERING_WORLD");
  self:UnregisterEvent("BAG_UPDATE_DELAYED");

  self:UnregisterChatCommand("autohealthstone");
  self:UnregisterChatCommand("ah");
end

function Addon:OnChatCommand()
  Settings.OpenToCategory(AddonName);
end

function Addon:PLAYER_ENTERING_WORLD(_, isLogin, isReload)
  if isLogin or isReload then
    self:UpdateMacro();
  end
end

function Addon:BAG_UPDATE_DELAYED()
  self:UpdateMacro();
end

function Addon:UpdateMacro()
  if InCombatLockdown() then
    return;
  end

  local itemID = self:GetUsableItem();

  if not itemID then
    return;
  end

  local macroName = self.conf.macroName;
  local macroText = format(macroTemplate, itemID);
  local name, _, body = GetMacroInfo(macroName);

  if not name then
    CreateMacro(macroName, 134400, macroText, false);
  elseif body ~= macroText then
    EditMacro(macroName, nil, nil, macroText);
  end
end

function Addon:GetUsableItem()
  if self.conf.preferNightmareSeeds and GetItemCount(nightmareSeedID, false) > 0 then
    return nightmareSeedID;
  end

  for _,id in ipairs(healthstoneIDs) do
    if GetItemCount(id, false) == 1 then
      return id;
    end
  end
end

function Addon:OptsGetter(info)
  return self.conf[info[#info]];
end
