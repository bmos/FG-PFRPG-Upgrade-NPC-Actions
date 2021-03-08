--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

--
--	SPELL ACTION REPLACEMENT FUNCTIONS
--

local function trim_spell_name(string_spell_name)
	-- remove anything after open parentheses
	local number_name_end = string.find(string_spell_name, '%(')
	string_spell_name = string_spell_name:sub(1, number_name_end)

	-- remove certain sets of characters
	string_spell_name = string_spell_name:gsub('%u%u%u%u', '')
	string_spell_name = string_spell_name:gsub('%u%u%u', '')
	string_spell_name = string_spell_name:gsub('AP%d+', '')
	string_spell_name = string_spell_name:gsub('%u%u', '')
	string_spell_name = string_spell_name:gsub('.+:', '')
	string_spell_name = string_spell_name:gsub(',.+', '')
	string_spell_name = string_spell_name:gsub('%[%a%]', '')
	string_spell_name = string_spell_name:gsub('%A+', '')

	-- remove extra spaces at beginning or end
	string_spell_name = StringManager.trim(string_spell_name)

	-- remove uppercase D or M at end of name
	number_name_end = string.find(string_spell_name, 'D', string.len(string_spell_name)) or string.find(string_spell_name, 'M', string.len(string_spell_name))
	if number_name_end then string_spell_name = string_spell_name:sub(1, number_name_end - 1) end

	-- convert to lower-case
	string_spell_name = string_spell_name:lower()

	-- move "greater" to the end in case it's at the beginning
	if string.find(string_spell_name, 'greater') then
		string_spell_name = string_spell_name:gsub('greater', '') .. 'greater'
	end

	return string_spell_name
end

local function replace_effect_nodes(node_spell, node_spellset, number_spell_level, string_name_spell, node_reference_spell)
	if node_reference_spell then
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
			local node_spell_new = SpellManager.addSpell(node_actions_reference_spell.getParent(), node_spellset, number_spell_level)
			DB.setValue(node_spell_new, 'prepared', 'number', prepared_count)
			DB.setValue(node_spell_new, 'name', 'string', name_spell)
			
			return node_spell_new
		end
	end
end

local function add_spell_description(node_spell, string_name_spell, node_reference_spell)
	if node_reference_spell and node_spell then
		if DB.getValue(node_spell, 'description', '') == '' or DB.getValue(node_spell, 'description', '') == '<p></p>' then
			DB.deleteNode(node_spell.getChild('description'))
			local string_full_description = DB.getValue(node_reference_spell, 'description', '<p></p>')
			DB.setValue(node_spell, 'description_full', 'formattedtext', string_full_description)
			DB.setValue(node_spell, 'description', 'formattedtext', string_full_description)
			SpellManager.convertSpellDescToString(node_spell)
		end
	end
end

local function add_spell_information(node_spell, string_name_spell, node_reference_spell)
	if node_reference_spell and node_spell then
		for _,node_reference_spell_subnode in pairs(node_reference_spell.getChildren()) do
			local string_node_name = node_reference_spell_subnode.getName()
			if string_node_name ~= 'description' and string_node_name ~= 'name' then
				if not node_spell.getChild(string_node_name) then
					local string_node_type = node_reference_spell_subnode.getType()
					local node_spell_subnode = node_spell.createChild(string_node_name, string_node_type)
					DB.copyNode(node_reference_spell_subnode, node_spell_subnode)
				end
			end
		end
	end
end

local function replace_spell_effects(nodeEntry)
	if nodeEntry.getChild('spellset') then
		for _,nodeSpellset in pairs(nodeEntry.getChild('spellset').getChildren()) do
			if nodeSpellset.getChild('levels') then
				for _,nodeSpellLevel in pairs(nodeSpellset.getChild('levels').getChildren()) do
					local number_spell_level = tonumber(nodeSpellLevel.getName():gsub('level', '') or 0)
					if nodeSpellLevel.getChild('spells') and number_spell_level then
						for _,nodeSpell in pairs(nodeSpellLevel.getChild('spells').getChildren()) do
							local string_name_spell = trim_spell_name(DB.getValue(nodeSpell, 'name')) or ''
							local node_reference_spell = DB.findNode('spelldesc.' .. string_name_spell .. '@PFRPG - Spellbook')
							local nodeNewSpell = replace_effect_nodes(nodeSpell, node_spellset, number_spell_level, string_name_spell, node_reference_spell)
							if nodeNewSpell then nodeSpell = nodeNewSpell end
							add_spell_description(nodeSpell, string_name_spell, node_reference_spell)
							add_spell_information(nodeSpell, string_name_spell, node_reference_spell)
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

--
--	ACTION AUTOMATION FUNCTIONS
--

local function add_ability_automation(node_npc, string_ability_name, table_ability_information, number_rank)
	if (
		not node_npc
		or string_ability_name == ''
		or not table_ability_information
		or table_ability_information == {}
		or (table_ability_information['daily_uses'] and table_ability_information['daily_uses'] < 0)
		or table_ability_information['level'] < 0
		or table_ability_information['level'] > 9
		or not table_ability_information['actions']
		) then
			return
	end

	local node_spellset = node_npc.createChild('spellset')
	local node_spellclass = node_spellset.createChild(table_ability_information['string_ability_type'] or 'Abilities')
	local node_spelllevel = node_spellclass.createChild('levels').createChild('level' .. table_ability_information['level'])
	local node_ability = node_spelllevel.createChild('spells').createChild()

	DB.setValue(node_spellclass, 'label', 'string', table_ability_information['string_ability_type'])
	DB.setValue(node_spellclass, 'castertype', 'string', 'spontaneous')
	DB.setValue(node_spellclass, 'availablelevel' .. table_ability_information['level'], 'number', table_ability_information['daily_uses'] or 1)
	DB.setValue(node_spellclass, 'cl', 'number', 0)
	DB.setValue(node_spelllevel, 'level', 'number', table_ability_information['level'])

	DB.setValue(node_ability, 'name', 'string', string_ability_name)
	local node_actions = node_ability.createChild('actions')
	for string_name_action,table_action_information in pairs(table_ability_information['actions']) do
		local node_action = node_actions.createChild(string_name_action)
		for string_node_name,table_node_info in pairs(table_action_information) do
			if string_node_name == 'damagelist' or string_node_name == 'heallist' then
				for string_damage_name,table_damage_information in pairs(table_node_info) do
					local node_damage = node_action.createChild(string_node_name).createChild(string_damage_name)
					for string_damagenode_name,table_damagenode_info in pairs(table_damage_information) do
						if table_damagenode_info['type'] and table_damagenode_info['value'] then
							if table_damagenode_info['tiermultiplier'] then
								if table_damagenode_info['type'] == 'string' then
									local string_result = string.format(table_damagenode_info['value'], (table_damagenode_info['tiermultiplier'] * (number_rank or 1)))
									DB.setValue(node_damage, string_damagenode_name, table_damagenode_info['type'], string_result)
								elseif table_damagenode_info['type'] == 'number' then
									local number_result = table_damagenode_info['value'] * (table_damagenode_info['tiermultiplier'] * (number_rank or 1))
									DB.setValue(node_damage, string_damagenode_name, table_damagenode_info['type'], number_result)
								end
							else
								DB.setValue(node_damage, string_damagenode_name, table_damagenode_info['type'], table_damagenode_info['value'])
							end
						end
					end
				end
			else
				if table_node_info['type'] and table_node_info['value'] then
					if table_node_info['tiermultiplier'] then
						local result = string.format(table_node_info['value'], (table_node_info['tiermultiplier'] * (number_rank or 1)))
						DB.setValue(node_action, string_node_name, table_node_info['type'], result)
					else
						DB.setValue(node_action, string_node_name, table_node_info['type'], table_node_info['value'])
					end
				end
			end
		end
	end
end

---	This function checks NPCs for feats, traits, and/or special abilities.
local function hasSpecialAbility(nodeActor, sSearchString, bFeat, bTrait, bSpecialAbility, bDice)
	if not nodeActor or not sSearchString or (not bFeat and not bTrait and not bSpecialAbility) then
		return false;
	end

	local sLowerSpecAbil = string.lower(sSearchString);
	local sSpecialQualities = string.lower(DB.getValue(nodeActor, '.specialqualities', ''));
	local sSpecAtks = string.lower(DB.getValue(nodeActor, '.specialattacks', ''));
	local sFeats = string.lower(DB.getValue(nodeActor, '.feats', ''));

	if bFeat and sFeats:match(sLowerSpecAbil, 1) then
		local nRank = tonumber(sFeats:match(sLowerSpecAbil .. ' (%d+)', 1))
		local sParenthetical = sSpecAtks:match(sLowerSpecAbil .. ' %((.+)%)', 1) or sFeats:match(sLowerSpecAbil .. ' %((.+)%)', 1)
		return true, (nRank or 1), sParenthetical
	elseif bSpecialAbility and (sSpecAtks:match(sLowerSpecAbil, 1) or sSpecialQualities:match(sLowerSpecAbil, 1)) then
		local nRank = tonumber(sSpecAtks:match(sLowerSpecAbil .. ' (%d+)', 1) or sSpecialQualities:match(sLowerSpecAbil .. ' (%d+)', 1))
		local sParenthetical = sSpecAtks:match(sLowerSpecAbil .. ' %((.+)%)', 1) or sSpecialQualities:match(sLowerSpecAbil .. ' %((.+)%)', 1)
		return true, (nRank or 1), sParenthetical
	end
end

---	This function breaks down a table of abilities and searches for them in an NPC sheet.
--	The search result is provided by the hasSpecialAbility function.
--	If a match is found, it triggers the function hasSpecialAbility.
local function search_for_abilities(node_npc)
	local array_abilities = {
		['Ancestral Enmity'] = {
			['string_ability_type'] = 'Feats',
			['level'] = 0,
			['actions'] = {
				['zeffect-1'] = {
					['label'] = { ['type'] = 'string', ['value'] = ('Ancestral Enmity; IFT: TYPE(gnome); ATK: %d'), ['tiermultiplier'] = 2 },
					['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
					['type'] = { ['type'] = 'string', ['value'] = 'effect' },
				},
				['zeffect-2'] = {
					['label'] = { ['type'] = 'string', ['value'] = 'Ancestral Enmity; IFT: TYPE(dwarf); ATK: %d', ['tiermultiplier'] = 2 },
					['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
					['type'] = { ['type'] = 'string', ['value'] = 'effect' },
				},
			},
		},
		['Arcane Strike'] = {
			['string_ability_type'] = 'Feats',
			['level'] = 0,
			['actions'] = {
				['zeffect-1'] = {
					['dmaxstat'] = { ['type'] = 'number', ['value'] = 4 },
					['durmod'] = { ['type'] = 'number', ['value'] = 1 },
					['durmult'] = { ['type'] = 'number', ['value'] = .25 },
					['durstat'] = { ['type'] = 'string', ['value'] = 'cl' },
					['durunit'] = { ['type'] = 'string', ['value'] = 'round' },
					['label'] = { ['type'] = 'string', ['value'] = ('Arcane Strike; DMG: 1; DMGTYPE: magic') },
					['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
					['type'] = { ['type'] = 'string', ['value'] = 'effect' },
				},
			},
		},
		['Breath Weapon'] = {
			['string_ability_type'] = 'Special Abilities',
			['level'] = 0,
			['actions'] = {
				['zcast-1'] = {
					['onmissdamage'] = { ['type'] = 'string', ['value'] = 'half' },
					['savedcmod'] = { ['type'] = 'number', ['value'] = 20 },
					['savedctype'] = { ['type'] = 'string', ['value'] = 'fixed' },
					['savetype'] = { ['type'] = 'string', ['value'] = 'reflex' },
					['type'] = { ['type'] = 'string', ['value'] = 'cast' },
				},
				['zdamage-1'] = {
					['damagelist'] = {
						['damage-001'] = {
							['dice'] = { ['type'] = 'dice', ['value'] = '8d6' },
							['type'] = { ['type'] = 'string', ['value'] = 'fire' },
						},
					},
					['dmgnotspell'] = { ['type'] = 'number', ['value'] = 1 },
					['type'] = { ['type'] = 'string', ['value'] = 'damage' },
				},
				['zeffect-1'] = {
					['durdice'] = { ['type'] = 'dice', ['value'] = 'd4' },
					['durunit'] = { ['type'] = 'string', ['value'] = 'round' },
					['label'] = { ['type'] = 'string', ['value'] = ('Breath Weapon Recharge') },
					['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
					['type'] = { ['type'] = 'string', ['value'] = 'effect' },
				},
			},
		},
		['Bleed'] = {
			['string_ability_type'] = 'Special Abilities',
			['level'] = 0,
			['search_dice'] = true,
			['number_substitution'] = true,
			['actions'] = {
				['zeffect-1'] = {
					['durunit'] = { ['type'] = 'string', ['value'] = 'round' },
					['label'] = { ['type'] = 'string', ['value'] = 'Bleed; DMGO: %n bleed' },
					['type'] = { ['type'] = 'string', ['value'] = 'effect' },
				},
			},
		},
		['Combat Expertise'] = {
			['string_ability_type'] = 'Feats',
			['level'] = 0,
			['actions'] = {
				['zeffect-1'] = {
					['durunit'] = { ['type'] = 'string', ['value'] = 'round' },
					['label'] = { ['type'] = 'string', ['value'] = 'Combat Expertise; ATK: -1 [-QBAB] ,melee; AC: 1 [QBAB] dodge' },
					['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
					['type'] = { ['type'] = 'string', ['value'] = 'effect' },
				},
			},
		},
		['Deadly Aim'] = {
			['string_ability_type'] = 'Feats',
			['level'] = 0,
			['actions'] = {
				['zeffect-1'] = {
					['durunit'] = { ['type'] = 'string', ['value'] = 'round' },
					['label'] = { ['type'] = 'string', ['value'] = 'Deadly Aim; ATK: -1 [-QBAB] ,ranged; DMG: 1 [QBAB] ,ranged; DMG: 1 [QBAB] ,ranged' },
					['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
					['type'] = { ['type'] = 'string', ['value'] = 'effect' },
				},
			},
		},
		['Furious Focus'] = {
			['string_ability_type'] = 'Feats',
			['level'] = 0,
			['actions'] = {
				['zeffect-1'] = {
					['apply'] = { ['type'] = 'string', ['value'] = 'roll' },
					['label'] = { ['type'] = 'string', ['value'] = 'Furious Focus; IF: CUSTOM(Power Attack 2-H); ATK: 1 [QBAB] ,melee' },
					['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
					['type'] = { ['type'] = 'string', ['value'] = 'effect' },
				},
			},
		},
		['Mobility'] = {
			['string_ability_type'] = 'Feats',
			['level'] = 0,
			['actions'] = {
				['zeffect-1'] = {
					['label'] = { ['type'] = 'string', ['value'] = 'Mobility; AC: 4 ,opportunity; IF: CUSTOM(Flat-footed); AC: -4 ,opportunity' },
					['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
					['type'] = { ['type'] = 'string', ['value'] = 'effect' },
				},
			},
		},
		['Power Attack'] = {
			['string_ability_type'] = 'Feats',
			['level'] = 0,
			['actions'] = {
				['zeffect-1'] = {
					['label'] = { ['type'] = 'string', ['value'] = 'Power Attack 1-H; ATK: -1 [-QBAB] ,melee; DMG: 1 [QBAB] ,melee; DMG: 1 [QBAB] ,melee' },
					['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
					['type'] = { ['type'] = 'string', ['value'] = 'effect' },
				},
				['zeffect-2'] = {
					['label'] = { ['type'] = 'string', ['value'] = 'Power Attack 2-H; ATK: -1 [-QBAB] ,melee; DMG: 1 [QBAB] ,melee; DMG: 1 [QBAB] ,melee; DMG: 1 [QBAB] ,melee' },
					['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
					['type'] = { ['type'] = 'string', ['value'] = 'effect' },
				},
			},
		},
	}
	
	for string_ability_name, table_ability_information in pairs(array_abilities) do
		local is_feat, is_trait, is_special_ability
		if table_ability_information['string_ability_type'] == 'Feats' then
			is_feat = true
		elseif table_ability_information['string_ability_type'] == 'Traits' then
			is_trait = true
		elseif table_ability_information['string_ability_type'] == 'Special Abilities' then
			is_special_ability = true
		end
		
		local is_match, number_rank, string_parenthetical = hasSpecialAbility(node_npc, string_ability_name, is_feat, is_trait, is_special_ability)
		if is_match then
			add_ability_automation(node_npc, string_ability_name, table_ability_information, number_rank, string_parenthetical)
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
		search_for_abilities(nodeEntry)
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
