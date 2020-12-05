-- 
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

local addBattle_old = nil

-- Function Overrides
function onInit()
	addBattle_old = CombatManager.addBattle;
	CombatManager.addBattle = addBattle_new;
end

function onClose()
	CombatManager.addBattle = addBattle_old;
end

function getReferenceSpellActions(sSpellName)
	local nEnd = string.find(sSpellName, '%(')
	sSpellName = sSpellName:sub(1, nEnd)
	sSpellName = sSpellName:gsub('.+:', '')
	sSpellName = sSpellName:gsub(',.+', '')
	sSpellName = sSpellName:gsub('%A+', '')
	sSpellName = StringManager.trim(sSpellName)
	if string.find(sSpellName, 'greater') then sSpellName = sSpellName:gsub('greater', '') .. 'greater'	end
	
	local nodeReferenceSpell = DB.findNode('spelldesc.' .. sSpellName .. '@PFRPG - Spellbook')
	if nodeReferenceSpell then
		return nodeReferenceSpell.getChild('actions')
	end
end

function addBattle_new(nodeBattle)
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
		wSelect.initialize(aModulesToLoad, onBattleNPCLoadCallback, { nodeBattle = nodeBattle });
		return;
	end
	
	if fCustomAddBattle then
		return fCustomAddBattle(nodeBattle);
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

					-- bmos replacing spell effects
					if nodeEntry.getChild('spellset') then
						for _,nodeSpellset in pairs(nodeEntry.getChild('spellset').getChildren()) do
							for _,nodeSpellLevel in pairs(nodeSpellset.getChild('levels').getChildren()) do
								local sSpellLevel = nodeSpellLevel.getName():gsub('level', '')
								local nSpellLevel = tonumber(sSpellLevel)
								for _,nodeSpell in pairs(nodeSpellLevel.getChild('spells').getChildren()) do
									local sSpellName = string.lower(DB.getValue(nodeSpell, 'name'))
									if sSpellName then
										local nodeReferenceSpellActions = getReferenceSpellActions(sSpellName)
										local nodeSpellActions = nodeSpell.getChild('actions')
										if nodeReferenceSpellActions and nodeSpellActions then
											for _,nodeAction in pairs(nodeSpellActions.getChildren()) do
												local sType = string.lower(DB.getValue(nodeAction, 'type', '')) 
												if sType ~= 'cast' then
													DB.deleteNode(nodeAction)
												end
											end
											for _,nodeReferenceAction in pairs(nodeReferenceSpellActions.getChildren()) do
												local sType = string.lower(DB.getValue(nodeReferenceAction, 'type', '')) 
												if sType ~= 'cast' then
													DB.copyNode(nodeReferenceAction, nodeSpellActions.createChild())
												end
											end
										elseif nodeReferenceSpellActions then
											local nPrepared = DB.getValue(nodeSpell, 'prepared', 0)
											local sSpellName = DB.getValue(nodeSpell, 'name', '')
											DB.deleteNode(nodeSpell)
											local nodeSpell = SpellManager.addSpell(nodeReferenceSpellActions.getParent(), nodeSpellset, nSpellLevel)
											DB.setValue(nodeSpell, 'prepared', 'number', nPrepared)
											DB.setValue(nodeSpell, 'name', 'string', sSpellName)
										end
									end
								end
							end
						end
					end
					-- bmos adding automatic disease addition for DiseaseTracker
					if DiseaseTracker then
						local sNPCName = DB.getValue(nodeEntry, 'name')
						if sNPCName then
							sNPCName = string.lower(sNPCName:gsub('%A', ''))
							if DB.findNode('reference.diseases@*') then
								for _,nodeDisease in pairs(DB.findNode('reference.diseases@*').getChildren()) do
									local sDiseaseCreature = DB.getValue(nodeDisease, 'npc')
									if sDiseaseCreature then
										sDiseaseCreature = string.lower(sDiseaseCreature:gsub('%A', ''))
										if sDiseaseCreature == sNPCName then
											local sDesc = DB.getValue(nodeEntry, 'text', '')
											local sDiseaseName = DB.getValue(nodeDisease, 'name')
											local sDescAdd = '<linklist><link class="referencedisease" recordname="' .. DB.getPath(nodeDisease) .. '"><b>Malady: </b>' .. sDiseaseName .. '</link></linklist>'
											DB.setValue(nodeEntry, 'text', 'formattedtext', sDescAdd .. sDesc)										
										end
									end
								end
							end
							if DB.findNode('disease') then
								for _,nodeDisease in pairs(DB.findNode('disease').getChildren()) do
									local sDiseaseCreature = DB.getValue(nodeDisease, 'npc')
									if sDiseaseCreature then
										sDiseaseCreature = string.lower(sDiseaseCreature:gsub('%A', ''))
										if sDiseaseCreature == sNPCName then
											local sDesc = DB.getValue(nodeEntry, 'text', '')
											local sDiseaseName = DB.getValue(nodeDisease, 'name')
											local sDescAdd = '<linklist><link class="referencedisease" recordname="' .. DB.getPath(nodeDisease) .. '"><b>Malady: </b>' .. sDiseaseName .. '</link></linklist>'
											DB.setValue(nodeEntry, 'text', 'formattedtext', sDescAdd .. sDesc)										
										end
									end
								end
							end
						end
					end
					-- end bmos additions

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