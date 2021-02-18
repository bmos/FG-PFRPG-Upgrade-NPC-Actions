--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

--
--	SPELL ACTION REPLACEMENT FUNCTIONS
--

local function trim_spell_name(string_spell_name)
	local number_name_end = string.find(string_spell_name, '%(')
	string_spell_name = string_spell_name:sub(1, number_name_end)
	string_spell_name = string_spell_name:gsub('.+:', '')
	string_spell_name = string_spell_name:gsub(',.+', '')
	string_spell_name = string_spell_name:gsub('%[%a%]', '')
	string_spell_name = string_spell_name:gsub('%A+', '')
	string_spell_name = StringManager.trim(string_spell_name)
	if string.find(string_spell_name, 'greater') then
			string_spell_name = string_spell_name:gsub('greater', '') .. 'greater'
	end

	return string_spell_name
end

local function add_spell_descriptions(node_spell, node_spellset, nSpellLevel)
	local name_spell = string.lower(DB.getValue(node_spell, 'name') or '')
	local node_reference_spell = DB.findNode('spelldesc.' .. trim_spell_name(name_spell) .. '@PFRPG - Spellbook')
	if node_reference_spell and node_spell then
		if DB.getValue(node_spell, 'description', '') == '' then
			DB.deleteNode(node_spell.getChild('description'))
			local string_full_description = DB.getValue(node_reference_spell, 'description', '<p></p>')
			DB.setValue(node_spell, 'description_full', 'formattedtext', string_full_description)
			DB.setValue(node_spell, 'description', 'formattedtext', string_full_description)
			SpellManager.convertSpellDescToString(node_spell)
		end
	end
end

local function replace_effect_nodes(node_spell, node_spellset, nSpellLevel)
	local name_spell = string.lower(DB.getValue(node_spell, 'name') or '')
	local node_reference_spell = DB.findNode('spelldesc.' .. trim_spell_name(name_spell) .. '@PFRPG - Spellbook')
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
							add_spell_descriptions(nodeSpell, nodeSpellset, nSpellLevel)
						end
					end
				end
			end
		end
	end
end

--
--	MALADY LINKING FUNCTIONS
--

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

---	This function adds a link to matching creature maladies.
--	To work, it needs the malady node and npc node.
local function add_malady_link(node_malady, node_npc)
	local table_malady_npcs = string_to_table(DB.getValue(node_malady, 'npc')) or {}
	if table_malady_npcs ~= {} then
		for _,string_malady_linked_npc in pairs(table_malady_npcs) do
			local sDC = (string_malady_linked_npc:match(' %(DC %d+%)')) or ''
			string_malady_linked_npc = string_malady_linked_npc:gsub(' %(DC %d+%)', '')
			string_malady_linked_npc = string.lower(string_malady_linked_npc:gsub('%A', ''))
			local string_npc_name = DB.getValue(node_npc, 'name')
			if string_malady_linked_npc == string_npc_name then
				local string_description = DB.getValue(node_npc, 'text', '')
				local string_malady_name = DB.getValue(node_malady, 'name', '')
				local string_malady_link = '<linklist><link class="referencedisease" recordname="' .. DB.getPath(node_malady) .. '"><b>Malady: </b>' .. string_malady_name .. sDC .. '</link></linklist>'
				DB.setValue(node_npc, 'text', 'formattedtext', string_malady_link .. string_description)
			end
		end
	end
end

---	This function checks reference.diseases._ and disease._ for matching maladies.
--	It passes the appropriate nodes to the add_malady_link function.
--	It does nothing if the DiseaseTracker script isn't found.
local function search_for_maladies(node_npc)
	if DiseaseTracker then
		local string_npc_name = DB.getValue(node_npc, 'name')
		if string_npc_name then
			string_npc_name = string.lower(string_npc_name:gsub('%A+', ''))
			if DB.findNode('reference.diseases@*') then
				for _,node_malady in pairs(DB.findNode('reference.diseases@*').getChildren()) do
					add_malady_link(node_malady, node_npc)
				end
			end
			if DB.findNode('disease') then
				for _,node_malady in pairs(DB.findNode('disease').getChildren()) do
					add_malady_link(node_malady, node_npc)
				end
			end
		end
	end
end

---	This function checks NPCs for feats, traits, and/or special abilities.
local function hasSpecialAbility(nodeActor, sSearchString, bFeat, bTrait, bSpecialAbility, bDice)
	if not nodeActor then
		return false;
	end

	local sLowerSpecAbil = string.lower(sSearchString);
	local sSpecialQualities = string.lower(DB.getValue(nodeActor, '.specialqualities', ''));
	local sSpecAtks = string.lower(DB.getValue(nodeActor, '.specialattacks', ''));
	local sFeats = string.lower(DB.getValue(nodeActor, '.feats', ''));

	if bFeat and sFeats:match(sLowerSpecAbil, 1) then
		local nRank = tonumber(sFeats:match(sLowerSpecAbil .. ' (%d+)', 1))
		return true, (nRank or 1)
	elseif bDice and bSpecialAbility and (sSpecAtks:match(sLowerSpecAbil, 1) or sSpecialQualities:match(sLowerSpecAbil, 1)) then
		local sDice = sSpecAtks:match(sLowerSpecAbil .. ' (%(.+%))', 1) or sSpecialQualities:match(sLowerSpecAbil .. ' (%(.+%))', 1)
		return true, (sParenthetical or 1), sDice
	elseif bSpecialAbility and (sSpecAtks:match(sLowerSpecAbil, 1) or sSpecialQualities:match(sLowerSpecAbil, 1)) then
		local nRank = tonumber(sSpecAtks:match(sLowerSpecAbil .. ' (%d+)', 1) or sSpecialQualities:match(sLowerSpecAbil .. ' (%d+)', 1))
		return true, (nRank or 1)
	end

	return false
end

local function add_spell_node(nodeSource, nodeSpellClass, nLevel)
	-- Validate
	if not nodeSource or not nodeSpellClass or not nLevel then
		return nil;
	end
	
	-- Create the new spell entry
	local nodeTargetLevelSpells = nodeSpellClass.createChild("levels.level" .. nLevel .. ".spells");
	if not nodeTargetLevelSpells then
		return nil;
	end
	local nodeNewSpell = nodeTargetLevelSpells.createChild();
	if not nodeNewSpell then
		return nil;
	end
	
	-- Copy the spell details over
	DB.copyNode(nodeSource, nodeNewSpell);
	
	-- Convert the description field from module data
	SpellManager.convertSpellDescToString(nodeNewSpell);

	local nodeParent = nodeTargetLevelSpells.getParent();
	if nodeParent then
		-- If spell level not visible, then make it so.
		local sAvailablePath = "....available" .. nodeParent.getName();
		local nAvailable = DB.getValue(nodeTargetLevelSpells, sAvailablePath, 1);
		if nAvailable <= 0 then
			DB.setValue(nodeTargetLevelSpells, sAvailablePath, "number", 1);
		end
	end
	
	-- Parse spell details to create actions
	if DB.getChildCount(nodeNewSpell, "actions") == 0 then
		SpellManager.parseSpell(nodeNewSpell);
	elseif usingKelrugemExt() then											-- bmos adding Kel's tag parsing
		local nodeActions = nodeNewSpell.createChild("actions");
		if nodeActions then
			local nodeAction = nodeActions.getChildren();
			if nodeAction then
				for k, v in pairs(nodeAction) do
					if DB.getValue(v, "type") == "cast" then
						SpellManager.addTags(nodeNewSpell, v);
						DB.setValue(v, 'usereset', 'string', 'consumable')	-- bmos setting spell as consumable (no reset on rest)
					end
				end
			end
		end
	end
		
	return nodeNewSpell;
end

--
--	ACTION AUTOMATION FUNCTIONS
--

local function add_ability_automation(node_pc, string_ability_name, table_ability_information)
	if (
		not node_pc
		or string_ability_name == ""
		or not table_ability_information
		or table_ability_information == {}
		or table_ability_information['daily_uses'] < 0
		or table_ability_information['level'] < 0
		or table_ability_information['level'] > 9
		) then
			return
	end
	local node_spellset = node_pc.createChild("spellset")
	local node_spellclass = node_spellset.createChild()

	DB.setValue(node_spellclass, "label", "string", string_ability_name)
	DB.setValue(node_spellclass, "castertype", "string", "spontaneous")
	DB.setValue(node_spellclass, "availablelevel" .. table_ability_information['level'], "number", table_ability_information['daily_uses'])
	DB.setValue(node_spellclass, "cl", "number", 0)
	DB.setValue(node_pc, "spellmode", "string", "standard")
	local node_spell = add_spell_node(node_spellclass, table_ability_information['level'])

	return node_spell, node_spellclass
end

---	This function breaks down a table of abilities and searches for them in an NPC sheet.
--	The search result is provided by the hasSpecialAbility function.
--	If a match is found, it triggers the function hasSpecialAbility.
local function search_for_abilities(node_npc)
	local array_abilities = {
		['power attack'] = {
			['string_ability_type'] = 'feat',
			['level'] = 0,
			['daily_uses'] = 1,
			['effect-1'] = 'Power Attack-1H; ATK: -1 [-QBAB] ,melee; CMB: -1 [-QBAB] ,melee; DMG: 1 [QBAB] ,melee; DMG: 1 [QBAB] ,melee',
			['effect-2'] = 'Power Attack-2H; ATK: -1 [-QBAB] ,melee; CMB: -1 [-QBAB] ,melee; DMG: 1 [QBAB] ,melee; DMG: 1 [QBAB] ,melee; DMG: 1 [QBAB] ,melee'
			},
		['deadly aim'] = {
			['string_ability_type'] = 'feat',
			['level'] = 0,
			['daily_uses'] = 1,
			['effect-1'] = 'Deadly Aim; ATK: -1 [-QBAB] ,ranged; DMG: 1 [QBAB] ,ranged; DMG: 1 [QBAB] ,ranged'
			},
		['combat expertise'] = {
			['string_ability_type'] = 'feat',
			['level'] = 0,
			['daily_uses'] = 1,
			['effect-1'] = 'Combat Expertise; ATK: -1 [-QBAB] ,melee; CMB: -1 [-QBAB] ,melee; AC: 1 [QBAB] dodge'
			},
		['bleed'] = {
			['string_ability_type'] = 'special ability',
			['level'] = 0,
			['daily_uses'] = 1,
			['search_dice'] = true,
			['number_substitution'] = true,
			['effect-1'] = 'Bleed; DMGO: %n bleed'
			}
	}
	
	for string_ability_name, table_ability_information in pairs(array_abilities) do
		local is_feat, is_trait, is_special_ability = false, false, false
		if table_ability_information['string_ability_type'] == 'feat' then
			is_feat = true
		elseif table_ability_information['string_ability_type'] == 'trait' then
			is_trait = true
		elseif table_ability_information['string_ability_type'] == 'special ability' then
			is_special_ability = true
		end
		
		local is_match, string_parenthetical = hasSpecialAbility(node_npc, string_ability_name, is_feat, is_trait, is_special_ability) or false
		if is_match then
			local node_spell, node_spellclass = add_ability_automation(node_pc, string_ability_name, table_ability_information)
			Debug.chat('search_for_abilities', node_spell, node_spellclass)
		end
	end
end

--
--	UTILITY FUNCTIONS
--

---	This function is called when adding an NPC to the combat tracker.
--	It passes the call to the original addNPC function.
--	Once it receives the node, it performs replacement of actions.
local addNPC_old = nil -- placeholder for original addNPC function
local function addNPC_new(sClass, nodeNPC, sName)
	local nodeEntry = addNPC_old(sClass, nodeNPC, sName)
	if nodeEntry then
		replace_spell_effects(nodeEntry)
		search_for_maladies(nodeEntry)
		-- search_for_abilities(nodeEntry)
	end

	return nodeEntry
end

-- Function Overrides
function onInit()
	addNPC_old = CombatManager2.addNPC
	CombatManager.addNPC = addNPC_new
end

function onClose()
	CombatManager.addNPC = addNPC_old
end
