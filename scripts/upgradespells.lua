--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
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
						end
					end
				end
			end
		end
	end
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

local addNPC_old = nil -- placeholder for original addNPC function

---	This function is called when adding an NPC to the combat tracker.
--	It passes the call to the original addNPC function.
--	Once it receives the node, it performs replacement of actions.
local function addNPC_new(sClass, nodeNPC, sName)
	local nodeEntry = addNPC_old(sClass, nodeNPC, sName)
	if nodeEntry then
		replace_spell_effects(nodeEntry)
		search_for_maladies(nodeEntry)
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
