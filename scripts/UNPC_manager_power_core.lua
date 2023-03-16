--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

--	luacheck: globals onDefaultPowerMenuSelection
function onDefaultPowerMenuSelection(w, selection, subselection)
	if selection == 6 and subselection == 7 then
		DB.deleteNode(w.getDatabaseNode())
	elseif selection == 4 then
		PowerManagerCore.parsePower(w.getDatabaseNode())
		if type(w) ~= 'error' and w.activatedetail then
			w.activatedetail.setValue(1) -- remove line to keep script error away
		end
	elseif selection == 3 then
		local tTypes = PowerActionManagerCore.getSortedActionTypes()
		local nBaseIndex = PowerManagerCore.getDefaultPowerMenuBaseIndex(tTypes)
		local nActionIndex = ((subselection - nBaseIndex) % 8) + 1
		local sType = tTypes[nActionIndex]
		if sType then PowerManagerCore.createPowerAction(w, sType) end
	end
end

function onInit() PowerManagerCore.onDefaultPowerMenuSelection = onDefaultPowerMenuSelection end
