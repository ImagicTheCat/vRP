
local cfg = {}
-- define garage types with their associated vehicles
-- (vehicle list: https://wiki.fivem.net/wiki/Vehicles)

cfg.rent_factor = 0.1 -- 10% of the original price if a rent
cfg.sell_factor = 0.75 -- sell for 75% of the original price

cfg.force_out_fee = 1000 -- amount of money (fee) to force re-spawn an already out vehicle

-- default chest weight for vehicle trunks
cfg.default_vehicle_chest_weight = 50

cfg.vehicle_update_interval = 15 -- seconds
cfg.vehicle_check_interval = 15 -- seconds, re-own/respawn task
cfg.vehicle_respawn_radius = 150 -- radius for the out vehicle respawn feature

-- define vehicle chest weight by model in lower case
cfg.vehicle_chest_weights = {
  ["benson"] = 120,
  ["trailersmall"] = 100,
  ["trailers"] = 500,
  ["tanker"] = 5000
}

-- each garage type is a map of veh_name => {title, price, description}
-- _config: map_entity, permissions (optional, only users with the permissions will have access to the shop)
--- map_entity: {ent,cfg} will fill cfg.title, cfg.pos
cfg.garage_types = {
  ["compacts"]  = {
    _config = {map_entity = {"PoI", {blip_id = 50, blip_color = 4, marker_id = 1}}},
    ["blista"] = {"Blista", 15000, ""},
    ["brioso"] = {"Brioso R/A", 155000, ""},
    ["dilettante"] = {"Dilettante", 25000, ""},
    ["issi2"] = {"Issi", 18000, ""},
    ["panto"] = {"Panto", 85000, ""},
    ["prairie"] = {"Prairie", 30000, ""},
    ["rhapsody"] = {"Rhapsody", 120000, ""}
  },

  ["coupe"] = {
    _config = {map_entity = {"PoI", {blip_id = 50, blip_color = 4, marker_id = 1}}},
    ["cogcabrio"] = {"Cognoscenti Cabrio",180000, ""},
    ["exemplar"] = {"Exemplar", 200000, ""},
    ["F620"] = {"F620", 80000, ""},
    ["felon"] = {"Felon", 90000, ""},
    ["felon2"] = {"Felon GT", 95000, ""},
    ["jackal"] = {"Jackal", 60000, ""},
    ["oracle"] = {"Oracle", 80000, ""},
    ["oracle2"] = {"Oracle XS",82000, ""},
    ["sentinel"] = {"sentinel", 90000, ""},
    ["sentinel2"] = {"Sentinel XS", 60000, ""},
    ["windsor"] = {"Windsor",800000, ""},
    ["windsor2"] = {"Windsor Drop",850000, ""},
    ["zion"] = {"Zion", 60000, ""},
    ["zion2"] = {"Zion Cabrio", 65000, ""}
  },

  ["sports"] = {
    _config = {map_entity = {"PoI", {blip_id = 50, blip_color = 4, marker_id = 1}}},
    ["ninef"] = {"9F",120000, ""},
    ["ninef2"] = {"9F Cabrio",130000, ""},
    ["alpha"] = {"Alpha",150000, ""},
    ["banshee"] = {"Banshee",105000, ""},
    ["bestiagts"] = {"Bestia GTS",610000, ""},
    ["blista"] = {"Blista Compact",42000, ""},
    ["buffalo"] = {"Buffalo",35000, ""},
    ["buffalo2"] = {"Buffalo S",96000, ""},
    ["carbonizzare"] = {"Carbonizzare",195000, ""},
    ["comet2"] = {"Comet",100000, ""},
    ["coquette"] = {"Coquette",138000, ""},
    ["tampa2"] = {"Drift Tampa",995000, ""},
    ["feltzer2"] = {"Feltzer",130000, ""},
    ["furoregt"] = {"Furore GT",448000, ""},
    ["fusilade"] = {"Fusilade",36000, ""},
    ["jester"] = {"Jester",240000, ""},
    ["jester2"] = {"Jester (Racecar)",350000, ""},
    ["kuruma"] = {"Kuruma",95000, ""},
    ["lynx"] = {"Lynx",1735000, ""},
    ["massacro"] = {"Massacro",275000, ""},
    ["massacro2"] = {"Massacro (Racecar)",385000, ""},
    ["omnis"] = {"Omnis",701000, ""},
    ["penumbra"] = {"Penumbra",24000, ""},
    ["rapidgt"] = {"Rapid GT",140000, ""},
    ["rapidgt2"] = {"Rapid GT Convertible",150000, ""},
    ["schafter3"] = {"Schafter V12",140000, ""},
    ["sultan"] = {"Sultan",12000, ""},
    ["surano"] = {"Surano",110000, ""},
    ["tropos"] = {"Tropos",816000, ""},
    ["verlierer2"] = {"Verkierer",695000,""}
  },

  ["sportsclassics"] = {
    _config = {map_entity = {"PoI", {blip_id = 50, blip_color = 5, marker_id = 1}}},
    ["casco"] = {"Casco",680000, ""},
    ["coquette2"] = {"Coquette Classic",665000, ""},
    ["jb700"] = {"JB 700",350000, ""},
    ["pigalle"] = {"Pigalle",400000, ""},
    ["stinger"] = {"Stinger",850000, ""},
    ["stingergt"] = {"Stinger GT",875000, ""},
    ["feltzer3"] = {"Stirling",975000, ""},
    ["ztype"] = {"Z-Type",950000,""}
  },

  ["supercars"] = {
    _config = {map_entity = {"PoI", {blip_id = 50, blip_color = 5, marker_id = 1}}},
    ["adder"] = {"Adder",1000000, ""},
    ["banshee2"] = {"Banshee 900R",565000, ""},
    ["bullet"] = {"Bullet",155000, ""},
    ["cheetah"] = {"Cheetah",650000, ""},
    ["entityxf"] = {"Entity XF",795000, ""},
    ["sheava"] = {"ETR1",199500, "4 - (less numner better car"},
    ["fmj"] = {"FMJ",1750000, "10 - (less numner better car"},
    ["infernus"] = {"Infernus",440000, ""},
    ["osiris"] = {"Osiris",1950000, "8 - (less numner better car"},
    ["le7b"] = {"RE-7B",5075000, "1 - (less numner better car"},
    ["reaper"] = {"Reaper",1595000, ""},
    ["sultanrs"] = {"Sultan RS",795000, ""},
    ["t20"] = {"T20",2200000,"7 - (less numner better car"},
    ["turismor"] = {"Turismo R",500000, "9 - (less numner better car"},
    ["tyrus"] = {"Tyrus",2550000, "5 - (less numner better car"},
    ["vacca"] = {"Vacca",240000, ""},
    ["voltic"] = {"Voltic",150000, ""},
    ["prototipo"] = {"X80 Proto",2700000, "6 - (less numner better car"},
    ["zentorno"] = {"Zentorno",725000,"3 - (less numner better car"}
  },

  ["musclecars"] = {
    _config = {map_entity = {"PoI", {blip_id = 50, blip_color = 4, marker_id = 1}}},
    ["blade"] = {"Blade",160000, ""},
    ["buccaneer"] = {"Buccaneer",29000, ""},
    ["Chino"] = {"Chino",225000, ""},
    ["coquette3"] = {"Coquette BlackFin",695000, ""},
    ["dominator"] = {"Dominator",35000, ""},
    ["dukes"] = {"Dukes",62000, ""},
    ["gauntlet"] = {"Gauntlet",32000, ""},
    ["hotknife"] = {"Hotknife",90000, ""},
    ["faction"] = {"Faction",36000, ""},
    ["nightshade"] = {"Nightshade",585000, ""},
    ["picador"] = {"Picador",9000, ""},
    ["sabregt"] = {"Sabre Turbo",15000, ""},
    ["tampa"] = {"Tampa",375000, ""},
    ["virgo"] = {"Virgo",195000, ""},
    ["vigero"] = {"Vigero",21000, ""}
  },

  ["off-road"] = {
    _config = {map_entity = {"PoI", {blip_id = 50, blip_color = 4, marker_id = 1}}},
    ["bifta"] = {"Bifta",75000, ""},
    ["blazer"] = {"Blazer",8000, ""},
    ["brawler"] = {"Brawler",715000, ""},
    ["dubsta3"] = {"Bubsta 6x6",249000, ""},
    ["dune"] = {"Dune Buggy",20000, ""},
    ["rebel2"] = {"Rebel",22000, ""},
    ["sandking"] = {"Sandking",38000, ""},
    ["monster"] = {"The Liberator",550000, ""},
    ["trophytruck"] = {"The Liberator",550000, ""}
  },

  ["suvs"]  = {
    _config = {map_entity = {"PoI", {blip_id = 50, blip_color = 4, marker_id = 1}}},
    ["baller"] = {"Baller",90000, ""},
    ["cavalcade"] = {"Cavalcade",60000, ""},
    ["granger"] = {"Grabger",35000, ""},
    ["huntley"] = {"Huntley",195000, ""},
    ["landstalker"] = {"Landstalker",58000, ""},
    ["radi"] = {"Radius",32000, ""},
    ["rocoto"] = {"Rocoto",85000, ""},
    ["seminole"] = {"Seminole",30000, ""},
    ["xls"] = {"XLS",253000, ""}
  },

  ["vans"] = {
    _config = {map_entity = {"PoI", {blip_id = 50, blip_color = 4, marker_id = 1}}},
    ["bison"] = {"Bison",30000, ""},
    ["bobcatxl"] = {"Bobcat XL",23000, ""},
    ["gburrito"] = {"Gang Burrito",65000, ""},
    ["journey"] = {"Journey",15000, ""},
    ["minivan"] = {"Minivan",30000, ""},
    ["paradise"] = {"Paradise",25000, ""},
    ["rumpo"] = {"Rumpo",13000, ""},
    ["surfer"] = {"Surfer",11000, ""},
    ["youga"] = {"Youga",16000, ""}
  },

  ["sedans"] = {
    _config = {map_entity = {"PoI", {blip_id = 50, blip_color = 4, marker_id = 1}}},
    ["asea"] = {"Asea",1000000, ""},
    ["asterope"] = {"Asterope",1000000, ""},
    ["cognoscenti"] = {"Cognoscenti",1000000, ""},
    ["cognoscenti2"] = {"Cognoscenti(Armored)",1000000, ""},
    ["cognoscenti3"] = {"Cognoscenti 55",1000000, ""},
    ["zentorno"] = {"Cognoscenti 55(Armored)",1500000, ""},
    ["fugitive"] = {"Fugitive",24000, ""},
    ["glendale"] = {"Glendale",200000, ""},
    ["ingot"] = {"Ingot",9000, ""},
    ["intruder"] = {"Intruder",16000, ""},
    ["premier"] = {"Premier",10000, ""},
    ["primo"] = {"Primo",9000, ""},
    ["primo2"] = {"Primo Custom",9500, ""},
    ["regina"] = {"Regina",8000, ""},
    ["schafter2"] = {"Schafter",65000, ""},
    ["stanier"] = {"Stanier",10000, ""},
    ["stratum"] = {"Stratum",10000, ""},
    ["stretch"] = {"Stretch",30000, ""},
    ["superd"] = {"Super Diamond",250000, ""},
    ["surge"] = {"Surge",38000, ""},
    ["tailgater"] = {"Tailgater",55000, ""},
    ["warrener"] = {"Warrener",120000, ""},
    ["washington"] = {"Washington",15000, ""}
  },

  ["motorcycles"] = {
    _config = {map_entity = {"PoI", {blip_id = 50, blip_color = 4, marker_id = 1}}},
    ["AKUMA"] = {"Akuma",9000, ""},
    ["bagger"] = {"Bagger",5000, ""},
    ["bati"] = {"Bati 801",15000, ""},
    ["bati2"] = {"Bati 801RR",15000, ""},
    ["bf400"] = {"BF400",95000, ""},
    ["carbonrs"] = {"Carbon RS",40000, ""},
    ["cliffhanger"] = {"Cliffhanger",225000, ""},
    ["daemon"] = {"Daemon",5000, ""},
    ["double"] = {"Double T",12000, ""},
    ["enduro"] = {"Enduro",48000, ""},
    ["faggio2"] = {"Faggio",4000, ""},
    ["gargoyle"] = {"Gargoyle",120000, ""},
    ["hakuchou"] = {"Hakuchou",82000, ""},
    ["hexer"] = {"Hexer",15000, ""},
    ["innovation"] = {"Innovation",90000, ""},
    ["lectro"] = {"Lectro",700000, ""},
    ["nemesis"] = {"Nemesis",12000, ""},
    ["pcj"] = {"PCJ-600",9000, ""},
    ["ruffian"] = {"Ruffian",9000, ""},
    ["sanchez"] = {"Sanchez",7000, ""},
    ["sovereign"] = {"Sovereign",90000, ""},
    ["thrust"] = {"Thrust",75000, ""},
    ["vader"] = {"Vader",9000, ""},
    ["vindicator"] = {"Vindicator",600000,""}
  },
  ["taxi"] = {
    _config = {map_entity = {"PoI", {blip_id = 56, blip_color = 5, marker_id = 1}}, permissions = {"taxi.vehicle"} },
    ["taxi"] = {"Taxi",100,""}
  },
  ["police"] = {
    _config = {map_entity = {"PoI", {blip_id = 50, blip_color = 38, marker_id = 1}}, permissions = {"police.vehicle"} },
    ["police"] = {"Basic",100,"Basic model."},
    ["police3"] = {"Classic",25000,"Sport model."},
    ["police2"] = {"Furtive",50000,"Furtive model."}
  },
  ["emergency"] = {
    _config = {map_entity = {"PoI", {blip_id = 61, blip_color = 3, marker_id = 1}}, permissions = {"emergency.vehicle"} },
    ["ambulance"] = {"Basic",100,""}
  },
  ["bicycles"] = {
    _config = {map_entity = {"PoI", {blip_id = 376, blip_color = 4, marker_id = 1}}},
    ["tribike"] = {"Tribike", 250, ""},
    ["BMX"] = {"BMX", 450, ""}
  },
  ["boats"] = {
    _config = {map_entity = {"PoI", {blip_id = 427, blip_color = 4, marker_id = 1}}},
    ["dinghy"] = {"Dinghy", 50000, "A zodiac."},
    ["dinghy2"] = {"Dinghy II", 50000, "A zodiac."},
    ["dinghy3"] = {"Dinghy III", 50000, "A zodiac."},
    ["dinghy4"] = {"Dinghy IV", 50000, "A zodiac."},
    ["marquis"] = {"Marquis", 250000, "A yacht."},
    ["seashark"] = {"Seashark", 9000, "A jet ski."},
    ["seashark2"] = {"Seashark II", 9000, "A jet ski."},
    ["seashark3"] = {"Seashark III", 9000, "A jet ski."},
    ["speeder"] = {"Speeder", 600000, "A fast boat."},
    ["speeder2"] = {"Speeder II", 600000, "A fast boat."},
    ["squalo"] = {"Squalo", 600000, "A fast boat."},
    ["jetmax"] = {"JetMax", 600000, "A fast boat."},
    ["toro"] = {"Toro", 600000, "A fast boat."},
    ["toro2"] = {"Toro II", 600000, "A fast boat."},
    ["tropic"] = {"Tropic", 600000, "A fast boat."},
    ["tropic2"] = {"Tropic II", 600000, "A fast boat."},
    ["predator"] = {"Predator", 600000, "A fast boat."},
    ["suntrap"] = {"Suntrap", 250000, "Pleasure boat."}
  },
  ["planes"] = {
    _config = {map_entity = {"PoI", {blip_id = 307, blip_color = 4, marker_id = 1}}},
    ["velum"] = {"Velum", 500000, "Propeller plane."},
    ["velum2"] = {"Velum II", 500000, "Propeller plane."},
    ["stunt"] = {"Stunt", 250000, "Small propeller plane."},
    ["mammatus"] = {"Mammatus", 250000, "Small propeller plane."},
    ["dodo"] = {"Dodo", 250000, "Small propeller plane."},
    ["duster"] = {"Duster", 105000, "Old propeller plane."},
    ["cuban800"] = {"Cuban 800", 250000, "Small propeller plane."},
    ["luxor"] = {"Luxor", 3500000, "Private jet."},
    ["luxor2"] = {"Luxor II", 3500000, "Private jet."}
  },
  ["helicopters"] = {
    _config = {map_entity = {"PoI", {blip_id = 43, blip_color = 4, marker_id = 1}}},
    ["maverick"] = {"Maverick", 150000, "Basic chopper."},
    ["swift"] = {"Swift", 550000, "Fast chopper."},
    ["swift2"] = {"Swift II", 550000, "Fast chopper."},
    ["supervolito"] = {"Super Volito", 850000, "Fast chopper."},
    ["supervolito2"] = {"Super Volito II", 850000, "Fast chopper."},
    ["volatus"] = {"Volatus", 3500000, "Top of the line chopper."}
  },
  ["transport"] = {
    _config = {map_entity = {"PoI", {blip_id = 318, blip_color = 4, marker_id = 1}}},
    ["packer"] = {"Packer", 15000, "Basic tug."},
    ["benson"] = {"Benson", 8000, "Basic truck."},
    ["bison"] = {"Bison", 12000, "Basic pickup truck."}
  },
  ["containers"] = {
    _config = {map_entity = {"PoI", {blip_id = 318, blip_color = 17, marker_id = 1}}},
    ["trailersmall"] = {"Petit", 3000, "Small container for pickup."},
    ["trailers"] = {"Basic", 30000, "Medium container."},
    ["tanker"] = {"Tanker", 300000, "Big container."}
  }
}

-- {garage_type,x,y,z,radius(optional),height(optional)}
cfg.garages = {
  {"compacts",-356.146, -134.69, 39.0097},
  {"coupe",723.013, -1088.92, 22.1829},
  {"sports",-1145.67, -1991.17, 13.162},
  {"sportsclassics",1174.76, 2645.46, 37.7545},
  {"supercars",112.275, 6619.83, 31.8154},
  {"motorcycles",-205.789, -1308.02, 31.2916},
  {"taxi",-286.870056152344,-917.948181152344,31.080623626709},
  {"police",454.4,-1017.6,28.4},
  {"emergency",-492.08544921875,-336.749206542969,34.3731842041016},
  {"bicycles",-352.038482666016,-109.240043640137,38.6970825195313},
  {"boats",-849.501281738281,-1367.69567871094,1.60516905784607},
  {"boats",1299.11730957031,4215.66162109375,33.9086799621582},
  {"boats",3867.17578125,4464.54248046875,2.72485375404358},
  {"planes",1640.0, 3236.0, 40.4},
  {"planes",2123.0, 4805.0, 41.19},
  {"planes",-1348.0, -2230.0, 13.9},
  {"helicopters",1750.0, 3260.0, 41.37},
  {"helicopters",-1233.0, -2269.0, 13.9},
  {"helicopters",-745.0, -1468.0, 5.0},
  {"containers",-978.674682617188,-2994.29028320313,13.945068359375},
  {"transport",-962.553039550781,-2965.82470703125,13.9450702667236}
}

return cfg
