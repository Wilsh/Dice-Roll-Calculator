local isActive = false
local player
local isWatched, trackDice = {}, {}
local rollTotal = 0
local modifierId, rollModifier = ''

function onload()
    --Track the results of each die rolled by a specific player
    function onObjectRandomize(obj, color)
        if(not isActive or player.color ~= color) then return end
        --Check object attributes to ensure only dice are evaluated
        local function isDie() return obj.tag == "Dice" end
        if(obj.getValue() == nil and isDie()) then
            print("WARNING: attempting to roll an improperly created die. " ..
                    "Cannot evaluate its result. Name: " .. obj.getName())
            return
        end
        --Ignore non-Dice objects and non-numerical dice
        if(not isDie() or tonumber(obj.getRotationValue()) == nil) then return end

        local id = obj.getGUID()
        --Prevent adding the same object to the isWatched table more than once
        --(A die can be randomized multiple times before coming to rest)
        local exists = false
        for k, v in pairs(isWatched) do
            if(v == id) then
                exists = true
                break
            end
        end
        if(not exists) then
            table.insert(isWatched, id)
            --Function that will be watched until it becomes true
            local function rollWatch() return obj.resting end
            --Function that will be run once the above condition becomes true
            local function rollFinished()
                local result = obj.getRotationValue()
                if(tonumber(result) ~= nil) then
                    table.insert(trackDice, #obj.getRotationValues())
                    rollTotal = rollTotal + result
                end
                for k, v in pairs(isWatched) do
                    if(v == id) then
                        table.remove(isWatched, k)
                        break
                    end
                end
                endRoll()
            end
            --Plug those two functions into the Wait function
            Wait.condition(rollFinished, rollWatch)
        end
    end
end

--Do stuff when the last die comes to rest
function endRoll()
    if(#isWatched == 0) then
        --Organize type of dice in tallyDice
        local tallyString, resultString = "", ""
        table.sort(trackDice, function(a,b) return a>b end) --Decreasing order
        local current, count = 0, 0
        for k, v in ipairs(trackDice) do
            if(v == current) then
                count = count + 1
            else
                if(current ~= 0) then
                    tallyString = tallyString .. count .. "d" .. current .. " + "
                end
                current = v
                count = 1
            end
            resultString = resultString .. tostring(v[2]) .. " + "
        end
        tallyString = tallyString .. count .. "d" .. current
        resultString = string.sub(resultString, 1, string.len(resultString) - 3) --remove trailing " + "
        --Display roll results
        local message = player.steam_name .. " rolls " .. tallyString
        if(rollModifier ~= nil and rollModifier ~= 0) then
            if #trackDice == 1 then
                message = message .. " + " .. rollModifier .. " = " .. rollTotal + rollModifier
            else
                message = message .. " + " .. rollModifier .. ": " .. resultString .. " + " .. rollModifier .. " = " .. rollTotal + rollModifier
            end
            rollModifier = nil
        else
            if #trackDice == 1 then
                message = message .. " = " .. rollTotal
            else
                message = message .. ": " .. resultString .. " = " .. rollTotal
            end
        end
        printToAll(message, player.color)
        if(modifierId ~= '') then
            self.UI.setAttribute(modifierId, "text", '')
        end
        rollTotal = 0
        trackDice = {}
    end
end

--Enable or disable object function
--Activated by toggle element
function toggled(toggledBy, toggledOn, id)
    if(toggledOn == 'True') then
        player = toggledBy
        isActive = true
        self.UI.setAttributes(id, {["text"]="Active for " .. player.steam_name,
                ["textColor"]=player.color})
    else
        isActive = false
        self.UI.setAttributes(id, {["text"]="Click to activate", ["textColor"]="White"})
    end
end

--Add a modifier to the dice roll
--Activated by modifier input field
function modifierAdded(enteredBy, value, id)
    rollModifier = tonumber(value)
    modifierId = id
end
