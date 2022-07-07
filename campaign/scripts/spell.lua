--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--
--	luacheck: globals onMenuSelection
function onMenuSelection(selection, subselection, ...)
	if super and super.onMenuSelection and selection ~= 4 then
		super.onMenuSelection(selection, subselection, ...)
	elseif getDatabaseNode then
		SpellManager.parseSpell(getDatabaseNode());
		-- activatedetail.setValue(1); -- remove line to keep script error away
	end
end

--	luacheck: globals onDisplayChanged
function onDisplayChanged()
	-- luacheck: globals minisheet
	if minisheet then return; end

	local sDisplayMode = ''
	if DB and getDatabaseNode then sDisplayMode = DB.getValue(getDatabaseNode(), '.......spelldisplaymode', ''); end

	if header and sDisplayMode == 'action' then
		header.subwindow.shortdescription.setVisible(false);
		header.subwindow.actionsmini.setVisible(true);
		-- add compatibility with Zarestia's  Spell casting time labels extension
		-- adds display change so casting time not shown in summary display
		if header.subwindow.action_text_label and header.subwindow.components_text_label then
			header.subwindow.action_text_label.setVisible(true);
			if OptionsManager.isOption('SAIC', 'on') then header.subwindow.components_text_label.setVisible(true); end
		end
	elseif header then
		header.subwindow.shortdescription.setVisible(true);
		header.subwindow.actionsmini.setVisible(false);
		-- add compatibility with Zarestia's  Spell casting time labels extension
		-- adds display change so casting time not shown in summary display
		if header.subwindow.action_text_label and header.subwindow.components_text_label then
			header.subwindow.action_text_label.setVisible(false);
			if OptionsManager.isOption('SAIC', 'on') then header.subwindow.components_text_label.setVisible(false); end
		end
	end
end

function onInit()
	if super and super.onInit then super.onInit() end

	onDisplayChanged();
end
