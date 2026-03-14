local _, ns = ...

local instances = {
  windrunner_spire = {
    id = "windrunner_spire",
    name = "Windrunner Spire",
    type = "dungeon",
    uiMapID = 2805,
    displayMapID = 2393,
    x = 0.5200,
    y = 0.6200,
    bosses = {
      emberdawn = { id = "emberdawn", name = "Emberdawn", bossesOrder = 1, loot = {} },
      derelict_duo = { id = "derelict_duo", name = "Derelict Duo", bossesOrder = 2, loot = {} },
      commander_kroluk = { id = "commander_kroluk", name = "Commander Kroluk", bossesOrder = 3, loot = {} },
      restless_heart = { id = "restless_heart", name = "The Restless Heart", bossesOrder = 4, loot = {} },
      dungeon_drops = {
        id = "dungeon_drops",
        name = "Best Dungeon Drops",
        bossesOrder = 5,
        loot = {
          WARLOCK = {
            SPEC_266 = {
              { itemId = 251085, name = "Mantle of Dark Devotion", slot = "SHOULDER", difficulty = "M+", source = "Wowhead Demonology BiS - Midnight" },
              { itemId = 250144, name = "Emberwing Feather", slot = "TRINKET", difficulty = "M+", source = "Wowhead Demonology BiS - Midnight" },
            },
          },
        },
      },
    },
  },
  magisters_terrace = {
    id = "magisters_terrace",
    name = "Magister's Terrace",
    type = "dungeon",
    uiMapID = 2811,
    displayMapID = 2393,
    x = 0.5000,
    y = 0.6000,
    bosses = {
      arcanotron_custos = { id = "arcanotron_custos", name = "Arcanotron Custos", bossesOrder = 1, loot = {} },
      gemellus = { id = "gemellus", name = "Gemellus", bossesOrder = 2, loot = {} },
      seranel_sunlash = { id = "seranel_sunlash", name = "Seranel Sunlash", bossesOrder = 3, loot = {} },
      degentrius = { id = "degentrius", name = "Degentrius", bossesOrder = 4, loot = {} },
    },
  },
  algethar_academy = {
    id = "algethar_academy",
    name = "Algeth'ar Academy",
    type = "dungeon",
    uiMapID = 2025,
    displayMapID = 2393,
    x = 0.4180,
    y = 0.5790,
    bosses = {
      vexamus = { id = "vexamus", name = "Vexamus", bossesOrder = 1, loot = {} },
      overgrown_ancient = { id = "overgrown_ancient", name = "Overgrown Ancient", bossesOrder = 2, loot = {} },
      crawth = { id = "crawth", name = "Crawth", bossesOrder = 3, loot = {} },
      echo_of_doragosa = {
        id = "echo_of_doragosa",
        name = "Echo of Doragosa",
        bossesOrder = 4,
        loot = {
          WARLOCK = {
            SPEC_266 = {
              { itemId = 193707, name = "Final Grade", slot = "WEAPON", difficulty = "M+", source = "Wowhead Demonology BiS - Midnight" },
            },
          },
        },
      },
    },
  },
  pit_of_saron = {
    id = "pit_of_saron",
    name = "Pit of Saron",
    type = "dungeon",
    uiMapID = 118,
    displayMapID = 2393,
    x = 0.4300,
    y = 0.5870,
    bosses = {
      forgemaster_garfrost = {
        id = "forgemaster_garfrost",
        name = "Forgemaster Garfrost",
        bossesOrder = 1,
        loot = {
          WARLOCK = {
            SPEC_266 = {
              { itemId = 50228, name = "Barbed Ymirheim Choker", slot = "NECK", difficulty = "M+", source = "Wowhead Demonology BiS - Midnight" },
            },
          },
        },
      },
      ick_and_krick = { id = "ick_and_krick", name = "Ick and Krick", bossesOrder = 2, loot = {} },
      scourgelord_tyrannus = { id = "scourgelord_tyrannus", name = "Scourgelord Tyrannus", bossesOrder = 3, loot = {} },
    },
  },
  murder_row = {
    id = "murder_row",
    name = "Murder Row",
    type = "dungeon",
    uiMapID = 2813,
    displayMapID = 2393,
    x = 0.5400,
    y = 0.6000,
    bosses = {
      kystia_manaheart = { id = "kystia_manaheart", name = "Kystia Manaheart", bossesOrder = 1, loot = {} },
      zaen_bladesorrow = { id = "zaen_bladesorrow", name = "Zaen Bladesorrow", bossesOrder = 2, loot = {} },
      xathuux_annihilator = { id = "xathuux_annihilator", name = "Xathuux the Annihilator", bossesOrder = 3, loot = {} },
      lithiel_cinderfury = { id = "lithiel_cinderfury", name = "Lithiel Cinderfury", bossesOrder = 4, loot = {} },
    },
  },
  the_blinding_vale = {
    id = "the_blinding_vale",
    name = "The Blinding Vale",
    type = "dungeon",
    uiMapID = 2859,
    displayMapID = 2393,
    x = 0.5600,
    y = 0.6200,
    bosses = {
      lightblossom_trinity = { id = "lightblossom_trinity", name = "Lightblossom Trinity", bossesOrder = 1, loot = {} },
      ikuzz_light_hunter = { id = "ikuzz_light_hunter", name = "Ikuzz the Light Hunter", bossesOrder = 2, loot = {} },
      lightwarden_ruia = { id = "lightwarden_ruia", name = "Lightwarden Ruia", bossesOrder = 3, loot = {} },
      ziekket = { id = "ziekket", name = "Ziekket", bossesOrder = 4, loot = {} },
    },
  },
  den_of_nalorakk = {
    id = "den_of_nalorakk",
    name = "Den of Nalorakk",
    type = "dungeon",
    uiMapID = 2825,
    displayMapID = 2393,
    x = 0.5200,
    y = 0.5800,
    bosses = {
      hoardmonger = { id = "hoardmonger", name = "The Hoardmonger", bossesOrder = 1, loot = {} },
      sentinel_of_winter = { id = "sentinel_of_winter", name = "Sentinel of Winter", bossesOrder = 2, loot = {} },
      nalorakk = { id = "nalorakk", name = "Nalorakk", bossesOrder = 3, loot = {} },
    },
  },
  maisara_caverns = {
    id = "maisara_caverns",
    name = "Maisara Caverns",
    type = "dungeon",
    uiMapID = 2874,
    displayMapID = 2393,
    x = 0.5800,
    y = 0.6200,
    bosses = {
      murojin_nekraxx = { id = "murojin_nekraxx", name = "Murojin and Nekraxx", bossesOrder = 1, loot = {} },
      vordaza = { id = "vordaza", name = "Vordaza", bossesOrder = 2, loot = {} },
      raktul = { id = "raktul", name = "Raktul", bossesOrder = 3, loot = {} },
    },
  },
  nexus_point_xenas = {
    id = "nexus_point_xenas",
    name = "Nexus Point Xenas",
    type = "dungeon",
    uiMapID = 2915,
    displayMapID = 2393,
    x = 0.6000,
    y = 0.6000,
    bosses = {
      kasreth = { id = "kasreth", name = "Chief Corewright Kasreth", bossesOrder = 1, loot = {} },
      nysarra = { id = "nysarra", name = "Corewarden Nysarra", bossesOrder = 2, loot = {} },
      lothraxion = { id = "lothraxion", name = "Lothraxion", bossesOrder = 3, loot = {} },
    },
  },
  voidscar_arena = {
    id = "voidscar_arena",
    name = "Voidscar Arena",
    type = "dungeon",
    uiMapID = 2923,
    displayMapID = 2393,
    x = 0.6200,
    y = 0.6200,
    bosses = {
      taz_rah = { id = "taz_rah", name = "Taz Rah", bossesOrder = 1, loot = {} },
      atroxus = { id = "atroxus", name = "Atroxus", bossesOrder = 2, loot = {} },
      charonus = { id = "charonus", name = "Charonus", bossesOrder = 3, loot = {} },
    },
  },
}

ns.BiSData:SetInstances(instances)
