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

Addon = AceAddon:NewAddon(Addon, AddonName, "AceEvent-3.0", "AceConsole-3.0");

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
      desc = "Macro Name.",
      get = "OptsGetter",
      set = "OptsSetter",
    },
    preferNightmareSeeds = {
      type = "toggle",
      order = 1.1,
      name = "Prefer Nightmare Seed",
      desc = "Prefer Nightmare Seed.",
      get = "OptsGetter",
      set = "OptsSetter",
    },
  },
};

function Addon:OnInitialize()
  self.db = AceDB:New(AddonName.."DB", self.defaults, true);

  self.conf = setmetatable({}, {
    __index = self.db.profile,
    __newindex = self.db.profile,
  });

  self.options.args.profiles = AceDBOptions:GetOptionsTable(self.db);

  AceConfig:RegisterOptionsTable(AddonName, self.options);
  AceConfigDialog:AddToBlizOptions(AddonName, AddonName);
end

function Addon:OnEnable()
  self:RegisterEvent("PLAYER_ENTERING_WORLD");
  self:RegisterEvent("BAG_NEW_ITEMS_UPDATED");
  self:RegisterEvent("UNIT_INVENTORY_CHANGED");

  self:RegisterChatCommand("autohealthstone", "OnChatCommand");
  self:RegisterChatCommand("ah", "OnChatCommand");
end

function Addon:OnDisable()
  self:UnregisterEvent("PLAYER_ENTERING_WORLD");
  self:UnregisterEvent("BAG_NEW_ITEMS_UPDATED");
  self:UnregisterEvent("UNIT_INVENTORY_CHANGED");

  self:UnregisterChatCommand("autohealthstone");
  self:UnregisterChatCommand("ah");
end

function Addon:OnChatCommand()
  Settings.OpenToCategory(AddonName);
end

function Addon:PLAYER_ENTERING_WORLD(event, isLogin, isReload)
  if isLogin or isReload then
    self:UpdateMacro(event);
  end
end

function Addon:UNIT_INVENTORY_CHANGED(event, unit)
  if unit == "player" then
    self:UpdateMacro(event);
  end
end

function Addon:BAG_NEW_ITEMS_UPDATED(event)
  self:UpdateMacro(event);
end

function Addon:UpdateMacro(event)
  if InCombatLockdown() then
    return;
  end

  local itemID = self:GetUsableItem();

  if not itemID then
    return;
  end

  self:Print(event)

  local macroName = self.conf.macroName;
  local macroText = format(macroTemplate, itemID);
  local name, _, body = GetMacroInfo(macroName);

  if not name then
    CreateMacro(macroName, 134400, macroText, false);
  elseif body ~= macroText then
    EditMacro(macroName, nil, nil, macroText);
  else
    self:Print("update skipped");
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

function Addon:OptsSetter(info, value)
  self.conf[info[#info]] = value;
end
