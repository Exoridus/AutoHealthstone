local AddonName, Addon = ...;
local AceAddon = LibStub("AceAddon-3.0");
local AceConfig = LibStub("AceConfig-3.0");
local AceConfigDialog = LibStub("AceConfigDialog-3.0");
local AceDB = LibStub("AceDB-3.0");
local healthstoneIDs = { 36894, 36893, 36892, 36891, 36890, 36889, 22105, 22104, 22103 };
local nightmareSeedID = 22797;
local macroTemplate = [[
#showtooltip
/use item:%d
]];

Addon = AceAddon:NewAddon(Addon, AddonName, "AceEvent-3.0");

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

  self.opts = setmetatable({}, {
    __index = self.db.profile,
    __newindex = self.db.profile,
  });

  AceConfig:RegisterOptionsTable(AddonName, self.options);
  AceConfigDialog:AddToBlizOptions(AddonName, AddonName, {"/autohealthstone", "/ah"});
end

function Addon:OnEnable()
  self:RegisterEvent("UNIT_INVENTORY_CHANGED");
end

function Addon:OnDisable()
  self:UnregisterEvent("UNIT_INVENTORY_CHANGED");
end

function Addon:UNIT_INVENTORY_CHANGED(_, unit)
  if InCombatLockdown() or unit ~= "player" then
    return;
  end

  local itemID = self:GetUsableItem();

  if itemID then
    local macroName = self.opts.macroName;
    local macroText = macroTemplate:format(itemID);
    local name, _, body = GetMacroInfo(macroName);

    if not name then
      CreateMacro(macroName, nil, macroText);
    elseif body ~= macroText then
      EditMacro(macroName, nil, nil, macroText);
    end
  end
end

function Addon:GetUsableItem()
  if self.opts.preferNightmareSeeds and GetItemCount(nightmareSeedID, false) > 0 then
    return nightmareSeedID;
  end

  for _,id in ipairs(healthstoneIDs) do
    if GetItemCount(id, false) == 1 then
      return id;
    end
  end
end

function Addon:OptsGetter(info)
  return self.opts[info[#info]];
end

function Addon:OptsSetter(info, value)
  self.opts[info[#info]] = value;
end
