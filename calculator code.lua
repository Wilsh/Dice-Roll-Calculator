local isActive = false
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

function onload()
    populateTables()
    --Track the results of each die rolled by a specific player
    function onObjectRandomize(obj, color)
        if not isActive then return end
        --Check object attributes to ensure only dice are evaluated
        local function isDie() return obj.tag == "Dice" end
        if(obj.getValue() == nil and isDie()) then return end
        --Ignore non-Dice objects and non-numerical dice
        if(not isDie() or tonumber(obj.getRotationValue()) == nil) then return end

        local id = obj.getGUID()
        --Prevent adding the same object to the isWatched table more than once
        --(A die can be randomized multiple times before coming to rest)
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
                if(tonumber(result) ~= nil) then
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
            Wait.condition(rollFinished, || obj.resting)
        end
    end
end

--Do stuff when the last die comes to rest
function endRoll(color, listSize)
    if(listSize == 0) then
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
    if(toggledOn == 'True') then
        isActive = true
        self.UI.setAttributes("status", {["text"]="Enabled", ["color"]="Green"})
        printToAll("Dice roll calculator enabled by " .. toggledBy.steam_name, {1,1,1})
    else
        isActive = false
        self.UI.setAttributes("status", {["text"]="Disabled", ["color"]="Red"})
        printToAll("Dice roll calculator disabled by " .. toggledBy.steam_name, {1,1,1})
    end
end
