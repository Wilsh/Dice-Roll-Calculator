local isActive = false
local uiID
local isWatched = {}
local trackDice = {}
local rollTotal = {}
local allPlayerColors = {"White", "Brown", "Red", "Orange", "Yellow", "Green",
        "Teal", "Blue", "Purple", "Pink", "Grey", "Black"}

function populateTables()
    for k,v in ipairs(allPlayerColors) do
        isWatched[v] = {}
        trackDice[v] = {}
        rollTotal[v] = 0
    end
end

function onSave()
    return JSON.encode({activated = isActive, ui = uiID})
end

function onload(scriptState)
    local state = JSON.decode(scriptState)
    if(state ~= nil and state.activated) then
        isActive = true
        uiID = state.ui
        self.UI.setAttributes("status", {["text"]="Enabled", ["color"]="Green"})
        self.UI.setAttributes(uiID, {["text"]="Click to disable", ["isOn"]=true})
    end
    populateTables()
end

--Track the results of each die rolled by a specific player
function onObjectRandomize(obj, color)
    if(not isActive or obj.getValue() == nil) then return end
    --Ignore non-Dice objects and non-numerical dice
    if(obj.tag ~= "Dice" or tonumber(obj.getRotationValue()) == nil) then return end
    --Prevent adding the same object to the isWatched table more than once
    --(A die can be randomized multiple times before coming to rest)
    local id = obj.getGUID()
    local exists = false
    for k, v in pairs(isWatched[color]) do
        if(v == id) then
            exists = true
            break
        end
    end
    if(not exists) then
        table.insert(isWatched[color], id)
        local function rollFinished()
            local result = obj.getRotationValue()
            if(tonumber(result) ~= nil and not obj.isDestroyed()) then
                table.insert(trackDice[color], {#obj.getRotationValues(), result})
                rollTotal[color] = rollTotal[color] + result
            end
            for k, v in pairs(isWatched[color]) do
                if(v == id) then
                    table.remove(isWatched[color], k)
                    break
                end
            end
            endRoll(color, #isWatched[color])
        end
        local function dieStopped()
            return obj.isDestroyed() or obj.resting
        end
        Wait.condition(rollFinished, dieStopped)
    end
end

--Do stuff when the last die comes to rest
function endRoll(color, listSize)
    if(listSize == 0 and #trackDice[color] > 0) then
        --Organize type of dice in tallyDice
        local tallyString, resultString = "", ""
        table.sort(trackDice[color], function(a,b) return a[1]>b[1] end) --Decreasing order
        local current, count = 0, 0
        for k, v in ipairs(trackDice[color]) do
            if(v[1] == current) then
                count = count + 1
            else
                if(current ~= 0) then
                    tallyString = tallyString .. count .. "d" .. current .. " + "
                end
                current = v[1]
                count = 1
            end
            resultString = resultString .. tostring(v[2]) .. " + "
        end
        tallyString = tallyString .. count .. "d" .. current
        resultString = string.sub(resultString, 1, string.len(resultString) - 3) --remove trailing " + "
        --Print roll results to chat
        local message = Player[color].steam_name .. " rolls " .. tallyString
        if #trackDice[color] == 1 then
            message = message .. " = " .. rollTotal[color]
        else
            message = message .. ": " .. resultString .. " = " .. rollTotal[color]
        end
        printToAll(message, color)
        rollTotal[color] = 0
        trackDice[color] = {}
    end
end

--Enable or disable object function
--Activated by toggle element
function toggled(toggledBy, toggledOn, id)
    uiID = id
    if(toggledOn == 'True') then
        isActive = true
        self.UI.setAttributes("status", {["text"]="Enabled", ["color"]="Green"})
        self.UI.setAttribute(uiID, "text", "Click to disable")
        printToAll("Dice roll calculator enabled by " .. toggledBy.steam_name, {1,1,1})
    else
        isActive = false
        self.UI.setAttributes("status", {["text"]="Disabled", ["color"]="Red"})
        self.UI.setAttribute(uiID, "text", "Click to enable")
        printToAll("Dice roll calculator disabled by " .. toggledBy.steam_name, {1,1,1})
    end
end
