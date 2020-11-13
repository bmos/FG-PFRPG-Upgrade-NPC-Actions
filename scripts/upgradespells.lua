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
	sSpellName = string.sub(sSpellName, 1, nEnd)
	sSpellName = string.gsub(sSpellName, '%A+', '')
	
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
					for _,nodeSpellset in pairs(nodeEntry.getChild('spellset').getChildren()) do
						for _,nodeSpellLevel in pairs(nodeSpellset.getChild('levels').getChildren()) do
							for _,nodeSpell in pairs(nodeSpellLevel.getChild('spells').getChildren()) do
								local sSpellName = string.lower(DB.getValue(nodeSpell, 'name'))
								if sSpellName then
									local nodeReferenceSpellActions = getReferenceSpellActions(sSpellName)
									local nodeSpellActions = nodeSpell.createChild('actions')
									if nodeReferenceSpellActions and nodeSpellActions then
										for _,nodeAction in pairs(nodeSpellActions.getChildren()) do
											local sType = string.lower(DB.getValue(nodeAction, 'type', '')) 
											if sType == 'effect' then
												DB.deleteNode(nodeAction)
											end
										end
										for _,nodeReferenceAction in pairs(nodeReferenceSpellActions.getChildren()) do
											local sType = string.lower(DB.getValue(nodeReferenceAction, 'type', '')) 
											if sType == 'effect' then
												DB.copyNode(nodeReferenceAction, nodeSpellActions.createChild())
											end
										end

										-- copy fully-formatted spell description for use with Spell Formatting extension
										DB.copyNode(nodeReferenceSpellActions.getParent().getChild('description'), nodeSpell.createChild('description_full', 'formattedtext'))
									end
								end
							end
						end
					end
					-- end of bmos code

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