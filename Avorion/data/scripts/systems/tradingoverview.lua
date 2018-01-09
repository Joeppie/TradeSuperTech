package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")
require ("randomext")
local RingBuffer = require ("ringbuffer")

-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true

local tabbedWindow = nil
local routesTab = nil

local sellableGoodFrames = {}
local sellableGoodIcons = {}
local sellableGoodNameLabels = {}
local sellableGoodStockLabels = {}
local sellableGoodPriceLabels = {}
local sellableGoodSizeLabels = {}
local sellableGoodStationLabels = {}
local sellableGoodPriceFactorLabels = {}
local sellableGoodOnShipLabels = {}
local sellableGoodButtons = {}

local buyableGoodFrames = {}
local buyableGoodIcons = {}
local buyableGoodNameLabels = {}
local buyableGoodStockLabels = {}
local buyableGoodPriceLabels = {}
local buyableGoodSizeLabels = {}
local buyableGoodStationLabels = {}
local buyableGoodPriceFactorLabels = {}
local buyableGoodOnShipLabels = {}
local buyableGoodButtons = {}

local routeIcons = {}
local routeFrames = {}
local routePriceLabels = {}
local routeCoordLabels = {}
local routeStationLabels = {}
local routeButtons = {}

-- begin improved trading overview mod
local routeProfitLabels = {}
local routeStockLabels = {}
local routeVisibility = {}
local filterJumps=nil
local filterJumpsInput=nil
local filterDangerous=nil
local filterInSector=nil
local filterCargo=nil
local filterCargoInput=nil
local filterCredits=nil
local filterCreditsInput=nil
local modVersion=0.22
local modName="Improved Trading Overview"
local routesPerPage=14
local sellablesPerPage=15
local buyablesPerPage=15
local buySellPageNumber=nil
--maxCargo={10}
--Entity(Player().craftIndex):addKeyedAbsoluteBias(12345,100)
-- end improved trading overview mod

local routeIcons = {}
local routeFrames = {}
local routePriceLabels = {}
local routeCoordLabels = {}
local routeStationLabels = {}
local routeButtons = {}
local routeAmountOnShipLabels = {}
sellable = {}
buyable = {}

local routes = {}
local tradingData = nil
local tradingSectors = nil

local routes = {}
local historySize = 0
local tradingData = nil

local sellablesPage = 0
local buyablesPage = 0
local routesPage = 0

local sellableSortFunction = nil
local buyableSortFunction = nil

function seePrices(seed, rarity)
    --Hacked return rarity.value >= 0
	return true
end

function seePriceFactors(seed, rarity)
    --Hacked return rarity.value >= 1
	return true
end

function seeMultipleSectors(seed, rarity)
	--Hacked return rarity.value>=3
	return true
end

-- begin improved trading overview mod
function seeInventories(seed, rarity)
    --Hacked return rarity.value >= 4
	return true
end

function seeProfits(seed, rarity)
    --Hacked return rarity.value >= 5
	return true
end
-- end improved trading overview mod


function getHistorySize(seed, rarity)
	--return 20 --Hacked
    if rarity.value == 2 then
        return 1
    elseif rarity.value >= 3 then
        math.randomseed(seed)

        if rarity.value == 5 then
            return getInt(7, 15)
        elseif rarity.value == 4 then
            return getInt(4, 6)
        elseif  rarity.value == 3 then
            return getInt(2, 3)
        end
    end

    return 0
end

function onInstalled(seed, rarity)
-- begin improved trading overview mod
	print(modName .. " v" .. modVersion .. "-Fixed by (General) Inaptitude aka Joeppie")

	historySize = getHistorySize(seed, rarity)
-- end improved trading overview mod
    if onServer() then
        local size = getHistorySize(seed, rarity)
        if size > 0 then
            tradingData = RingBuffer(math.max(historySize, 1))
-- begin improved trading overview mod
			tradingSectors = RingBuffer(size)
-- end improved trading overview mod
            collectSectorData()
-- begin improved trading overview mod

-- end improved trading overview mod
        end
    end

end

-- begin improved trading overview mod
function refreshSector()
	invokeServerFunction("collectSectorData")
	invokeServerFunction("getData", Player().index)
end
-- end improved trading overview mod

function onUninstalled(seed, rarity)
end

function getName(seed, rarity)
    local prefix = ""
    if rarity.value == 0 then
        return "Basic Trading System"%_t
    elseif rarity.value == 1 then
        return "Improved Trading System"%_t
    elseif rarity.value == 2 then
        return "Advanced Trading System"%_t
    elseif rarity.value == 3 then
        return "High-Tech Trading System"%_t
    elseif rarity.value == 4 then
        return "Salesman's Trading System"%_t
    elseif rarity.value == 5 then
        return "Ultra-Tech Trading System"%_t
    end

    return "Trading System"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/cash.png"
end

function getPrice(seed, rarity)
    local num = getHistorySize(seed, rarity)
    local price = (rarity.value + 2) * 4000 + 5000 * num;
    return price * 2.5 ^ rarity.value
end

function getTooltipLines(seed, rarity)
    local lines = {}

    if seePrices(seed, rarity) then
        table.insert(lines, {ltext = "Display prices of goods"%_t, icon = "data/textures/icons/coins.png"})
    end
    if seePriceFactors(seed, rarity) then
        table.insert(lines, {ltext = "Display price ratios of goods"%_t, icon = "data/textures/icons/coins.png"})
	end

-- begin improved trading overview mod
    if seeInventories(seed, rarity) then
        table.insert(lines, {ltext = "Display inventories of stations in trade routes"%_t, icon = "data/textures/icons/coins.png"})
	end

    if seeProfits(seed, rarity) then
        table.insert(lines, {ltext = "Display estimated profit for each trade route"%_t, icon = "data/textures/icons/coins.png"})
	end

	if seeProfits(seed, rarity) then
		table.insert(lines, {ltext = "Filters: jump, dangerous, in-sector, cargo, credits"%_t, icon="data/textures/icons/circuitry.png"})
	elseif seeInventories(seed, rarity) then
		table.insert(lines, {ltext = "Filters: jump, dangerous, in-sector, cargo"%_t, icon="data/textures/icons/circuitry.png"})
	elseif seeMultipleSectors(seed, rarity) then
		table.insert(lines, {ltext = "Filters: jump, dangerous, in-sector"%_t, icon="data/textures/icons/circuitry.png"})
	end
-- end improved trading overview mod

    return lines
end

function getDescriptionLines(seed, rarity)
    local lines =
    {
        {ltext = "View trading offers of all stations of the sector"%_t}
    }

    local history = getHistorySize(seed, rarity)

    if history == 1 then
        table.insert(lines, {ltext = "Display trade routes in current sector"%_t})
    elseif history > 1 then
        table.insert(lines, {ltext = string.format("Display trade routes in last %i sectors"%_t, history)})
    end

    return lines
end

function gatherData()

    local sellable = {}
    local buyable = {}
    local scripts = {"consumer.lua", "factory.lua", "tradingpost.lua"}

    for _, station in pairs({Sector():getEntitiesByType(EntityType.Station)}) do
        for _, script in pairs(scripts) do

            local results = {station:invokeFunction(script, "getBoughtGoods")}
            local callResult = results[1]

            if callResult == 0 then -- call was successful, the station buys goods

                for i = 2, #results do
                    local name = results[i];

                    local callOk, good = station:invokeFunction(script, "getGoodByName", name)
                    if callOk ~= 0 then print("getGoodByName failed: " .. callOk) end

                    local callOk, stock, maxStock = station:invokeFunction(script, "getStock", name)
                    if callOk ~= 0 then print("getStock failed" .. callOk) end

                    local callOk, price = station:invokeFunction(script, "getBuyPrice", name, Faction().index)
                    if callOk ~= 0 then print("getBuyPrice failed" .. callOk) end

                    table.insert(sellable, {good = good, price = price, stock = stock, maxStock = maxStock, station = station.title, titleArgs = station:getTitleArguments(), stationIndex = station.index, coords = vec2(Sector():getCoordinates())})
                end
            end

            local results = {station:invokeFunction(script, "getSoldGoods")}
            local callResult = results[1]

            if callResult == 0 then -- call was successful, the station sells goods

                for i = 2, #results do
                    local name = results[i];

                    local callOk, good = station:invokeFunction(script, "getGoodByName", name)
                    if callOk ~= 0 then print("getGoodByName failed: " .. callOk) end

                    local callOk, stock, maxStock = station:invokeFunction(script, "getStock", name)
                    if callOk ~= 0 then print("getStock failed" .. callOk) end

                    local callOk, price = station:invokeFunction(script, "getSellPrice", name, Faction().index)
                    if callOk ~= 0 then print("getSellPrice failed" .. callOk) end

                    table.insert(buyable, {good = good, price = price, stock = stock, maxStock = maxStock, station = station.title, titleArgs = station:getTitleArguments(), stationIndex = station.index, coords = vec2(Sector():getCoordinates())})
                end
            end
        end
    end

    return sellable, buyable
end

function onSectorChanged()
    collectSectorData()
end

function collectSectorData()
    if tradingData then
        local sellable, buyable = gatherData()

       -- print("gathered " .. #sellable .. " sellable goods from sector " .. tostring(vec2(Sector():getCoordinates())))
       -- print("gathered " .. #buyable .. " buyable goods from sector " .. tostring(vec2(Sector():getCoordinates())))

        tradingData:insert({sellable = sellable, buyable = buyable})

-- begin improved trading overview mod
		tradingSectors:insert(vec2(Sector():getCoordinates()))
-- end improved trading overview mod

        analyzeSectorHistory()
    end
end

function analyzeSectorHistory()

    if historySize == 0 then
        routes = {}
        return
    end

--    print("analyzing sector history")

    local buyables = {}
    local sellables = {}
    routes = {}

    local counter = 0
    local gc = 0

    -- find best offer in buyables for every good
    for _, sectorData in ipairs(tradingData.data) do
        -- find best offer in buyable for every good
        for _, offer in pairs(sectorData.buyable) do
            local existing = buyables[offer.good.name]
            if existing == nil or offer.price < existing.price then
                buyables[offer.good.name] = offer
            end

            gc = gc + 1
        end

        -- find best offer in sellable for every good
        for _, offer in pairs(sectorData.sellable) do
            local existing = sellables[offer.good.name]
            if existing == nil or offer.price > existing.price then
                sellables[offer.good.name] = offer
            end

            gc = gc + 1
        end

        counter = counter + 1
    end

    -- match those two to find possible trading routes
    for name, offer in pairs(buyables) do

        if offer.stock > 0 then
            local sellable = sellables[name]

            if sellable ~= nil and sellable.price > offer.price then
                table.insert(routes, {sellable=sellable, buyable=offer})

               -- print(string.format("found trading route for %s, buy price (in sector %s): %i, sell price (in sector %s): %i", name, tostring(offer.coords), offer.price, tostring(sellable.coords), sellable.price))
            end
        end
    end

--    print("analyzed " .. counter .. " data sets with " .. gc .. " different goods")

end

function getData(playerIndex)
    local sellable, buyable = gatherData()
    tradingData.data[tradingData.last] = {sellable = sellable, buyable = buyable}
	analyzeSectorHistory()
    invokeClientFunction(Player(playerIndex), "setData", sellable, buyable, routes)
end



-- if this function returns false, the script will not be listed in the interaction window on the client,
-- even though its UI may be registered
function interactionPossible(playerIndex, option)

    local player = Player()
    if Entity().index == player.craftIndex then
        return true
    end

    return false
end

function initUI()
    local size = vec2(1000, 670)
    local res = getResolution()

    local menu = ScriptUI()
    local mainWindow = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5));
    menu:registerWindow(mainWindow, "Trading Overview"%_t);

    mainWindow.caption = "Trading Overview"%_t
    mainWindow.showCloseButton = 1
    mainWindow.moveable = 1

    -- create a tabbed window inside the main window
    tabbedWindow = mainWindow:createTabbedWindow(Rect(vec2(10, 10), size - 10))

    -- create routes tab
    routesTab = tabbedWindow:createTab("Trading Routes"%_t, "data/textures/icons/trade-route.png", "View detected trading routes"%_t)
    buildRoutesGui(routesTab)

    -- create buy tab
    local buyTab = tabbedWindow:createTab("Buy"%_t, "data/textures/icons/purse.png", "Buy from stations"%_t)
    buildGui(buyTab, 1)

    -- create sell tab
    local sellTab = tabbedWindow:createTab("Sell"%_t, "data/textures/icons/coins.png", "Sell to stations"%_t)
    buildGui(sellTab, 0)

    guiInitialized = 1

end

function onShowWindow()
    invokeServerFunction("getData", Player().index)
end

function setData(sellable_received, buyable_received, routes_received)

    sellable = sellable_received
    buyable = buyable_received
    routes = routes_received

    local ship = Entity()

    for _, route in pairs(routes) do
        for j, offer in pairs({route.buyable, route.sellable}) do
            offer.amountOnShip = ship:getCargoAmount(offer.good)
            -- translate argument values of station title
            for k, v in pairs(offer.titleArgs) do
                offer.titleArgs[k] = v%_t
            end
        end
    end

    for _, good in pairs(buyable) do
        good.amountOnShip = ship:getCargoAmount(good.good)

        -- translate argument values of station title
        for k, v in pairs(good.titleArgs) do
            good.titleArgs[k] = v%_t
        end
    end

    for _, good in pairs(sellable) do
	   good.amountOnShip = ship:getCargoAmount(good.good)
        -- translate argument values of station title
        for k, v in pairs(good.titleArgs) do
            good.titleArgs[k] = v%_t
        end
    end

	--if guiInitialized==1 then
	refreshUI()
	--end
end

function sortByNameAsc(a, b) return a.good.displayPlural < b.good.displayPlural end
function sortByNameDes(a, b) return a.good.displayPlural > b.good.displayPlural end

function sortByStockAsc(a, b) return a.stock / a.maxStock < b.stock / b.maxStock end
function sortByStockDes(a, b) return a.stock / a.maxStock > b.stock / b.maxStock end

function sortByPriceAsc(a, b) return a.good.price < b.good.price end
function sortByPriceDes(a, b) return a.good.price > b.good.price end

function sortByVolAsc(a, b) return a.good.size < b.good.size end
function sortByVolDes(a, b) return a.good.size > b.good.size end

function sortByPriceFactorAsc(a, b) return a.price / a.good.price < b.price / b.good.price end
function sortByPriceFactorDes(a, b) return a.price / a.good.price > b.price / b.good.price end

function sortByStationAsc(a, b) return a.station < b.station end
function sortByStationDes(a, b) return a.station > b.station end

function sortByAmountOnShipAsc(a, b) return a.amountOnShip < b.amountOnShip end
function sortByAmountOnShipDes(a, b) return a.amountOnShip > b.amountOnShip end

-- begin improved trading overview mod
function routesByProfit(a, b)
    -- calculate max profit
    local pa = (a.sellable.price - a.buyable.price) * math.min(a.buyable.stock,a.sellable.maxStock-a.sellable.stock)
    local pb = (b.sellable.price - b.buyable.price) * math.min(b.buyable.stock,b.sellable.maxStock-b.sellable.stock)
    return pa > pb
end
-- end improved trading overview mod

function routesByPriceMargin(a, b)
    -- calculate max profit
    local pa = (a.sellable.price - a.buyable.price)
    local pb = (b.sellable.price - b.buyable.price)
    return pa > pb
end

sellableSortFunction = sortByNameAsc
buyableSortFunction = sortByNameAsc

function refreshBuyablesUI()
    table.sort(buyable, buyableSortFunction)

-- begin improved trading overview mod
	buySellPageNumber.caption=buyablesPage+1 .. "/" .. math.ceil(#buyable/buyablesPerPage)

	if #buyable<buyablesPage*buyablesPerPage then
		buyablesPage=buyablesPage-1
	end

    for index = 1, buyablesPerPage do
-- end improved trading overview mod
        buyableGoodFrames[index]:hide()
        buyableGoodIcons[index]:hide()
        buyableGoodNameLabels[index]:hide()
        buyableGoodStockLabels[index]:hide()
        buyableGoodPriceLabels[index]:hide()
        buyableGoodSizeLabels[index]:hide()
        buyableGoodStationLabels[index]:hide()
        buyableGoodPriceFactorLabels[index]:hide()
        buyableGoodOnShipLabels[index]:hide()
        buyableGoodButtons[index]:hide()
    end

    local index = 0

-- begin improved trading overview mod

    for i, good in pairs(buyable) do

        if i > buyablesPage * buyablesPerPage and i <= (buyablesPage + 1) * buyablesPerPage then
            index = index + 1
            if index > buyablesPerPage then break end
-- end improved trading overview mod

            buyableGoodNameLabels[index].caption = good.good.displayPlural
            buyableGoodStockLabels[index].caption = math.floor(good.stock) .. " / " .. math.floor(good.maxStock)
            buyableGoodPriceLabels[index].caption = createMonetaryString(good.price)
            buyableGoodPriceFactorLabels[index].caption = string.format("%+i%%", round((good.price / good.good.price - 1.0) * 100))
			buyableGoodSizeLabels[index].caption = round(good.good.size, 2)
            buyableGoodIcons[index].picture = good.good.icon
            buyableGoodStationLabels[index].caption = good.station%_t % good.titleArgs
           if good.amountOnShip > 0 then
                buyableGoodOnShipLabels[index].caption = good.amountOnShip
            else
                buyableGoodOnShipLabels[index].caption = "-"
            end

            buyableGoodFrames[index]:show()
            buyableGoodIcons[index]:show()
            buyableGoodNameLabels[index]:show()
            buyableGoodStockLabels[index]:show()
            buyableGoodPriceLabels[index]:show()
            buyableGoodSizeLabels[index]:show()
            buyableGoodStationLabels[index]:show()
            buyableGoodPriceFactorLabels[index]:show()
            buyableGoodButtons[index]:show()
            buyableGoodOnShipLabels[index]:show()

            if getRarity().value < 1 then
                --Hacked buyableGoodPriceLabels[index].caption = "-"
            end

            if getRarity().value < 2 then
                --Hacked buyableGoodPriceFactorLabels[index].caption = "-"
            end

        end
    end

end


function refreshSellablesUI()
    table.sort(sellable, sellableSortFunction)

-- begin improved trading overview mod
    for index = 1, sellablesPerPage do
-- end improved trading overview mod
        sellableGoodFrames[index]:hide()
        sellableGoodIcons[index]:hide()
        sellableGoodNameLabels[index]:hide()
        sellableGoodStockLabels[index]:hide()
        sellableGoodPriceLabels[index]:hide()
        sellableGoodSizeLabels[index]:hide()
        sellableGoodStationLabels[index]:hide()
        sellableGoodPriceFactorLabels[index]:hide()
        sellableGoodOnShipLabels[index]:hide()
        sellableGoodButtons[index]:hide()
    end

-- begin improved trading overview mod
	if #sellable<sellablesPage*sellablesPerPage then
		sellablesPage=sellablesPage-1
	end

	buySellPageNumber.caption=sellablesPage+1 .. "/" .. math.ceil(#sellable/sellablesPerPage)
-- end improved trading overview mod

    local index = 0
    for i, good in pairs(sellable) do

-- begin improved trading overview mod
        if i > sellablesPage * sellablesPerPage and i <= (sellablesPage + 1) * sellablesPerPage then
            index = index + 1
            if index > sellablesPerPage then break end
-- end improved trading overview mod

            local priceFactor = ""
            if good.good.price > 0 then
                priceFactor = string.format("%+i%%", round((good.price / good.good.price - 1.0) * 100))
            end

            sellableGoodNameLabels[index].caption = good.good.displayPlural
            sellableGoodStockLabels[index].caption = math.floor(good.stock) .. " / " .. math.floor(good.maxStock)
            sellableGoodPriceLabels[index].caption = createMonetaryString(good.price)
            sellableGoodPriceFactorLabels[index].caption = priceFactor
            sellableGoodSizeLabels[index].caption = round(good.good.size, 2)
            sellableGoodIcons[index].picture = good.good.icon
            sellableGoodStationLabels[index].caption = good.station%_t % good.titleArgs
            if good.amountOnShip > 0 then
                sellableGoodOnShipLabels[index].caption = good.amountOnShip
            else
                sellableGoodOnShipLabels[index].caption = "-"
            end

            sellableGoodFrames[index]:show()
            sellableGoodIcons[index]:show()
            sellableGoodNameLabels[index]:show()
            sellableGoodStockLabels[index]:show()
            sellableGoodPriceLabels[index]:show()
            sellableGoodSizeLabels[index]:show()
            sellableGoodStationLabels[index]:show()
            sellableGoodPriceFactorLabels[index]:show()
            sellableGoodOnShipLabels[index]:show()
            sellableGoodButtons[index]:show()


            if getRarity().value < 1 then
                --Hacked sellableGoodPriceLabels[index].caption = "-"
            end

            if getRarity().value < 2 then
                --Hacked sellableGoodPriceFactorLabels[index].caption = "-"
            end

        end
    end

end

function refreshRoutesUI()

    if historySize == 0 then
        tabbedWindow:deactivateTab(routesTab)
    	return
    end

-- begin improved trading overview mod
    for index = 1, routesPerPage do
-- end improved trading overview mod

        for j = 1, 2 do
            routePriceLabels[index][j]:hide()
            routeStationLabels[index][j]:hide()
            routeCoordLabels[index][j]:hide()
            routeFrames[index][j]:hide()
            routeButtons[index][j]:hide()
            routeIcons[index]:hide()
			routeAmountOnShipLabels[index]:hide()

-- begin improved trading overview mod
            routeProfitLabels[index]:hide()
            routeStockLabels[index][j]:hide()
			collectSectorData()
-- end improved trading overview mod

        end
    end

-- begin improved trading overview mod
    --Hacked if getRarity().value < 5 then
        --Hacked table.sort(routes, routesByPriceMargin)
    --Hacked else
        table.sort(routes, routesByProfit)
    --Hacked end
-- end improved trading overview mod

    local index = 0
    for i, route in pairs(routes) do

-- begin improved trading overview mod
		if #routes<routesPage*routesPerPage then
			routesPage=routesPage-1
		end
        if i > routesPage * routesPerPage and i <= (routesPage + 1) * routesPerPage then
            index = index + 1
            if index > routesPerPage then break end
-- end improved trading overview mod
            for j, offer in pairs({route.buyable, route.sellable}) do

-- begin improved trading overview mod
				local maxCargoSpace=1000000000
				local maxCredits=10000000000
				local unitsOfGood=math.min(math.floor(route.sellable.maxStock)-math.floor(route.sellable.stock),route.buyable.stock)
				local sizeOfGood=offer.good.size

				if filterCargo.checked==true then
					maxCargoSpace=tonumber(filterCargoInput.text)
				end
				if filterCredits.checked==true then
					maxCredits=tonumber(filterCreditsInput.text)
				end
				local routeProfit=unitsOfGood*(math.floor(route.sellable.price)-math.floor(route.buyable.price))
				local upFrontCost=unitsOfGood*(math.floor(route.buyable.price))
				local routeCargo=unitsOfGood*sizeOfGood
				local jumpDistance=math.ceil(math.sqrt(math.pow(route.sellable.coords.x-route.buyable.coords.x,2)+math.pow(route.sellable.coords.y-route.buyable.coords.y,2)))
				local curSector=vec2(Sector().getCoordinates(Sector()))

				if (#filterCreditsInput.text==0) then
					filterCreditsInput.text="0"
				end
				if (#filterCargoInput.text==0) then
					filterCargoInput.text="0"
				end
				if (#filterJumpsInput.text==0) then
					filterJumpsInput.text="0"
				end

				--print( tostring(curSector) .. Entity(Player().craftIndex).maxCargoSpace)

				if not ((filterCredits.checked==true and tonumber(filterCreditsInput.text) < upFrontCost)
					or (filterCargo.checked==true and tonumber(filterCargoInput.text) < routeCargo)
					or (filterJumps.checked==true and tonumber(filterJumpsInput.text) < jumpDistance)
					or (filterDangerous.checked==true and (offer.good.illegal or offer.good.dangerous))
					or (filterInSector.checked==true and (route.buyable.coords.x~=curSector.x or route.buyable.coords.y~=curSector.y or route.sellable.coords.x~=curSector.x or route.sellable.coords.y~=curSector.y))) then
					if index<1 then
						index=1
					end
					routeProfitLabels[index].caption = createMonetaryString(routeProfit)
					if j == 1 then
						routeStockLabels[index][j].caption = math.floor(offer.stock)
					else
						routeStockLabels[index][j].caption = math.floor(offer.maxStock)-math.floor(offer.stock)
					end
	-- end improved trading overview mod

					routePriceLabels[index][j].caption = createMonetaryString(offer.price)
					routeStationLabels[index][j].caption = offer.station%_t % offer.titleArgs
					routeCoordLabels[index][j].caption = tostring(offer.coords)
					routeIcons[index].picture = offer.good.icon

	-- begin improved trading overview mod
					local icontooltip = offer.good.displayPlural
					--Hacked if getRarity().value > 2 then
						icontooltip = icontooltip .. "\n\nJump distance: " .. jumpDistance
					--Hacked end
					--Hacked if getRarity().value > 3 then
						icontooltip = icontooltip .. "\nUp-front cost: " .. createMonetaryString(upFrontCost)
						icontooltip = icontooltip .. "\nCargo space required: " .. routeCargo
						filterCargo:show()
						filterCargoInput:show()
					--Hacked end

					routeIcons[index].tooltip = icontooltip

		             if j == 2 then
		                if offer.amountOnShip > 0 then
		                    routeAmountOnShipLabels[index].caption = offer.amountOnShip
		                else
		                    routeAmountOnShipLabels[index].caption = "-"
		                end
		                routeAmountOnShipLabels[index]:show()
    	            end

					routePriceLabels[index][j]:show()
					routeStationLabels[index][j]:show()
					routeCoordLabels[index][j]:show()
					routeFrames[index][j]:show()
					routeButtons[index][j]:show()
					routeIcons[index]:show()

	-- begin improved trading overview mod
					routeProfitLabels[index]:show()
					routeStockLabels[index][j]:show()

					if getRarity().value < 4 then
					--Hacked 	routeStockLabels[index][j].caption = "-"
					end

					if getRarity().value < 5 then
						--Hacked routeProfitLabels[index].caption = "-"
					end
					--Hacked if getRarity().value >2 then
						filterJumps:show()
						filterJumpsInput:show()
						filterInSector:show()
						filterDangerous:show()
					--Hacked end
					--Hacked if getRarity().value>4 then
						filterCredits:show()
						filterCreditsInput:show()
					--Hacked end
				else
					index=index-1
				end
-- end improved trading overview mod

            end
        end
    end
end

function refreshUI()

    refreshBuyablesUI()
    refreshSellablesUI()
    refreshRoutesUI()

end

function buildGui(window, guiType)

    local buttonCaption = "Show"%_t
    local buttonCallback = ""
    local nextPageFunc = ""
    local previousPageFunc = ""

    if guiType == 1 then
        buttonCallback = "onBuyShowButtonPressed"
        nextPageFunc = "onNextBuyablesPage"
        previousPageFunc = "onPreviousBuyablesPage"
    else
        buttonCallback = "onSellShowButtonPressed"
        nextPageFunc = "onNextSellablesPage"
        previousPageFunc = "onPreviousSellablesPage"
    end

    local size = window.size

    window:createFrame(Rect(size))

    local pictureX = 270
    local nameX = 20
    local stockX = 310
    local volX = 430
    local priceX = 480
    local priceFactorLabelX = 550
    local stationLabelX = 610
    local onShipLabelX = 880
    local buttonX = 940

    -- header
    nameLabel = window:createLabel(vec2(nameX, 10), "Name"%_t, 15)
    stockLabel = window:createLabel(vec2(stockX, 10), "Stock"%_t, 15)
    volLabel = window:createLabel(vec2(volX, 10), "Vol"%_t, 15)
    priceLabel = window:createLabel(vec2(priceX, 10), "Cr"%_t, 15)
    priceFactorLabel = window:createLabel(vec2(priceFactorLabelX, 10), "%", 15)
    stationLabel = window:createLabel(vec2(stationLabelX, 10), "Station"%_t, 15)
    onShipLabel = window:createLabel(vec2(onShipLabelX, 10), "You"%_t, 15)

    nameLabel.width = 250
    stockLabel.width = 90
    volLabel.width = 50
    priceLabel.width = 70
    priceFactorLabel.width = 60
    stationLabel.width = 240
    onShipLabel.width = 70

    if guiType == 1 then
        nameLabel.mouseDownFunction = "onBuyableNameLabelClick"
        stockLabel.mouseDownFunction = "onBuyableStockLabelClick"
        volLabel.mouseDownFunction = "onBuyableVolLabelClick"
        priceLabel.mouseDownFunction = "onBuyablePriceLabelClick"
        priceFactorLabel.mouseDownFunction = "onBuyablePriceFactorLabelClick"
        stationLabel.mouseDownFunction = "onBuyableStationLabelClick"
        onShipLabel.mouseDownFunction = "onBuyableOnShipLabelClick"
    else
        nameLabel.mouseDownFunction = "onSellableNameLabelClick"
        stockLabel.mouseDownFunction = "onSellableStockLabelClick"
        volLabel.mouseDownFunction = "onSellableVolLabelClick"
        priceLabel.mouseDownFunction = "onSellablePriceLabelClick"
        priceFactorLabel.mouseDownFunction = "onSellablePriceFactorLabelClick"
        stationLabel.mouseDownFunction = "onSellableStationLabelClick"
        onShipLabel.mouseDownFunction = "onSellableOnShipLabelClick"
    end

-- begin improved trading overview mod
    -- footer
    local backButton=window:createButton(Rect(10, size.y - 40, 60, size.y - 10), "<", previousPageFunc)
	buySellPageNumber=window:createLabel(vec2(size.x/2-20,size.y-40),"-/-",15)
    local nextButton=window:createButton(Rect(size.x - 60, size.y - 40, size.x - 10, size.y - 10), ">", nextPageFunc)

	backButton.tooltip="Previous Page"
	nextButton.tooltip="Next Page"

	totalLines=15
-- end improved trading overview mod

    local y = 35
-- begin improved trading overview mod
    for i = 1, totalLines do
-- end improved trading overview mod

        local yText = y + 6

        local frame = window:createFrame(Rect(10, y, size.x - 50, 30 + y))

        local iconPicture = window:createPicture(Rect(pictureX, yText - 5, 29 + pictureX, 29 + yText - 5), "")
        local nameLabel = window:createLabel(vec2(nameX, yText), "", 15)
        local stockLabel = window:createLabel(vec2(stockX, yText), "", 15)
        local priceLabel = window:createLabel(vec2(priceX, yText), "", 15)
        local sizeLabel = window:createLabel(vec2(volX, yText), "", 15)
        local priceFactorLabel = window:createLabel(vec2(priceFactorLabelX, yText), "", 15)
        local stationLabel = window:createLabel(vec2(stationLabelX, yText), "", 15)
        local onShipLabel = window:createLabel(vec2(onShipLabelX, yText), "", 15)
        local button = window:createButton(Rect(buttonX, yText - 6, buttonX + 30, 30 + yText - 6), "", buttonCallback)

        stockLabel.font = "Arial"
        priceLabel.font = "Arial"
        sizeLabel.font = "Arial"
        priceFactorLabel.font = "Arial"
        stationLabel.font = "Arial"
		onShipLabel.font = "Arial"

        button.icon = "data/textures/icons/look-at.png"
        iconPicture.isIcon = 1

        if guiType == 1 then
            table.insert(buyableGoodIcons, iconPicture)
            table.insert(buyableGoodFrames, frame)
            table.insert(buyableGoodNameLabels, nameLabel)
            table.insert(buyableGoodStockLabels, stockLabel)
            table.insert(buyableGoodPriceLabels, priceLabel)
            table.insert(buyableGoodSizeLabels, sizeLabel)
            table.insert(buyableGoodPriceFactorLabels, priceFactorLabel)
            table.insert(buyableGoodStationLabels, stationLabel)
            table.insert(buyableGoodOnShipLabels, onShipLabel)
            table.insert(buyableGoodButtons, button)
        else
            table.insert(sellableGoodIcons, iconPicture)
            table.insert(sellableGoodFrames, frame)
            table.insert(sellableGoodNameLabels, nameLabel)
            table.insert(sellableGoodStockLabels, stockLabel)
            table.insert(sellableGoodPriceLabels, priceLabel)
            table.insert(sellableGoodSizeLabels, sizeLabel)
            table.insert(sellableGoodPriceFactorLabels, priceFactorLabel)
            table.insert(sellableGoodStationLabels, stationLabel)
            table.insert(sellableGoodOnShipLabels, onShipLabel)
            table.insert(sellableGoodButtons, button)
        end

        frame:hide();
        iconPicture:hide();
        nameLabel:hide();
        stockLabel:hide();
        priceLabel:hide();
        sizeLabel:hide();
        stationLabel:hide();
        onShipLabel:hide()
        button:hide();

        y = y + 35
    end

end

function buildRoutesGui(window)
    local buttonCaption = "Show"%_t

    local buttonCallback = "onRouteShowStationPressed"
    local nextPageFunc = "onNextRoutesPage"
    local previousPageFunc = "onPreviousRoutesPage"

    local size = window.size

    window:createFrame(Rect(size))

    local priceX = 10

-- begin improved trading overview mod
    local stockX = 70
    local coordLabelX = 140
    local stationLabelX = 230
    local onShipLabelX = 370


    -- footer
    local backButton=window:createButton(Rect(10, size.y - 40, 60, size.y - 10), "<", previousPageFunc)
    local nextButton=window:createButton(Rect(size.x - 60, size.y - 40, size.x - 10, size.y - 10), ">", nextPageFunc)

	backButton.tooltip="Previous Page"
	nextButton.tooltip="Next Page"

-- end improved trading overview mod

-- begin improved trading overview mod
	local filterY=10
	local filterWidth=100
	local filterInputOffset=0
	local filterHeight=25
	local filterTextSize=15
	local filterOffset=20
	local refreshButtonX = 80
	local filterJumpsX=refreshButtonX+filterWidth+filterOffset-30
	local filterJumpsInputX=filterJumpsX+filterWidth+filterInputOffset
	local filterDangerousButtonX = filterJumpsInputX+filterWidth+filterOffset-60
	local filterInSectorButtonX = filterDangerousButtonX+filterWidth+filterOffset+30
	local filterCargoButtonX = filterInSectorButtonX+filterWidth+filterOffset
	local filterCargoInputX=filterCargoButtonX+filterWidth+filterInputOffset
	local filterCreditsButtonX =filterCargoInputX+filterWidth+filterOffset-40
	local filterCreditsInputX=filterCreditsButtonX+filterWidth+filterInputOffset

	local filterLabel=window:createLabel(vec2(10,10),"Filter:"%_t,18)
	local refreshButton=window:createButton(Rect(refreshButtonX,filterY,refreshButtonX+filterWidth-20,filterY+filterHeight),"Refresh"%_t,"refreshSector")
	filterJumps=window:createCheckBox(Rect(filterJumpsX,filterY,filterJumpsX+filterWidth,filterY+filterHeight),"Max Jump"%_t,"refreshRoutesUI")
	filterJumpsInput=window:createTextBox(Rect(filterJumpsInputX,filterY,filterJumpsInputX+filterWidth-60,filterY+filterHeight),""%_t)
	filterDangerous=window:createCheckBox(Rect(filterDangerousButtonX,filterY,filterDangerousButtonX+filterWidth+30,filterY+filterHeight),"Hide Dangerous"%_t,"refreshRoutesUI")
	filterInSector=window:createCheckBox(Rect(filterInSectorButtonX,filterY,filterInSectorButtonX+filterWidth,filterY+filterHeight),"In-Sector"%_t,"refreshRoutesUI")
	filterCargo=window:createCheckBox(Rect(filterCargoButtonX,filterY,filterCargoButtonX+filterWidth,filterY+filterHeight),"Max Cargo"%_t,"refreshRoutesUI")
	filterCargoInput=window:createTextBox(Rect(filterCargoInputX,filterY,filterCargoInputX+filterWidth-30,filterY+filterHeight),""%_t)
	filterCredits=window:createCheckBox(Rect(filterCreditsButtonX,filterY,filterCreditsButtonX+filterWidth,filterY+filterHeight),"Max Credits"%_t,"refreshRoutesUI")
	filterCreditsInput=window:createTextBox(Rect(filterCreditsInputX,filterY,filterCreditsInputX+filterWidth,filterY+filterHeight),""%_t)

	refreshButton:hide()
	filterJumps:hide()
	filterJumpsInput:hide()
	filterDangerous:hide()
	filterInSector:hide()
	filterCargo:hide()
	filterCargoInput:hide()
	filterCredits:hide()
	filterCreditsInput:hide()

	filterJumps.tooltip="If checked, hides trade routes longer than the specified number of jumps"
	filterDangerous.tooltip="If checked, hides trade routes for dangerous/illegal goods"
	filterInSector.tooltip="If checked, displays trade routes in the current sector only"
	filterCargo.tooltip="If checked, displays trade routes requiring up to the specified maximum cargo"
	filterCredits.tooltip="If checked, displays trade routes with up-front cost up to the specified maximum"

	filterJumpsInput.text="0"
	filterCargoInput.text="0"
	filterCreditsInput.text="0"

	filterJumpsInput.allowedCharacters="0123456789"
	filterCargoInput.allowedCharacters="0123456789"
	filterCreditsInput.allowedCharacters="0123456789"
	filterJumpsInput.tooltip="Enter the maximum jump distance, then toggle the checkbox off and on"

	local headerY = 45
    local y = 65
-- end improved trading overview mod
    for i = 1, 14 do

        local yText = y + 6

        local msplit = UIVerticalSplitter(Rect(10, y, size.x - 10, 30 + y), 10, 0, 0.5)

-- begin improved trading overview mod
        msplit.leftSize = 100

        local icon = window:createPicture(Rect(msplit.left.lower.x, yText - 5, msplit.left.lower.x+30, 29 + yText - 5), "")
-- end improved trading overview mod

        icon.isIcon = 1
        icon.picture = "data/textures/icons/circuitry.png"
        icon:hide();

-- begin improved trading overview mod
        window:createLabel(vec2(msplit.left.lower.x + 40, headerY), "Profit"%_t, 15)
        local profit = window:createLabel(vec2(msplit.left.lower.x + 40, yText), "", 15)
        profit.font = "Arial"
        profit:hide();
-- end improved trading overview mod

        local vsplit = UIVerticalSplitter(msplit.right, 10, 0, 0.5)

        routeIcons[i] = icon
        routeFrames[i] = {}
        routePriceLabels[i] = {}
        routeCoordLabels[i] = {}
        routeStationLabels[i] = {}
        routeButtons[i] = {}
		routeAmountOnShipLabels[i] = nil

-- begin improved trading overview mod
        routeProfitLabels[i] = profit
        routeStockLabels[i] = {}
-- end improved trading overview mod

        for j, rect in pairs({vsplit.left, vsplit.right}) do

            -- create UI for good + station where to get it
            local ssplit = UIVerticalSplitter(rect, headerY, 0, 0.5)
            ssplit.rightSize = 30
            local x = ssplit.left.lower.x

            if i == 1 then
                -- header
-- begin improved trading overview mod
                window:createLabel(vec2(x + priceX, headerY), "Cr"%_t, 15)

                if j == 1 then
                    window:createLabel(vec2(x + stockX, headerY), "Stock"%_t, 15)
                else
                    window:createLabel(vec2(x + stockX, headerY), "Wants"%_t, 15)
					window:createLabel(vec2(x + onShipLabelX, 10), "You"%_t, 15)
                end

                window:createLabel(vec2(x + coordLabelX, headerY), "Coord"%_t, 15)

                if j == 1 then
                    window:createLabel(vec2(x + stationLabelX, headerY), "From"%_t, 15)
                else
                    window:createLabel(vec2(x + stationLabelX, headerY), "To"%_t, 15)
					window:createLabel(vec2(x + onShipLabelX, headerY), "You"%_t, 15)
-- end improved trading overview mod
                end
            end


            local frame = window:createFrame(ssplit.left)

            local priceLabel = window:createLabel(vec2(x + priceX, yText), "", 15)

-- begin improved trading overview mod
			local stockLabel = window:createLabel(vec2(x + stockX, yText), "", 15)
            local stationLabel = window:createLabel(vec2(x + stationLabelX, yText + 2), "", 12)
-- end improved trading overview mod

            local coordLabel = window:createLabel(vec2(x + coordLabelX, yText), "", 15)

            local button = window:createButton(ssplit.right, "", buttonCallback)

            button.icon = "data/textures/icons/look-at.png"

    		if j == 2 then
                local onShipLabel = window:createLabel(vec2(x + onShipLabelX, yText), "", 15)
                onShipLabel.font = FontType.Normal
                onShipLabel:hide()
                routeAmountOnShipLabels[i] = onShipLabel
            end

            frame:hide();
            priceLabel:hide();
            coordLabel:hide();
            stationLabel:hide();
            button:hide();

            priceLabel.font = "Arial"
            coordLabel.font = "Arial"
            stationLabel.font = "Arial"

            table.insert(routeFrames[i], frame)
            table.insert(routePriceLabels[i], priceLabel)
            table.insert(routeCoordLabels[i], coordLabel)
            table.insert(routeStationLabels[i], stationLabel)
            table.insert(routeButtons[i], button)

-- begin improved trading overview mod
            stockLabel:hide();
            stockLabel.font = "Arial"
            table.insert(routeStockLabels[i], stockLabel)
-- end improved trading overview mod


        end


        y = y + 35
    end

end


function onRouteShowStationPressed(button_in)

    for i, buttons in pairs(routeButtons) do
        for j, button in pairs(buttons) do
            if button.index == button_in.index then
                local stationIndex
                local coords
                if j == 1 then
                    stationIndex = routes[routesPage * 15 + i].buyable.stationIndex
                    coords = routes[routesPage * 15 + i].buyable.coords
                else
                    stationIndex = routes[routesPage * 15 + i].sellable.stationIndex
                    coords = routes[routesPage * 15 + i].sellable.coords
                end

                local x, y = Sector():getCoordinates()

                if coords.x == x and coords.y == y then
                    Player().selectedObject = Entity(stationIndex)
                else
                    GalaxyMap():setSelectedCoordinates(coords.x, coords.y)
                    GalaxyMap():show(coords.x, coords.y)
                end
            end
        end
    end

end

-- begin improved trading overview mod
function filterCreditsChecked()
	refreshUI()
end
-- end improved trading overview mod

function onNextRoutesPage()
    routesPage = routesPage + 1
    refreshUI()
end

function onPreviousRoutesPage()
    routesPage = math.max(0, routesPage - 1)
    refreshUI()
end

function onNextSellablesPage()
    sellablesPage = sellablesPage + 1
    refreshUI()
end

function onPreviousSellablesPage()
    sellablesPage = math.max(0, sellablesPage - 1)
    refreshUI()
end

function onNextBuyablesPage()
    buyablesPage = buyablesPage + 1
    refreshUI()
end

function onPreviousBuyablesPage()
    buyablesPage = math.max(0, buyablesPage - 1)
    refreshUI()
end

function onBuyShowButtonPressed(button_in)

    for index, button in pairs(buyableGoodButtons) do
        if button.index == button_in.index then
            Player().selectedObject = Entity(buyable[buyablesPage * 15 + index].stationIndex)
        end
    end

end

function onSellShowButtonPressed(button_in)

    for index, button in pairs(sellableGoodButtons) do
        if button.index == button_in.index then
            Player().selectedObject = Entity(sellable[sellablesPage * 15 + index].stationIndex)
        end
    end

end

function setSortFunction(default, alternative, buyable)

    if buyable == 1 then
        if buyableSortFunction == default then
            buyableSortFunction = alternative
        else
            buyableSortFunction = default
        end
    else
        if sellableSortFunction == default then
            sellableSortFunction = alternative
        else
            sellableSortFunction = default
        end
    end

    refreshUI()
end


function onBuyableNameLabelClick(index, button)
    setSortFunction(sortByNameAsc, sortByNameDes, 1)
end

function onBuyableStockLabelClick()
    setSortFunction(sortByStockAsc, sortByStockDes, 1)
end

function onBuyableVolLabelClick()
    setSortFunction(sortByVolAsc, sortByVolDes, 1)
end

function onBuyablePriceLabelClick()
--Hacked     if getRarity().value < 1 then return end
    setSortFunction(sortByPriceAsc, sortByPriceDes, 1)
end

function onBuyablePriceFactorLabelClick()
    --Hacked if getRarity().value < 2 then return end
    setSortFunction(sortByPriceFactorAsc, sortByPriceFactorDes, 1)
end

function onBuyableStationLabelClick()
    setSortFunction(sortByStationAsc, sortByStationDes, 1)
end

function onBuyableOnShipLabelClick()
    setSortFunction(sortByAmountOnShipDes, sortByAmountOnShipAsc, 1)
end

function onSellableNameLabelClick(index, button)
    setSortFunction(sortByNameAsc, sortByNameDes, 0)
end

function onSellableStockLabelClick()
    setSortFunction(sortByStockAsc, sortByStockDes, 0)
end

function onSellableVolLabelClick()
    setSortFunction(sortByVolAsc, sortByVolDes, 0)
end

function onSellablePriceLabelClick()
    --Hacked if getRarity().value < 1 then return end
    setSortFunction(sortByPriceAsc, sortByPriceDes, 0)
end

function onSellablePriceFactorLabelClick()
    --Hacked if getRarity().value < 2 then return end
    setSortFunction(sortByPriceFactorAsc, sortByPriceFactorDes, 0)
end

function onSellableStationLabelClick()
    setSortFunction(sortByStationAsc, sortByStationDes, 0)
end

function onSellableOnShipLabelClick()
    setSortFunction(sortByAmountOnShipDes, sortByAmountOnShipAsc, 0)
end
