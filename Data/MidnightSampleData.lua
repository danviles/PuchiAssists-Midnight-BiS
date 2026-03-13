local _, ns = ...

local instances = {
  dreamrift_raid = {
    id = "dreamrift_raid",
    name = "The Dreamrift",
    type = "raid",
    uiMapID = 2374,
    x = 0.5342,
    y = 0.3718,
    icon = "Interface\\Icons\\inv_10_raid_dream",
    bosses = {
      dreamwarden = {
        id = "dreamwarden",
        name = "Dreamwarden Solis",
        npcId = 239901,
        loot = {
          MAGE = {
            ALL = {
              { itemId = 239001, name = "Aetherglass Focus", slot = "TRINKET", difficulty = "HEROIC" },
              { itemId = 239002, name = "Veilwoven Mantle", slot = "SHOULDER", difficulty = "MYTHIC" },
            },
          },
          PALADIN = {
            ALL = {
              { itemId = 239011, name = "Solisguard Bulwark", slot = "SHIELD", difficulty = "HEROIC" },
            },
          },
        },
      },
      nyx_matron = {
        id = "nyx_matron",
        name = "Nyx Matron Velara",
        npcId = 239902,
        loot = {
          MAGE = {
            ALL = {
              { itemId = 239021, name = "Mantle of Midnight Threads", slot = "CHEST", difficulty = "MYTHIC" },
            },
          },
          HUNTER = {
            ALL = {
              { itemId = 239031, name = "Nightpiercer Bow", slot = "RANGED", difficulty = "HEROIC" },
            },
          },
        },
      },
    },
  },
  voidspire_dungeon = {
    id = "voidspire_dungeon",
    name = "The Voidspire",
    type = "dungeon",
    uiMapID = 2375,
    x = 0.4726,
    y = 0.6211,
    icon = "Interface\\Icons\\inv_10_dungeon_voidspire",
    bosses = {
      void_engine = {
        id = "void_engine",
        name = "The Void Engine",
        npcId = 239903,
        loot = {
          MAGE = {
            ALL = {
              { itemId = 239101, name = "Fractured Prism Ring", slot = "FINGER", difficulty = "MYTHIC" },
            },
          },
          ROGUE = {
            ALL = {
              { itemId = 239111, name = "Blackglass Shank", slot = "DAGGER", difficulty = "MYTHIC" },
            },
          },
        },
      },
      altaar_warden = {
        id = "altaar_warden",
        name = "Altaar Warden",
        npcId = 239904,
        loot = {
          PRIEST = {
            ALL = {
              { itemId = 239121, name = "Chalice of Silent Stars", slot = "TRINKET", difficulty = "MYTHIC" },
            },
          },
          WARRIOR = {
            ALL = {
              { itemId = 239131, name = "Greaves of Crushed Night", slot = "LEGS", difficulty = "MYTHIC" },
            },
          },
        },
      },
    },
  },
}

ns.BiSData:SetInstances(instances)
