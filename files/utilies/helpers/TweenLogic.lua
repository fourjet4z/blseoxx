-- SX_VM_CNONE();





local Utility = loadstring(game:HttpGet("https://raw.githubusercontent.com/fourjet4z/foundation/refs/heads/main/files/utilies/Utility.lua"))();
local Services = loadstring(game:HttpGet("https://raw.githubusercontent.com/fourjet4z/foundation/refs/heads/main/files/utilies/Services.lua"))();
local Methods = loadstring(game:HttpGet("https://raw.githubusercontent.com/fourjet4z/foundation/refs/heads/main/files/utilies/Methods.lua"))();
local Slave = loadstring(game:HttpGet("https://raw.githubusercontent.com/fourjet4z/foundation/refs/heads/main/files/utilies/Slave.lua"))();
local Helpers = {
    basics = loadstring(game:HttpGet("https://raw.githubusercontent.com/fourjet4z/foundation/refs/heads/main/files/utilies/helpers/basics.lua"))();
};



local TweenService = Services:Get("TweenService");


local Tween = {}

local IsA, IsAncestorOf = Methods:Get("game.IsA", "game.IsAncestorOf");

local bigSlave = Slave.SichNew()


local model, rootPart, hum = nil, nil, nil

local tween = nil

local function getTweenLerpSteppPos(startPos, endPos, totalT, elapsedT)
    local percentComplete = math.min(elapsedT / totalT, 1)
    return startPos:Lerp(endPos, percentComplete)
end

local function isHasRequiredInstances()
    return model and rootPart and hum
    and model.Parent and rootPart.Parent and hum.Parent
    and IsAncestorOf(game, model) and IsAncestorOf(game, rootPart) and IsAncestorOf(game, hum)
    and IsA(model, "Model") and IsA(rootPart, "BasePart") and IsA(hum, "Humanoid")
end

function Tween:getRunningTween()
    return tween
end

--override/multi function callable
local lastStartAdvanceTweenTick, nextStateStartAtTick, nextState = nil, nil, nil
function Tween:tweenTeleport(m, rp, hu, goalCFrame, options)
    model = m
    rootPart = rp
    hum = hu
    if (not isHasRequiredInstances()) then
        Tween.destroyTweens()
        return;
    end;

    if bigSlave.tween then
        bigSlave.tween = nil
        nextState = nextState
    else
        nextState = 1
    end

    goalCFrame = typeof(goalCFrame) == "Vector3" and CFrame.new(goalCFrame) or CFrame.new(goalCFrame.Position)

    --default options
    local defaults = {
        tweenSpeed = 100,
        tweenSpeedIgnoreY = false,
        instant = false,
        offset = CFrame.identity * rootPart.CFrame.Rotation, --(offset while twennin)/(default:) LocalPlayer HumanoidRootPart Rotation
        advance = { --advanced tween logic with high customization
            value = false, --true: normal tween / false: advanced tween logic
            states = {
                tween = {
                    waitTimeBeforeNextState = 0, --after time since actived start next state
                },
                pause = { --pause tween
                    value = false,
                    waitTimeBeforeNextState = 1, --_________________________________________
                },
                jumpSkip = { --skip a frame/distance, (immediately)/(set rootPart) to more 50 to goalCFrame
                    value = false,
                    waitTimeBeforeNextState = 0, --_________________________________________
                    distance = 50, --value distance to skip
                }
            },
            skipTweenToEnd = {
                value = false,
                activeAfterStartTweenTime = 0.75, --active stop tween and (immediately)/(set rootPart) to goalCFrame after time since tween started
                distance = 30, --distance (goalCFrame <-> rootPart) goalCFrame condition to active
            },
            tweenDefaultToEnd = {
                value = false,
                distance = 75, --distance (goalCFrame <-> rootPart) condition to active normal tween
            }
        }
    }

    --input options override on defaults options if ~= value
    --return new table with combined options
    options = Utility:mergeTables(defaults, options or {}, true)

    goalCFrame =  goalCFrame * options.offset

    if (options.instant) then
        options.tweenSpeed = 5000;
    end;

    Helpers.basics.noPhysics(rootPart, options); -- rootPart.CFrame = CFrame.new(rootPart.CFrame.Position) * options.offset.Rotation; --included in noPhysics function
    Helpers.basics.setClip(model, false, nil);

    local function getTweenTimeLeft()
        local distance = (rootPart.Position - goalCFrame.Position).Magnitude;
        if (options.tweenSpeedIgnoreY) then
            distance = Utility:roundVector(rootPart.Position - goalCFrame.Position).Magnitude;
        end;
        return distance / options.tweenSpeed
    end

    local function tweenPlay()
        local tweenInfo = TweenInfo.new(getTweenTimeLeft(), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut);
        tween = TweenService:Create(rootPart, tweenInfo, {CFrame = goalCFrame});
        if not options.advance.value then
            tween.Completed:Connect(function(playbackState)
                if playbackState == Enum.PlaybackState.Cancelled then return; end;
                tween = nil
            end)
        end
        tween:Play()
    end

    local function tweenPause()
        if tween then tween:Pause() end
    end

    local function tweenCancel()
        if tween then tween:Cancel() end
    end

    local function getStates()
        local statesLocal = {}

        table.insert(statesLocal, {
            status = "tweening",
            waitTime = options.advance.states.tween.waitTimeBeforeNextState,
            func = function()
                tweenPlay()
            end
        })

        if options.advance.states.pause.value then
            table.insert(statesLocal, {
                status = "pausing",
                waitTime = options.advance.states.pause.waitTimeBeforeNextState,
                func = function()
                    tweenPause()
                end
            })
        end

        if options.advance.states.jumpSkip.value then
            table.insert(statesLocal, {
                status = "jumpSkipping",
                waitTime = options.advance.states.jumpSkip.waitTimeBeforeNextState,
                func = function()
                    if not options.advance.states.pause.value then
                        tweenPause() --muss pause before change/set rootPart CFrame
                    end
                    rootPart.CFrame = CFrame.new(
                        getTweenLerpSteppPos(
                            rootPart.Position,
                            goalCFrame.Position,
                            getTweenTimeLeft(),
                            options.advance.states.jumpSkip.distance / options.tweenSpeed
                        )
                    ) * options.offset
                end
            })
        end

        return statesLocal
    end

    local states = getStates()

    if options.followCamera then Utility.lookAt(goalCFrame) end

    local done = false
    if options.advance.value then
        if options.advance.skipTweenToEnd.activeAfterStartTweenTime then
            if lastStartAdvanceTweenTick and lastStartAdvanceTweenTick <= options.advance.skipTweenToEnd.activeAfterStartTweenTime + tick() then
                lastStartAdvanceTweenTick = lastStartAdvanceTweenTick
            else
                lastStartAdvanceTweenTick = tick()
            end
        else
            lastStartAdvanceTweenTick = tick()
        end
        bigSlave.tween = task.spawn(function()
            local tweenDefault = false
            while task.wait() do
                if (not isHasRequiredInstances()) then
                    tweenCancel()
                    tween = nil
                    bigSlave.tween = nil
                    return;
                end;

                if (options.advance.skipTweenToEnd.value
                and Utility.isBetweenAt(rootPart.Position, goalCFrame.Position, options.advance.skipTweenToEnd.distance)
                and tick() >= lastStartAdvanceTweenTick + options.advance.skipTweenToEnd.activeAfterStartTweenTime
                or rootPart.CFrame == goalCFrame) then
                    tweenCancel()
                    rootPart.CFrame = goalCFrame
                    tween = nil
                    done = true
                    bigSlave.tween = nil
                    return
                elseif (options.advance.tweenDefaultToEnd.value
                and Utility.isBetweenAt(rootPart.Position, goalCFrame.Position, options.advance.tweenDefaultToEnd.distance)) then
                    if not tweenDefault then
                        tweenDefault = true
                        tweenPlay()
                        nextState = 1
                    end
                else
                    if tweenDefault then
                        tweenDefault = false
                        nextState = 0
                        nextStateStartAtTick = 0 --instant active state tween logic after done wait time
                        task.wait(5) --after got reback form anticheat wait for a sec before tween again
                    end
                end

                if not tweenDefault then
                    if tick() >= (nextStateStartAtTick or 0) then
                        if nextState then
                            states[nextState].func()
                            nextStateStartAtTick = tick() + states[nextState].waitTime
                            nextState = (nextState % #states) + 1
                        else
                            nextState = 1
                        end
                    end
                end
            end
        end)
    else
        tweenPlay()
    end
    repeat task.wait() until tween or done
    return tween
end;

function Tween.destroyTweens()
    if bigSlave.tween then
        bigSlave.tween = nil
    end
    if tween then
        tween:Cancel()
    end
    tween = nil
end;

function Tween.turnOffAutoFarm()
    Tween.destroyTweens();
    Helpers.basics.destroyNoPhysics(rootPart);
end;

--island list oder logic
---return steps islands to islands
---exam: b to whire_pool, output/return:
---{b prev
---a nil
---whire_pool next
---underwater_city nil --(if goCentralAfterDoor is false, or normal)
---}
---#1 arg: island name, #2 arg: action
---prev: previous island
---next: next island
---normal: central island
---nil: do nothing
function Tween.getPath(list, current, target, goCentralAfterDoor, visited, visited_local)
    visited = visited or {}
    visited_local = visited_local or {}
    if current == target then
        visited[current] = true
        return { { name = target, action = (goCentralAfterDoor or visited_local[current] or not next(visited_local)) and "normal" or nil} } --to center or do nothing
    end

    local current_info = list[current]
    if not current_info or not current_info.order or visited_local[current] then
        return nil
    end

    visited_local[current] = true

    for prev_name, _ in pairs(current_info.order.prev or {}) do
        local path = Tween.getPath(list, prev_name, target, goCentralAfterDoor, visited, visited_local)
        if path then
            visited[current] = true
            table.insert(path, 1, { name = current, action = "prev" })
            return path
        end
    end

    for next_name, _ in pairs(current_info.order.next or {}) do
        local path = Tween.getPath(list, next_name, target, goCentralAfterDoor, visited, visited_local)
        if path then
            visited[current] = true
            table.insert(path, 1, { name = current, action = "next" })
            return path
        end
    end

    if not next(current_info.order.prev or {}) then
        visited[current] = true
        local candidates = {}

        for island_name, island_info in pairs(list) do
            if island_info.layer == current_info.layer
            and not next(island_info.order.prev or {})
            and not visited[island_name] then
                visited[island_name] = true
                table.insert(candidates, island_name)
            end
        end

        local shortest_path = nil
        for _, candidate in pairs(candidates) do
            local path = Tween.getPath(list, candidate, target, goCentralAfterDoor, visited, {})
            if path then
                if not shortest_path or #path < #shortest_path then
                    shortest_path = path
                end
            end
        end

        if shortest_path then
            table.insert(shortest_path, 1, { name = current })
            return shortest_path
        end
    end

    return nil
end

function Tween.getClosestIsland(list, inputCFrame)
    local islandClosestName, islandClosestDis = nil, math.huge
    for islandNameIndex, islandInfo in pairs(list) do
        if islandInfo.centralCFrame then
            local _, dis = Utility.isBetweenAt(inputCFrame.Position, islandInfo.centralCFrame.Position)
            if islandClosestDis >= dis then
                islandClosestName = islandNameIndex
                islandClosestDis = dis
            end
        end
    end
    return islandClosestName, islandClosestDis
end

--override/multi function callable
function Tween:travel(m, rp, hu, list, target, options, goCentralAfterDoor)
    local actions = {
        ["normal"] = {
            func = function(island_name)
                local island_info = list[island_name]
                if not island_info.centralCFrame then
                    warn(island_name.." is missing value: centralCFrame")
                    return
                end
                Tween:tweenTeleport(m, rp, hu, island_info.centralCFrame, options)
                return island_info.centralCFrame
            end,
            description = "to island"
        },
        ["prev"] = {
            func = function(island_name, path, i)
                local island_info = list[island_name]
                local island_next_step = path[i + 1]
                if island_next_step then
                    local data = island_info.order.previous[island_next_step.name]
                    if data and data.positionEnter then
                        Tween:tweenTeleport(m, rp, hu, data.positionEnter, options)
                        return data.positionEnter
                    else
                        warn(island_name.." is missing value: positionEnter for "..island_next_step.name)
                    end
                end
            end,
            description = "outdoor island"
        },
        ["next"] = {
            func = function(island_name, path, i)
                local island_info = list[island_name]
                local island_next_step = path[i + 1]
                if island_next_step then
                    local data = island_info.order.next[island_next_step.name]
                    if data and data.positionEnter then
                        Tween:tweenTeleport(m, rp, hu, data.positionEnter, options)
                        return data.positionEnter
                    else
                        warn(island_name.." is missing value: positionEnter for "..island_next_step.name)
                    end
                end
            end,
            description = "nextdoor island"
        },
    }

    model = m
    rootPart = rp
    hum = hu
    if (not isHasRequiredInstances) then
        Tween:stopTravel()
        return;
    end;

    if bigSlave.travel then
        bigSlave.travel = nil
    end

    local path = Tween.getPath(list, Tween.getClosestIsland(list, rootPart.CFrame), target, goCentralAfterDoor)
    if not path then
        warn("path invalid")
        return
    end

    bigSlave.travel = task.spawn(function()
        for i, data in ipairs(path) do
            local action = actions[data.action]

            if action then
                local point = action.func(data.name, path, i)
                repeat task.wait()
                until not tween

				local savedTick = 0
				if data.action ~= "normal" then
					repeat task.wait()
						if tick() - savedTick > math.random(75, 150)/100 then
							hum:ChangeState(Enum.HumanoidStateType.Jumping)
							savedTick = tick()
						end
					until not isHasRequiredInstances() or not Utility.isBetweenAt(rootPart.Position, point.Position, Utility.getSmallestSize(rootPart))
				end

                if not isHasRequiredInstances() then
                    Tween.destroyTweens()
                    bigSlave.travel = nil
                    return
                end

                local current_1 = Tween.getClosestIsland(list, rootPart.CFrame)
				local current_expection = path[i + 1] or path[i] --path[i] for data.action == "normal" which should be always at end of table
                if current_1 ~= current_expection.name then
                    task.wait(1)
                    print("failed, retrying")
                    self:travel(m, rp, hu, list, target, options, goCentralAfterDoor)
                    return
				else
					print("successed")
                end
            end
        end
        bigSlave.travel = nil
    end)
end

function Tween:stopTravel()
    if bigSlave.travel then
        bigSlave.travel = nil
    end
    Tween.destroyTweens()
    Helpers.basics.destroyNoPhysics(rootPart);
end

return Tween;

--use:

--function Utility:getPlrCharc(plr)
--    plr = self:getPlr(plr)
--    if plr and plr.Character then
--        return plr.Character
--    end
--end

--list of islands
---rules:
---prev island is a mandatory condition to out of island until no prev island of whole prev islands connections then do next step
---=>always go prev island first if has
---islands has same layer value are connectable if not have prev island
---islands has next island are connectable, one way form island that have next island
--local Island_List_1 = {
--    ["underwater_city"] = {
--        centralCFrame = CFrame.new(61376.13671875, 143.50997924804688, 1415.7958984375),
--        order = {
--            prev = {
--                ["whire_pool"] = {}
--            },
--            next = {}
--        },
--    },
--    ["whire_pool"] = {
--        layer = 0,
--        centralCFrame = CFrame.new(3870.6845703125, -4.296045303344727, -1984.84814453125),
--        order = {
--            prev = {},
--            next = {
--                ["underwater_city"] = {
--                    positionEnter = CFrame.new(4050.310546875, -1.6884479522705078, -1814.1236572265625),
--                },
--            }
--        },
--   },
--
--    ["a"] = {
--        layer = 0,
--        centralCFrame = (...),
--        order = {
--            prev = {},
--            next = {}
--        },
--    },
--    ["b"] = {
--        layer = 0,
--        centralCFrame = (...),
--        order = {
--           prev = {
--                ["a"] = {}
--            },
--            next = {}
--        },
--    },
--}

--local plrLcalCharc = Utility:getPlrCharc(plrLcal)
--local plrLcalRootPart = plrLcalCharc["HumanoidRootPart"]
--local plrLcalHum = plrLcalCharc["Humanoid"]

--Tween:tweenTeleport(plrLcalCharc, plrLcalRootPart, plrLcalHum, CFrame.new(-1285, 8, 584), {})
--print("start tween1")
--task.wait(3)
---override/multi function callable
--Tween:tweenTeleport(plrLcalCharc, plrLcalRootPart, plrLcalHum, CFrame.new(-1285, 8, 584), {})
--print("start tween2")

--Tween:travel(plrLcalCharc, plrLcalRootPart, plrLcalHum, Island_List_1, "underwater_city", {}, true)
--print("start travel")
--task.wait(3)
---override/multi function callable
--Tween:travel(plrLcalCharc, plrLcalRootPart, plrLcalHum, Island_List_1, "underwater_city", {}, true)
--print("start travel2")