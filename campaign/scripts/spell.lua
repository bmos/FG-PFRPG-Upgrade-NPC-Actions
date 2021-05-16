-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		getDatabaseNode().delete();
	elseif selection == 4 then
		SpellManager.parseSpell(getDatabaseNode());
		-- bmos removing this line to keep script error away
		-- activatedetail.setValue(1);
	elseif selection == 3 then
		if subselection == 2 then
			createAction("cast");
			activatedetail.setValue(1);
		elseif subselection == 3 then
			createAction("damage");
			activatedetail.setValue(1);
		elseif subselection == 4 then
			createAction("heal");
			activatedetail.setValue(1);
		elseif subselection == 5 then
			createAction("effect");
			activatedetail.setValue(1);
		end
	end
end