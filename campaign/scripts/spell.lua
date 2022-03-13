-- 
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

function onInit()
	if not windowlist.isReadOnly() then
		registerMenuItem(Interface.getString("menu_deletespell"), "delete", 6);
		registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);

		registerMenuItem(Interface.getString("menu_addspellaction"), "pointer", 3);
		registerMenuItem(Interface.getString("menu_addspellcast"), "radial_sword", 3, 2);
		registerMenuItem(Interface.getString("menu_addspelldamage"), "radial_damage", 3, 3);
		registerMenuItem(Interface.getString("menu_addspellheal"), "radial_heal", 3, 4);
		registerMenuItem(Interface.getString("menu_addspelleffect"), "radial_effect", 3, 5);
		
		registerMenuItem(Interface.getString("menu_reparsespell"), "textlist", 4);
	end

	-- Check to see if we should automatically parse spell description
	local nodeSpell = getDatabaseNode();
	local nParse = DB.getValue(nodeSpell, "parse", 0);
	if nParse ~= 0 then
		DB.setValue(nodeSpell, "parse", "number", 0);
		SpellManager.parseSpell(nodeSpell);
	end
	
	onDisplayChanged();
end

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

function onDisplayChanged()
	if minisheet then
		return;
	end
	
	local sDisplayMode = ""
	if DB and getDatabaseNode then
		sDisplayMode = DB.getValue(getDatabaseNode(), ".......spelldisplaymode", "");
	end

	if header and sDisplayMode == "action" then
		header.subwindow.shortdescription.setVisible(false);
		header.subwindow.actionsmini.setVisible(true);
		-- add compatibility with Zarestia's  Spell casting time labels extension
		-- adds display change so casting time not shown in summary display
		if header.subwindow.action_text_label and header.subwindow.components_text_label then
			header.subwindow.action_text_label.setVisible(true);
			if OptionsManager.isOption("SAIC", "on") then
				header.subwindow.components_text_label.setVisible(true);
			end
		end
	elseif header then
		header.subwindow.shortdescription.setVisible(true);
		header.subwindow.actionsmini.setVisible(false);
		-- add compatibility with Zarestia's  Spell casting time labels extension
		-- adds display change so casting time not shown in summary display
		if header.subwindow.action_text_label and header.subwindow.components_text_label then
			header.subwindow.action_text_label.setVisible(false);
			if OptionsManager.isOption("SAIC", "on") then
				header.subwindow.components_text_label.setVisible(false);
			end
		end
	end
end