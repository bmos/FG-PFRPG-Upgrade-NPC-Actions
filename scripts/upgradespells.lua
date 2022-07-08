--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--
--
--	SPELL ACTION REPLACEMENT FUNCTIONS
--
local function trim_spell_name(string_spell_name)
	local string_spell_name_lower = string_spell_name:lower()
	local is_greater = (string.find(string_spell_name_lower, ', greater') ~= nil)
	local is_lesser = (string.find(string_spell_name_lower, ', lesser') ~= nil)
	local is_communal = (string.find(string_spell_name_lower, ', communal') ~= nil)
	local is_mass = (string.find(string_spell_name_lower, ', mass') ~= nil)
	local is_maximized = (string.find(string_spell_name_lower, 'maximized') ~= nil)
	local is_empowered = (string.find(string_spell_name_lower, 'empowered') ~= nil)
	local is_quickened = (string.find(string_spell_name_lower, 'quickened') ~= nil)

	-- remove tags from spell name
	if is_greater then
		string_spell_name = string_spell_name:gsub(', greater', '')
		string_spell_name = string_spell_name:gsub(', Greater', '')
	end
	if is_lesser then
		string_spell_name = string_spell_name:gsub(', lesser', '')
		string_spell_name = string_spell_name:gsub(', Lesser', '')
	end
	if is_communal then
		string_spell_name = string_spell_name:gsub(', communal', '')
		string_spell_name = string_spell_name:gsub(', Communal', '')
	end
	if is_mass then
		string_spell_name = string_spell_name:gsub(', mass', '')
		string_spell_name = string_spell_name:gsub(', Mass', '')
	end
	if is_maximized then
		string_spell_name = string_spell_name:gsub('maximized', '')
		string_spell_name = string_spell_name:gsub('Maximized', '')
	end
	if is_empowered then
		string_spell_name = string_spell_name:gsub('empowered', '')
		string_spell_name = string_spell_name:gsub('Empowered', '')
	end
	if is_quickened then
		string_spell_name = string_spell_name:gsub('quickened', '')
		string_spell_name = string_spell_name:gsub('Quickened', '')
	end

	-- remove certain sets of characters
	string_spell_name = string_spell_name:gsub('%u%u%u%u', '')
	string_spell_name = string_spell_name:gsub('%u%u%u', '')
	string_spell_name = string_spell_name:gsub('AP%d+', '')
	string_spell_name = string_spell_name:gsub('%u%u', '')
	string_spell_name = string_spell_name:gsub('.+:', '')
	string_spell_name = string_spell_name:gsub(',.+', '')
	string_spell_name = string_spell_name:gsub('%[.-%]', '')
	string_spell_name = string_spell_name:gsub('%(.-%)', '')
	string_spell_name = string_spell_name:gsub('%A+', '')

	-- remove uppercase D or M at end of name
	local number_name_end = (string_spell_name:find('D', string.len(string_spell_name)) or
					                        string_spell_name:find('M', string.len(string_spell_name)))
	if number_name_end then string_spell_name = string_spell_name:sub(1, number_name_end - 1) end

	-- convert to lower-case
	string_spell_name = string_spell_name:lower()

	-- append relevant tags to end of spell name
	if is_greater then string_spell_name = string_spell_name .. 'greater' end
	if is_lesser then string_spell_name = string_spell_name .. 'lesser' end
	if is_communal then string_spell_name = string_spell_name .. 'communal' end
	if is_mass then string_spell_name = string_spell_name .. 'mass' end

	return string_spell_name, is_maximized, is_empowered
end

local function replace_action_nodes(node_spell, node_spellset, number_spell_level, node_reference_spell, is_maximized, is_empowered)
	if node_reference_spell then
		if node_reference_spell.getChild('actions') then
			local string_spell_name = DB.getValue(node_spell, 'name', 0)
			local number_cast = DB.getValue(node_spell, 'cast', 0)
			local number_prepared = DB.getValue(node_spell, 'prepared', 0)

			DB.deleteNode(node_spell)
			local node_spell_new = SpellManager.addSpell(node_reference_spell, node_spellset, number_spell_level)
			DB.setValue(node_spell_new, 'cast', 'number', number_cast)
			DB.setValue(node_spell_new, 'prepared', 'number', number_prepared)
			DB.setValue(node_spell_new, 'name', 'string', string_spell_name)

			-- set up metamagic if applicable
			local node_spell_new_damage = node_spell_new.getChild('actions').getChild('damage')
			if node_spell_new_damage then
				if is_empowered then DB.setValue(node_spell_new_damage, 'meta', 'string', 'empower') end
				if is_maximized then DB.setValue(node_spell_new_damage, 'meta', 'string', 'maximize') end
			end

			return node_spell_new
		end
	end
end

local function add_spell_description(node_spell, node_reference_spell)
	if node_reference_spell and node_spell then
		if DB.getValue(node_spell, 'description', '') == '' or DB.getValue(node_spell, 'description', '') == '<p></p>' then
			DB.deleteNode(node_spell.createChild('description'))
			local string_full_description = DB.getValue(node_reference_spell, 'description', '<p></p>')
			DB.setValue(node_spell, 'description_full', 'formattedtext', string_full_description)
			DB.setValue(node_spell, 'description', 'formattedtext', string_full_description)
			SpellManager.convertSpellDescToString(node_spell)
		end
	end
end

local function add_spell_information(node_spell, node_reference_spell)
	if node_reference_spell and node_spell then
		for _, node_reference_spell_subnode in pairs(node_reference_spell.getChildren()) do
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

local function replace_spell_actions(node_spell)
	local string_spell_name, is_maximized, is_empowered = trim_spell_name(DB.getValue(node_spell, 'name'))

	local array_modules = {
		['SpellbookExtended'] = { ['name'] = '@PFRPG - Spellbook Extended', ['prefix'] = 'spelldesc.' },
		['Spellbook'] = { ['name'] = '@PFRPG - Spellbook', ['prefix'] = 'spelldesc.' },
	}

	local node_reference_spell
	for _, table_module_data in pairs(array_modules) do
		node_reference_spell = DB.findNode(table_module_data['prefix'] .. string_spell_name .. table_module_data['name'])
		if node_reference_spell then break end
	end
	local number_spell_level = tonumber(node_spell.getChild('...').getName():gsub('level', '') or 0)
	if number_spell_level and string_spell_name and node_reference_spell then
		local node_spellset = node_spell.getChild('.....')
		local node_new_spell = replace_action_nodes(
						                       node_spell, node_spellset, number_spell_level, node_reference_spell, is_maximized, is_empowered
		                       )
		if node_new_spell then node_spell = node_new_spell end
		add_spell_description(node_spell, node_reference_spell)
		add_spell_information(node_spell, node_reference_spell)
	end

	return node_reference_spell;
end

local function find_spell_nodes(nodeEntry)
	for _, nodeSpellset in pairs(nodeEntry.createChild('spellset').getChildren()) do
		for _, nodeSpellLevel in pairs(nodeSpellset.createChild('levels').getChildren()) do
			for _, nodeSpell in pairs(nodeSpellLevel.createChild('spells').getChildren()) do replace_spell_actions(nodeSpell) end
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
	if (not string_input or string_input == '') then return {} end

	string_input = string_input .. ';' -- ending semicolon
	local table_output = {} -- table to collect fields
	local number_field_start = 1
	repeat
		local number_nexti = string.find(string_input, ';', number_field_start)
		table.insert(table_output, string.sub(string_input, number_field_start, number_nexti - 1))
		number_field_start = number_nexti + 1
	until number_field_start > string.len(string_input)

	return table_output
end

---	This function adds a link to matching creature maladies.
--	To work, it needs the malady node and npc node.
local function add_malady_link(node_malady, node_npc)
	local table_malady_npcs = string_to_table(DB.getValue(node_malady, 'npc')) or {}
	if table_malady_npcs ~= {} then
		for _, string_malady_linked_npc in pairs(table_malady_npcs) do
			local string_difficulty_class = (string_malady_linked_npc:match(' %(DC %d+%)')) or ''
			string_malady_linked_npc = string_malady_linked_npc:gsub(' %(DC %d+%)', '')
			string_malady_linked_npc = string.lower(string_malady_linked_npc:gsub('%A', ''))
			local string_npc_name = DB.getValue(node_npc, 'name')
			string_npc_name = string.lower(string_npc_name:gsub('%A', ''))
			if string_malady_linked_npc == string_npc_name then
				local string_description = DB.getValue(node_npc, 'text', '')
				local string_malady_name = DB.getValue(node_malady, 'name', '')
				local string_malady_link = ('<linklist><link class="referencedisease" recordname="' .. DB.getPath(node_malady) .. '"><b>Malady: </b>' ..
								                           string_malady_name .. string_difficulty_class .. '</link></linklist>')
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
		if DB.getValue(node_npc, 'name') then
			if DB.findNode('reference.diseases@*') then
				for _, node_malady in pairs(DB.findNode('reference.diseases@*').getChildren()) do add_malady_link(node_malady, node_npc) end
			end
			if DB.findNode('disease') then
				for _, node_malady in pairs(DB.findNode('disease').getChildren()) do add_malady_link(node_malady, node_npc) end
			end
		end
	end
end

--
--	ACTION AUTOMATION FUNCTIONS
--

local function add_ability_automation(node_npc, string_ability_name, table_ability_information, number_rank, string_parenthetical)
	if (not node_npc or string_ability_name == '' or not table_ability_information or table_ability_information == {} or
					(table_ability_information['daily_uses'] and table_ability_information['daily_uses'] < 0) or table_ability_information['level'] < 0 or
					table_ability_information['level'] > 9 or not table_ability_information['actions']) then return end

	-- create spellset and intermediate subnodes
	local node_spellset = node_npc.createChild('spellset')
	local node_spellclass = node_spellset.createChild(table_ability_information['string_ability_type'] or 'Abilities')
	local node_spelllevel = node_spellclass.createChild('levels').createChild('level' .. table_ability_information['level'])
	local node_ability = node_spelllevel.createChild('spells').createChild()

	-- set up spellset and intermediate subnodes
	DB.setValue(node_spellclass, 'label', 'string', table_ability_information['string_ability_type'])
	DB.setValue(node_spellclass, 'castertype', 'string', 'spontaneous')
	DB.setValue(node_spellclass, 'availablelevel' .. table_ability_information['level'], 'number', table_ability_information['daily_uses'] or 1)
	DB.setValue(node_spellclass, 'cl', 'number', 0)
	DB.setValue(node_spelllevel, 'level', 'number', table_ability_information['level'])

	-- set name and description
	DB.setValue(node_ability, 'name', 'string', string_ability_name)
	DB.setValue(node_ability, 'description', 'string', (table_ability_information['description'] or '') .. (string_parenthetical or ''))
	if table_ability_information['perday'] then DB.setValue(node_ability, 'prepared', 'number', table_ability_information['perday']) end
	DB.setValue(node_ability, 'sr', 'string', 'no')

	-- create actions
	local node_actions = node_ability.createChild('actions')
	for string_name_action, table_action_information in pairs(table_ability_information['actions']) do
		local node_action = node_actions.createChild(string_name_action)
		for string_node_name, table_node_info in pairs(table_action_information) do
			if string_node_name == 'damagelist' or string_node_name == 'heallist' then
				for string_damage_name, table_damage_information in pairs(table_node_info) do
					local node_damage = node_action.createChild(string_node_name).createChild(string_damage_name)
					for string_damagenode_name, table_damagenode_info in pairs(table_damage_information) do
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

local function parse_breath_weapon(string_parenthetical, table_ability_information)
	local string_parenthetical_lower = string.lower(', ' .. string_parenthetical .. ',')
	local dice_damage, string_damage_type = string_parenthetical_lower:match(',%s(%d%d*d*d%d+)%s*(%l+)[.+]?')
	local string_save_type, number_save_dc = string_parenthetical_lower:match(',%s(%l*%l*%l*%l*%l*%l*%l*%l*)%s*dc%s*(%d+)[.+]?')
	if string_save_type == 'fort' then string_save_type = 'fortitude' end
	local dice_recharge = string_parenthetical_lower:match(',%susable%severy%s(%d%d*d*d%d+)%srounds[.+]?')

	table_ability_information['actions']['breathweapondmg']['damagelist']['primarydamage']['dice']['value'] = dice_damage
	table_ability_information['actions']['breathweapondmg']['damagelist']['primarydamage']['type']['value'] = string_damage_type
	if string_save_type and string_save_type ~= '' then
		table_ability_information['actions']['breathweaponsave']['savetype']['value'] = string_save_type
	end
	table_ability_information['actions']['breathweaponsave']['savedcmod']['value'] = number_save_dc
	table_ability_information['actions']['breathweaponsave']['onmissdamage']['value'] = 'half'
	if dice_recharge and dice_recharge ~= '' then
		if dice_recharge:sub(1, 2) == '1d' then dice_recharge = dice_recharge:gsub('1d', 'd') end
		table_ability_information['actions']['breathweaponrecharge']['durdice']['value'] = dice_recharge
	end
end

local function parse_bleed(string_parenthetical, table_ability_information)
	if string_parenthetical ~= '' then
		table_ability_information['actions']['zeffect-1']['label']['value'] = string.format(
						                                                                      table_ability_information['actions']['zeffect-1']['label']['value'],
						                                                                      string_parenthetical
		                                                                      )
	end
end

local array_abilities = {
	-- luacheck: no max line length
	['Ancestral Enmity'] = {
		['auto_add'] = true,
		['description'] = 'You gain a +2 bonus on melee attack rolls against dwarves and gnomes.  You may select this feat twice. Its effects stack.',
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
		['description'] = 'As a swift action, you can imbue your weapons with a fraction of your power. For 1 round, your weapons deal +1 damage and are treated as magic for the purpose of overcoming damage reduction. For every five caster levels you possess, this bonus increases by +1, to a maximum of +5 at 20th level.',
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
		['description'] = 'Some creatures can exhale a cloud, cone, or line of magical effects. A breath weapon usually deals damage and is often based on some type of energy. Breath weapons allow a Reflex save for half damage (DC = 10 + 1/2 breathing creature’s racial HD + breathing creature’s Constitution modifier; the exact DC is given in the creature’s descriptive text). A creature is immune to its own breath weapon unless otherwise noted. Some breath weapons allow a Fortitude save or a Will save instead of a Reflex save. Each breath weapon also includes notes on how often it can be used.',
		['string_ability_type'] = 'Special Abilities',
		['level'] = 0,
		['parser'] = parse_breath_weapon,
		['actions'] = {
			['breathweaponsave'] = {
				['onmissdamage'] = { ['type'] = 'string', ['value'] = nil },
				['srnotallowed'] = { ['type'] = 'number', ['value'] = 1 },
				['savedcmod'] = { ['type'] = 'number', ['value'] = nil },
				['savedctype'] = { ['type'] = 'string', ['value'] = 'fixed' },
				['savetype'] = { ['type'] = 'string', ['value'] = 'reflex' },
				['type'] = { ['type'] = 'string', ['value'] = 'cast' },
			},
			['breathweapondmg'] = {
				['damagelist'] = {
					['primarydamage'] = { ['dice'] = { ['type'] = 'dice', ['value'] = nil }, ['type'] = { ['type'] = 'string', ['value'] = nil } },
				},
				['dmgnotspell'] = { ['type'] = 'number', ['value'] = 1 },
				['type'] = { ['type'] = 'string', ['value'] = 'damage' },
			},
			['breathweaponrecharge'] = {
				['durdice'] = { ['type'] = 'dice', ['value'] = 'd4' },
				['durunit'] = { ['type'] = 'string', ['value'] = 'round' },
				['label'] = { ['type'] = 'string', ['value'] = ('Breath Weapon Recharge') },
				['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
		},
	},
	['Bleed'] = {
		['description'] = 'A creature with this ability causes wounds that continue to bleed, dealing additional damage each round at the start of the affected creature’s turn. This bleeding can be stopped with a successful DC 15 Heal skill check or through the application of any magical healing. The amount of damage each round is specified in the creature’s entry.',
		['string_ability_type'] = 'Special Abilities',
		['level'] = 0,
		['search_dice'] = true,
		['number_substitution'] = true,
		['parser'] = parse_bleed,
		['actions'] = {
			['zeffect-1'] = {
				['durunit'] = { ['type'] = 'string', ['value'] = 'round' },
				['label'] = { ['type'] = 'string', ['value'] = 'Bleed; DMGO: %s bleed' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
		},
	},
	['Combat Expertise'] = {
		['description'] = 'You can choose to take a -1 penalty on melee attack rolls and combat maneuver checks to gain a +1 dodge bonus to your Armor Class. When your base attack bonus reaches +4, and every +4 thereafter, the penalty increases by -1 and the dodge bonus increases by +1. You can only choose to use this feat when you declare that you are making an attack or a full-attack action with a melee weapon. The effects of this feat last until your next turn.',
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
	['Critical Focus'] = {
		['auto_add'] = true,
		['description'] = 'You receive a +4 circumstance bonus on attack rolls made to confirm critical hits.',
		['string_ability_type'] = 'Feats',
		['level'] = 0,
		['actions'] = {
			['zeffect-1'] = {
				['durunit'] = { ['type'] = 'string', ['value'] = 'round' },
				['label'] = { ['type'] = 'string', ['value'] = 'Critical Focus; CC: +4 circumstance' },
				['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
		},
	},
	['Deadly Aim'] = {
		['description'] = 'You can choose to take a -1 penalty on all ranged attack rolls to gain a +2 bonus on all ranged damage rolls. When your base attack bonus reaches +4, and every +4 thereafter, the penalty increases by -1 and the bonus to damage increases by +2. You must choose to use this feat before making an attack roll and its effects last until your next turn. The bonus damage does not apply to touch attacks or effects that do not deal hit point damage.',
		['string_ability_type'] = 'Feats',
		['level'] = 0,
		['actions'] = {
			['zeffect-1'] = {
				['durunit'] = { ['type'] = 'string', ['value'] = 'round' },
				['label'] = { ['type'] = 'string', ['value'] = 'Deadly Aim; ATK: -1 [-QBAB] ,ranged; DMG: 2 [QBAB] [QBAB] ,ranged' },
				['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
		},
	},
	['Defended Movement'] = {
		['auto_add'] = true,
		['description'] = 'You gain a +2 bonus to your AC against attacks of opportunity.',
		['string_ability_type'] = 'Feats',
		['level'] = 0,
		['actions'] = {
			['zeffect-1'] = {
				['durunit'] = { ['type'] = 'string', ['value'] = 'round' },
				['label'] = { ['type'] = 'string', ['value'] = 'Defended Movement; AC: 4 ,,opportunity' },
				['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
		},
	},
	['Furious Focus'] = {
		['auto_add'] = true,
		['description'] = 'When you are wielding a two-handed weapon or a one-handed weapon with two hands, and using the Power Attack feat, you do not suffer Power Attack’s penalty on melee attack rolls on the first attack you make each turn. You still suffer the penalty on any additional attacks, including attacks of opportunity.',
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
		['auto_add'] = true,
		['description'] = 'You get a +4 dodge bonus to Armor Class against attacks of opportunity caused when you move out of or within a threatened area. A condition that makes you lose your Dexterity bonus to Armor Class (if any) also makes you lose dodge bonuses. Dodge bonuses stack with each other, unlike most types of bonuses.',
		['string_ability_type'] = 'Feats',
		['level'] = 0,
		['actions'] = {
			['zeffect-1'] = {
				['label'] = { ['type'] = 'string', ['value'] = 'Mobility; AC: 4 dodge,opportunity' },
				['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
		},
	},
	-- ['Mythic Power'] = {
	-- ['description'] = 'Every mythic PC gains a number of base abilities common to all mythic characters, in addition to the special abilities granted by each mythic path. These abilities are gained based on the character’s mythic tier.',
	-- ['string_ability_type'] = 'Special Abilities',
	-- ['level'] = 0,
	-- ['perday'] = nil,
	-- ['actions'] = {
	-- ['surge'] = {
	-- ['durunit'] = { ['type'] = 'string', ['value'] = 'round' },
	-- ['label'] = { ['type'] = 'string', ['value'] = 'Critical Focus; CC: +4 circumstance' },
	-- ['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
	-- ['type'] = { ['type'] = 'string', ['value'] = 'effect' },
	-- },
	-- },
	-- },
	['Power Attack'] = {
		['description'] = 'You can choose to take a -1 penalty on all melee attack rolls and combat maneuver checks to gain a +2 bonus on all melee damage rolls. This bonus to damage is increased by half (+50%) if you are making an attack with a two-handed weapon, a one handed weapon using two hands, or a primary natural weapon that adds 1-1/2 times your Strength modifier on damage rolls. This bonus to damage is halved (-50%) if you are making an attack with an off-hand weapon or secondary natural weapon. When your base attack bonus reaches +4, and every 4 points thereafter, the penalty increases by -1 and the bonus to damage increases by +2. You must choose to use this feat before making an attack roll, and its effects last until your next turn. The bonus damage does not apply to touch attacks or effects that do not deal hit point damage.',
		['string_ability_type'] = 'Feats',
		['level'] = 0,
		['actions'] = {
			['zeffect-1'] = {
				['label'] = { ['type'] = 'string', ['value'] = 'Power Attack 1-H; ATK: -1 [-QBAB] ,melee; DMG: 2 [QBAB] [QBAB] ,melee' },
				['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
			['zeffect-2'] = {
				['label'] = { ['type'] = 'string', ['value'] = 'REMOVE: Power Attack 1-H; ATK: -1 [-QBAB] ,melee; DMG: 2 [QBAB] [QBAB] ,melee' },
				['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
			['zeffect-3'] = {
				['label'] = { ['type'] = 'string', ['value'] = 'Power Attack 2-H; ATK: -1 [-QBAB] ,melee; DMG: 3 [QBAB] [QBAB] [QBAB] ,melee' },
				['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
			['zeffect-4'] = {
				['label'] = { ['type'] = 'string', ['value'] = 'REMOVE: Power Attack 2-H; ATK: -1 [-QBAB] ,melee; DMG: 3 [QBAB] [QBAB] [QBAB] ,melee' },
				['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
		},
	},
}

---	This function breaks down a table of abilities and searches for them in an NPC sheet.
--	The search result is provided by the hasSpecialAbility function.
--	If a match is found, it triggers the function hasSpecialAbility.
local function search_for_abilities(node_npc)

	---	This function checks NPCs for feats, traits, and/or special abilities.
	local function hasSpecialAbility(nodeActor, sSearchString, sAbilType)
		if not nodeActor or not sSearchString then return false; end

		local function matchInTable(table, search)
			for _, string in ipairs(table) do
				string = string:lower()

				local match = string:match(search:lower(), 1)
				if match then return match; end
			end
		end

		local tScope = {}
		if sAbilType == 'Feats' then
			tScope = { DB.getValue(nodeActor, '.specialattacks', ''), DB.getValue(nodeActor, '.feats', '') }
		elseif sAbilType == 'Special Abilities' then
			tScope = { DB.getValue(nodeActor, '.specialattacks', ''), DB.getValue(nodeActor, '.specialqualities', '') }
		end

		return matchInTable(tScope, sSearchString) ~= nil, matchInTable(tScope, sSearchString .. ' (%d+)') or 1,
		       matchInTable(tScope, sSearchString .. ' %((.-)%)')
	end

	for string_ability_name, table_ability_information in pairs(array_abilities) do
		local is_match, number_rank, string_parenthetical = hasSpecialAbility(
						                                                    node_npc, string_ability_name, table_ability_information['string_ability_type']
		                                                    )

		if is_match then
			-- call ability parser function if supplied
			if string_parenthetical and table_ability_information['parser'] then
				table_ability_information['parser'](string_parenthetical, table_ability_information)
			end

			-- add ability
			add_ability_automation(node_npc, string_ability_name, table_ability_information, number_rank, string_parenthetical)
		end
	end
end

-- Function Overrides
function onInit()

	---	This function is called when adding an NPC to the combat tracker.
	local addNPC_old -- placeholder for original addNPC function
	local function addNPC_new(tCustom, ...)
		addNPC_old(tCustom, ...) -- call original function

		local bAutomatedModule, tSourceModule = nil, Module.getModuleInfo(tCustom['nodeRecord'].getPath():gsub('.+%@', ''))
		if tSourceModule then
			bAutomatedModule = tSourceModule['author'] == 'Tanor'
		end

		find_spell_nodes(tCustom['nodeCT'])
		search_for_maladies(tCustom['nodeCT'])
		if not bAutomatedModule then search_for_abilities(tCustom['nodeCT']) end
	end

	addNPC_old = CombatRecordManager.addNPC
	CombatRecordManager.addNPC = addNPC_new

	---	This function is called when clicking re-parse spell on the radial menu.
	--	It re-imports the spell details from the PFRPG - Spellbook module.
	--	If not Spellbook spell is found, it passes the call to the original addNPC function.
	local parseSpell_old -- placeholder for original parseSpell function
	local function parseSpell_new(nodeSpell, ...)
		if nodeSpell then
			local node_reference_spell = replace_spell_actions(nodeSpell)
			-- if spellbook actions not found, run original parsing script
			if not node_reference_spell then parseSpell_old(nodeSpell, ...) end
		end
	end

	parseSpell_old = SpellManager.parseSpell
	SpellManager.parseSpell = parseSpell_new
end
