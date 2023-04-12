--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

--	luacheck: globals onDefaultPowerMenuSelection_new
local onDefaultPowerMenuSelection_old
function onDefaultPowerMenuSelection_new(w, selection, subselection, ...)
	if selection ~= 4 then return onDefaultPowerMenuSelection_old(w, selection, subselection, ...) end

	PowerManagerCore.parsePower(w.getDatabaseNode())
	if type(w) ~= 'error' and w.activatedetail then
		w.activatedetail.setValue(1);
	end
end

function onInit()
	onDefaultPowerMenuSelection_old = PowerManagerCore.onDefaultPowerMenuSelection
	PowerManagerCore.onDefaultPowerMenuSelection = onDefaultPowerMenuSelection_new
end
