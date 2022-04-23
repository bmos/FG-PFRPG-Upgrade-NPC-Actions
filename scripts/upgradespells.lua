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

-- Function Overrides
function onInit()

	---	This function is called when adding an NPC to the combat tracker.
	--	It passes the call to the original addNPC function.
	--	Once it receives the node, it performs replacement of actions.
	local addNPC_old -- placeholder for original addNPC function
	local function addNPC_new(sClass, nodeNPC, sName, ...)
		local nodeEntry = addNPC_old(sClass, nodeNPC, sName, ...)
		if nodeEntry then
			find_spell_nodes(nodeEntry)
			search_for_maladies(nodeEntry)
		end

		return nodeEntry
	end

	addNPC_old = CombatManager.addNPC
	CombatManager.addNPC = addNPC_new

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
