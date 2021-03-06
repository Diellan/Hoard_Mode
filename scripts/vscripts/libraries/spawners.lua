if Spawner == nil then
  print ( '[Spawner] creating Spawner' )
  Spawner = {}
  Spawner.__index = Spawner

  bottomFriends = {}
  for i=1, 30 do
    bottomFriends[i] = nil
  end

  topFriends = {}
  for i=1, 30 do
    topFriends[i] = nil
  end

  midFriends = {}
  for i=1, 30 do
    midFriends[i] = nil
  end
end

require('libraries/timers')

function Spawner:new( o )
  o = o or {}
  setmetatable( o, Spawner )

  return o
end

function Spawner:Spawn(keys)
  local point = Entities:FindByName(nil, keys.source):GetAbsOrigin()
  local waypoint = Entities:FindByName(nil, keys.waypoint):GetAbsOrigin()
  local order = keys.order
  if order == nil then
    order = DOTA_UNIT_ORDER_ATTACK_MOVE
  end
  local max = keys.max
  local min = keys.min
  local difficulty = 0
  if keys.max == nil then
    max = 1
  end
  local units_to_spawn
  if min == nil then
    units_to_spawn = max
  else
    units_to_spawn = RandomInt(min, max)
  end

  if keys.difficulty ~= nil then
    difficulty = keys.difficulty
  end

  local playerCount = 2
  if keys.players ~= nil then
    playerCount = keys.players
  end

  for i=1,units_to_spawn do
    local unit = CreateUnitByName(keys.unit, point, true, nil, nil, DOTA_TEAM_BADGUYS)

    unit.Target = keys.waypoint

    if unit:IsConsideredHero() then
      if difficulty > 1 then
        unit:AddAbility("roshan_spell_block")
        local roshan_spell_block = unit:FindAbilityByName("roshan_spell_block")
        if roshan_spell_block ~= nil then
          roshan_spell_block:SetLevel(1)
        end
      end

      if playerCount > 2 then
        unit:SetMaxHealth(unit:GetMaxHealth() * 1.5)
      end
    end

    ExecuteOrderFromTable({	UnitIndex = unit:GetEntityIndex(),
      OrderType = order,
      Position = waypoint, Queue = true} )
  end
end

function Spawner:SpawnTimer(keys)
  local start = keys.start

  if start == nil then
    start = 0
  end

  local finish = keys.finish
  local interval = keys.interval

  local spawn = keys.spawn

  Timers:CreateTimer(start, function()
    if type(spawn) == "function" then
      spawn()
    else
      Spawner:Spawn(spawn)
    end
    local nextCall = interval
    if finish ~= nil and GameRules:GetGameTime() > finish then
        nextCall = nil
    end
    return nextCall
  end)
end

function Spawner:SpawnFriend(keys)
  local pointEntity = keys.point
  local waypointEntity = keys.waypoint
  local lane = keys.lane
  local unit = keys.unit
  local max_spawn = keys.max_spawn
  local meleeBarracksEntity = "good_rax_melee_mid"
  local rangedBarracksEntity = "good_rax_range_mid"
  local unitArray = midFriends

  if lane == "top" then
    meleeBarracksEntity = "good_rax_melee_top"
    rangedBarracksEntity = "good_rax_range_top"
    unitArray = topFriends
  elseif lane == "bot" then
    meleeBarracksEntity = "good_rax_melee_bot"
    rangedBarracksEntity = "good_rax_range_bot"
    unitArray = bottomFriends
  end

  local point = Entities:FindByName(nil, pointEntity):GetAbsOrigin()
  local waypoint = Entities:FindByName(nil, waypointEntity):GetAbsOrigin()
  local spawned_units = 0
  local extra_spawn = 0

  local melee_barracks = Entities:FindByName(nil, meleeBarracksEntity)
  if melee_barracks ~= nil then
    local building_stats = melee_barracks:FindAbilityByName("building_stats")
    if building_stats ~= nil then
      max_spawn = max_spawn + math.floor(building_stats:GetLevel() / 2)

      if building_stats:GetLevel() > 9 then
        extra_spawn = 2
      elseif building_stats:GetLevel() > 4 then
        extra_spawn = 1
      end
    end
  end

  local ranged_barracks = Entities:FindByName(nil, rangedBarracksEntity)
  local unit_level = 0
  if ranged_barracks ~= nil then
    local ranged_building_stats = ranged_barracks:FindAbilityByName("building_stats")
    if ranged_building_stats ~= nil then
      unit_level = ranged_building_stats:GetLevel()
    end
  end

  for j=1, max_spawn do
    if spawned_units > extra_spawn then
      break
    end
    if unitArray[j] ~= nil then
      if unitArray[j]:IsNull() == true then
        unitArray[j] = nil
      end
    end
    if unitArray[j] == nil then
      Timers:CreateTimer(function()
        unitArray[j] = CreateUnitByName(unit, point, true, nil, nil, DOTA_TEAM_GOODGUYS)
        -- for testing purposes
        -- bottomFriends[j]:SetMaxHealth(100)
        if unit_level > 0 then
          unitArray[j]:CreatureLevelUp(unit_level)
        end

        unitArray[j].targetWaypoint = waypointEntity

        ExecuteOrderFromTable({	UnitIndex = unitArray[j]:GetEntityIndex(),
          OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
          Position = waypoint, Queue = true} )
        DebugPrint("Move ",unitArray[j]:GetEntityIndex()," to ", waypoint)
        DebugPrint("Friendly ".. lane .. " creep spawned at index: " .. tostring(j))
      end)
      spawned_units = spawned_units + 1
    end
  end
end