local menu={}
menu[0] = {label = "Pan Mode Control", channel=16, cases={[0]="hold hold pan", [1]="hold hold hold", [2]="pan pan pan"}}
menu[1] = {label = "Pitch control", channel=12, cases={[0]="Apm", [1]="offline", [2]="User pitch"}}
menu[2] = {label = "Recenter camera", channel=15, cases={[0]="Normal", [1]="Recenter"}}
menu[3] = {label = "Script 1", channel=nil}
menu[4] = {label = "Script 2", channel=nil}
menu[5] = {label = "Script 3", channel=nil}
menu[6] = {label = "Script 4", channel=11, cases={[0]="Case#Default", [1]="Case#1", [2]="Case#2", [3]="Case#3"}}
menu[7] = {label = "Script 5", channel=16, cases={[0]="default", [1]="tmp"}}
menu[8] = {label = "Script 6", channel=nil}
menu[9] = {label = "Script 7", channel=nil}

local menu_index = 0
local display_rows = 6
local function init()
end

local function background()

end

local function parseValue(item)
	if item == nil or item.channel == nil then
		return ""
	end
	local value = getValue(147+item.channel)
	if item.cases[1] ~= nil
	then
		if value > 900 then
			return 1
		end
		if item.cases[2] ~= nil 
		then
			if value < -900 then
				return 2
			end
			if item.cases[3] ~= nil 
			then
				if value > 600 then
					return 3
				end
			end
		end
	end
	if item.cases[0] ~= nil then
		return 0
	end
	return 0
end

local function parseValueStr(item)
	local case = parseValue(item)
	if(case == nil or item == nil or item.cases == nil) then
		return ""
	elseif case == 1 then
		return item.cases[1]
	elseif case == 2 then 
		return item.cases[2]
	elseif case == 3 then
		return item.cases[3]
	elseif item.cases[0] ~= nil then
		return item.cases[0]
	end
	return "Default"
end

local function ternary(value, first, second)
	if value then
		return first
	end
	return second
end

local function run(event)
	lcd.drawScreenTitle("STorM32 Control Panel", 1, 1)
	if event == EVT_MENU_BREAK
	then
		menu_index = menu_index +1
		if menu[menu_index] == nil 
		then
			menu_index = 0
		end
	end
	
	local start = ternary(menu_index <display_rows, 0, menu_index -display_rows+1)
	local row = 0
	for i=start, start+display_rows-1, 1
	do
		local options = 0
		if i == menu_index 
		then
			options = INVERS
		end
		if menu[i] == nil
		then
			break
		end
		lcd.drawText(5, 9+8*row, menu[i].label, options)
		lcd.drawText(100, 9+8*row, parseValueStr(menu[i]), 0);
		row = row+1
	end
	
	local item = menu[menu_index]
	if item.channel ~= nil then
		local showSubmenu = false
		if model.getMixesCount(item.channel-1) == 1 then
			local mixLine = model.getMix(item.channel-1, 0)
			if mixLine.source == 84 then -- MAX
				showSubmenu = true
			end
		end
		if showSubmenu 
		then
			local current = parseValue(item)
			local next = current
			for i=1, 3, 1 
			do
				local tmp = (current + i)%4
				if item.cases[tmp] ~= nil then
					next = tmp
					break
				end
			end
			lcd.drawText(1, 57, "Press Enter to change to: "..item.cases[next], SMLSIZE)
			if event == EVT_ENTER_BREAK then

				if next ~= current then
					-- Change output
					local mixLine = model.getMix(item.channel-1, 0)
					if next == 0 then mixLine.weight=0
					elseif next == 1 then mixLine.weight=100
					elseif next == 2 then mixLine.weight=-100
					elseif next == 3 then mixLine.weight=70
					end
					model.insertMix(item.channel-1, 0, mixLine)
					model.deleteMix(item.channel-1, 1)
				end
			end
		end
	end
end

return { init=init, run=run, background=background}