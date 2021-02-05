--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

local function trim_spell_name(string_spell_name)
	local number_name_end = string.find(string_spell_name, '%(')
	string_spell_name = string_spell_name:sub(1, number_name_end)
	string_spell_name = string_spell_name:gsub('.+:', '')
	string_spell_name = string_spell_name:gsub(',.+', '')
	string_spell_name = string_spell_name:gsub('%A+', '')
	string_spell_name = StringManager.trim(string_spell_name)
	if string.find(string_spell_name, 'greater') then
			string_spell_name = string_spell_name:gsub('greater', '') .. 'greater'
	end

	return string_spell_name
end

local function get_reference_spell(string_spell_name)
		return DB.findNode('spelldesc.' .. trim_spell_name(string_spell_name) .. '@PFRPG - Spellbook')
end

---	This function converts a string of values separated by semicolons to a table
--	@param s input, a string of values separated by semicolons
--	@return t output, an indexed table of values
local function string_to_table(string_input)
	if (not string_input or string_input == '') then
		return {}
	end

	string_input = string_input .. ';'        -- ending semicolon
	local table_output = {}        -- table to collect fields
	local number_field_start = 1
	repeat
		local number_nexti = string.find(string_input, ';', number_field_start)
		table.insert(table_output, string.sub(string_input, number_field_start, number_nexti-1))
		number_field_start = number_nexti + 1
	until number_field_start > string.len(string_input)

	return table_output
end

local function replace_effect_nodes(node_spell, node_spellset, nSpellLevel)
	local name_spell = string.lower(DB.getValue(node_spell, 'name') or '')
	local node_reference_spell = get_reference_spell(name_spell)
	if not node_reference_spell then return; end
	local node_actions_reference_spell = node_reference_spell.getChild('actions')
	local node_actions_npc_spell = node_spell.getChild('actions')
	if node_actions_reference_spell and node_actions_npc_spell then
		for _,nodeAction in pairs(node_actions_npc_spell.getChildren()) do
			local sType = string.lower(DB.getValue(nodeAction, 'type', ''))
			if sType ~= 'cast' then
				DB.deleteNode(nodeAction)
			end
		end
		for _,node_action in pairs(node_actions_reference_spell.getChildren()) do
			local sType = string.lower(DB.getValue(node_action, 'type', ''))
			if sType ~= 'cast' then
				DB.copyNode(node_action, node_actions_npc_spell.createChild())
			end
		end
	elseif node_actions_reference_spell then
		local prepared_count = DB.getValue(node_spell, 'prepared', 0)
		DB.deleteNode(node_spell)
		local node_spell_new = SpellManager.addSpell(node_actions_reference_spell.getParent(), node_spellset, nSpellLevel)
		DB.setValue(node_spell_new, 'prepared', 'number', prepared_count)
		DB.setValue(node_spell_new, 'name', 'string', name_spell)
	end
end

local function replace_spell_effects(nodeEntry)
	if nodeEntry.getChild('spellset') then
		for _,nodeSpellset in pairs(nodeEntry.getChild('spellset').getChildren()) do
			if nodeSpellset.getChild('levels') then
				for _,nodeSpellLevel in pairs(nodeSpellset.getChild('levels').getChildren()) do
					local nSpellLevel = tonumber(nodeSpellLevel.getName():gsub('level', '') or 0)
					if nodeSpellLevel.getChild('spells') and nSpellLevel then
						for _,nodeSpell in pairs(nodeSpellLevel.getChild('spells').getChildren()) do
							replace_effect_nodes(nodeSpell, nodeSpellset, nSpellLevel)
						end
					end
				end
			end
		end
	end
end

local function add_malady_link(node_malady, node_npc, string_npc_name)
	local table_malady_npcs = string_to_table(DB.getValue(node_malady, 'npc')) or {}
	if table_malady_npcs ~= {} then
		for _,string_malady_linked_npc in pairs(table_malady_npcs) do
			local sDC = (string_malady_linked_npc:match(' %(DC %d+%)')) or ''
			string_malady_linked_npc = string_malady_linked_npc:gsub(' %(DC %d+%)', '')
			string_malady_linked_npc = string.lower(string_malady_linked_npc:gsub('%A', ''))
			if string_malady_linked_npc == string_npc_name then
				local string_description = DB.getValue(node_npc, 'text', '')
				local string_malady_name = DB.getValue(node_malady, 'name', '')
				local string_malady_link = '<linklist><link class="referencedisease" recordname="' .. DB.getPath(node_malady) .. '"><b>Malady: </b>' .. string_malady_name .. sDC .. '</link></linklist>'
				DB.setValue(node_npc, 'text', 'formattedtext', string_malady_link .. string_description)
			end
		end
	end
end

local function search_for_maladies(node_npc)
	if DiseaseTracker then
		local string_npc_name = DB.getValue(node_npc, 'name')
		if string_npc_name then
			string_npc_name = string.lower(string_npc_name:gsub('%A+', ''))
			if DB.findNode('reference.diseases@*') then
				for _,node_malady in pairs(DB.findNode('reference.diseases@*').getChildren()) do
					add_malady_link(node_malady, node_npc, string_npc_name)
				end
			end
			if DB.findNode('disease') then
				for _,node_malady in pairs(DB.findNode('disease').getChildren()) do
					add_malady_link(node_malady, node_npc, string_npc_name)
				end
			end
		end
	end
end

---	This function is called when adding an encounter to the combat tracker.
--	This function is modified from the SmiteWorks original.
--	Lines added or modified will have at least "--bmos" as a comment
local function addBattle_new(nodeBattle)
	local aModulesToLoad = {};
	local sTargetNPCList = LibraryData.getCustomData("battle", "npclist") or "npclist";
	for _, vNPCItem in pairs(DB.getChildren(nodeBattle, sTargetNPCList)) do
		local sClass, sRecord = DB.getValue(vNPCItem, "link", "", "");
		if sRecord ~= "" then
			local nodeNPC = DB.findNode(sRecord);
			if not nodeNPC then
				local sModule = sRecord:match("@(.*)$");
				if sModule and sModule ~= "" and sModule ~= "*" then
					if not StringManager.contains(aModulesToLoad, sModule) then
						table.insert(aModulesToLoad, sModule);
					end
				end
			end
		end
		for _,vPlacement in pairs(DB.getChildren(vNPCItem, "maplink")) do
			local sClass, sRecord = DB.getValue(vPlacement, "imageref", "", "");
			if sRecord ~= "" then
				local nodeImage = DB.findNode(sRecord);
				if not nodeImage then
					local sModule = sRecord:match("@(.*)$");
					if sModule and sModule ~= "" and sModule ~= "*" then
						if not StringManager.contains(aModulesToLoad, sModule) then
							table.insert(aModulesToLoad, sModule);
						end
					end
				end
			end
		end
	end
	if #aModulesToLoad > 0 then
		local wSelect = Interface.openWindow("module_dialog_missinglink", "");
		wSelect.initialize(aModulesToLoad, CombatManager.onBattleNPCLoadCallback, { nodeBattle = nodeBattle });
		return;
	end

	if CombatManager.fCustomAddBattle then
		return CombatManager.fCustomAddBattle(nodeBattle);
	end

	-- Cycle through the NPC list, and add them to the tracker
	for _, vNPCItem in pairs(DB.getChildren(nodeBattle, sTargetNPCList)) do
		-- Get link database node
		local nodeNPC = nil;
		local sClass, sRecord = DB.getValue(vNPCItem, "link", "", "");
		if sRecord ~= "" then
			nodeNPC = DB.findNode(sRecord);
		end
		local sName = DB.getValue(vNPCItem, "name", "");

		if nodeNPC then
			local aPlacement = {};
			for _,vPlacement in pairs(DB.getChildren(vNPCItem, "maplink")) do
				local rPlacement = {};
				local _, sRecord = DB.getValue(vPlacement, "imageref", "", "");
				rPlacement.imagelink = sRecord;
				rPlacement.imagex = DB.getValue(vPlacement, "imagex", 0);
				rPlacement.imagey = DB.getValue(vPlacement, "imagey", 0);
				table.insert(aPlacement, rPlacement);
			end

			local nCount = DB.getValue(vNPCItem, "count", 0);
			for i = 1, nCount do
				local nodeEntry = CombatManager.addNPC(sClass, nodeNPC, sName);
				if nodeEntry then
					replace_spell_effects(nodeEntry)	-- bmos replacing spell effects
					search_for_maladies(nodeEntry)		-- bmos adding automatic disease addition for DiseaseTracker
					local sFaction = DB.getValue(vNPCItem, "faction", "");
					if sFaction ~= "" then
						DB.setValue(nodeEntry, "friendfoe", "string", sFaction);
					end
					local sToken = DB.getValue(vNPCItem, "token", "");
					if sToken == "" or not Interface.isToken(sToken) then
						local sLetter = StringManager.trim(sName):match("^([a-zA-Z])");
						if sLetter then
							sToken = "tokens/Medium/" .. sLetter:lower() .. ".png@Letter Tokens";
						else
							sToken = "tokens/Medium/z.png@Letter Tokens";
						end
					end
					if sToken ~= "" then
						DB.setValue(nodeEntry, "token", "token", sToken);

						if aPlacement[i] and aPlacement[i].imagelink ~= "" then
							TokenManager.setDragTokenUnits(DB.getValue(nodeEntry, "space"));
							local tokenAdded = Token.addToken(aPlacement[i].imagelink, sToken, aPlacement[i].imagex, aPlacement[i].imagey);
							TokenManager.endDragTokenWithUnits(nodeEntry);
							if tokenAdded then
								TokenManager.linkToken(nodeEntry, tokenAdded);
							end
						end
					end

					-- Set identification state from encounter record, and disable source link to prevent overriding ID for existing CT entries when identification state changes
					local sSourceClass,sSourceRecord = DB.getValue(nodeEntry, "sourcelink", "", "");
					DB.setValue(nodeEntry, "sourcelink", "windowreference", "", "");
					DB.setValue(nodeEntry, "isidentified", "number", DB.getValue(vNPCItem, "isidentified", 1));
					DB.setValue(nodeEntry, "sourcelink", "windowreference", sSourceClass, sSourceRecord);
				else
					ChatManager.SystemMessage(Interface.getString("ct_error_addnpcfail") .. " (" .. sName .. ")");
				end
			end
		else
			ChatManager.SystemMessage(Interface.getString("ct_error_addnpcfail2") .. " (" .. sName .. ")");
		end
	end

	Interface.openWindow("combattracker_host", "combattracker");
end

local addBattle_old = nil

-- Function Overrides
function onInit()
	addBattle_old = CombatManager.addBattle
	CombatManager.addBattle = addBattle_new
end

function onClose()
	CombatManager.addBattle = addBattle_old
end
