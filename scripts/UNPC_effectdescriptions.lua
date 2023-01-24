--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--
-- effects summaries for tooltips in effect list
-- NOTE: From rules, missing dying, staggered and disabled
--	luacheck: no max line length
--	luacheck: globals conditionshelp
conditionshelp = {
	blinded = 'Fantasy Grounds Automation: AC:-2; GRANTCA; SKILL:-2 strength dexterity; SKILL:-4 search perception\nThe creature cannot see. It takes a –2 penalty to Armor Class, loses its Dexterity bonus to AC (if any), and takes a –4 penalty on most Strength-based and Dexterity-based skill checks and on opposed Perception skill checks. All checks and activities that rely on vision (such as reading and Perception checks based on sight) automatically fail. All opponents are considered to have total concealment (50% miss chance) against the blinded character. Blind creatures must make a DC 10 Acrobatics skill check to move faster than half speed. Creatures that fail this check fall prone. Characters who remain blinded for a long time grow accustomed to these drawbacks and can overcome some of them.',
	climbing = 'Fantasy Grounds Automation: GRANTCA\nUsing Athletics, you can advance up, down, or across a slope, wall, or other steep incline (or a ceiling if it has handholds). You move at one-quarter your speed, though you can move at half your speed if you take a –5 penalty. If you fail the check by 4 or less, you make no progress. If you fail by 5 or more, you fall. A perfectly smooth vertical (or inverted) surface can’t be climbed.\nYou need both hands free to climb, but can cling with one hand while using the other to cast a spell or take some other action. You can’t use a shield while climbing. You lose your Dexterity bonus to AC while climbing. If you take damage while climbing, you must succeed at an Athletics check against the DC of the surface or fall.',
	confused = 'A confused creature is mentally befuddled and cannot act normally. A confused creature cannot tell the difference between ally and foe, treating all creatures as enemies. Allies wishing to cast a beneficial spell that requires a touch on a confused creature must succeed on a melee touch attack. If a confused creature is attacked, it attacks the creature that last attacked it until that creature is dead or out of sight.\nA confused creature who can’t carry out the indicated action does nothing but babble incoherently. Attackers are not at any special advantage when attacking a confused creature. Any confused creature who is attacked automatically attacks its attackers on its next turn, as long as it is still confused when its turn comes. Note that a confused creature will not make attacks of opportunity against anything that it is not already devoted to attacking (either because of its most recent action or because it has just been attacked).\n01-25: Acts normally\n26-50: Does nothing but babble incoherently\n51-75: Deals 1d8 points of damage + Str modifier to self with item in hand\n76-100: Attacks nearest creature (for this purpose, a familiar counts as part of the subject’s self).',
	cowering = 'Fantasy Grounds Automation: AC:-2\nThe character is frozen in fear and can take no actions. A cowering character takes a –2 penalty to Armor Class and loses his Dexterity bonus (if any).',
	dazed = 'The creature is unable to act normally. A dazed creature can take no actions, but has no penalty to AC. A dazed condition typically lasts 1 round.',
	dazzled = 'Fantasy Grounds Automation: ATK:-1; SKILL:-1 spot search perception\nThe creature is unable to see well because of overstimulation of the eyes. A dazzled creature takes a –1 penalty on attack rolls and sight-based Perception checks.',
	deafened = 'Fantasy Grounds Automation: INIT: -4\nA deafened character cannot hear. He takes a –4 penalty on initiative checks, automatically fails Perception checks based on sound, takes a –4 penalty on opposed Perception checks, and has a 20% chance of spell failure when casting spells with verbal components. Characters who remain deafened for a long time grow accustomed to these drawbacks and can overcome some of them.',
	entangled = 'Fantasy Grounds Automation: ATK:-2; DEX:-4\nThe character is ensnared. Being entangled impedes movement, but does not entirely prevent it unless the bonds are anchored to an immobile object or tethered by an opposing force. An entangled creature moves at half speed, cannot run or charge, and takes a –2 penalty on all attack rolls and a –4 penalty to Dexterity. An entangled character who attempts to cast a spell must make a concentration check (DC 15 + spell level) or lose the spell.',
	exhausted = 'Fantasy Grounds Automation: DEX:-6; STR:-6\nAn exhausted character moves at half speed, cannot run or charge, and takes a –6 penalty to Strength and Dexterity. After 1 hour of complete rest, an exhausted character becomes fatigued. A fatigued character becomes exhausted by doing something else that would normally cause fatigue.',
	fascinated = 'Fantasy Grounds Automation: SKILL:-4 spot listen perception\nA fascinated creature is entranced by a supernatural or spell effect. The creature stands or sits quietly, taking no actions other than to pay attention to the fascinating effect, for as long as the effect lasts. It takes a –4 penalty on skill checks made as reactions, such as Perception checks. Any potential threat, such as a hostile creature approaching, allows the fascinated creature a new saving throw against the fascinating effect. Any obvious threat, such as someone drawing a weapon, casting a spell, or aiming a ranged weapon at the fascinated creature, automatically breaks the effect. A fascinated creature’s ally may shake it free of the spell as a standard action.',
	fatigued = 'Fantasy Grounds Automation: DEX:-2; STR:-2\nA fatigued character can neither run nor charge and takes a –2 penalty to Strength and Dexterity. Doing anything that would normally cause fatigue causes the fatigued character to become exhausted. After 8 hours of complete rest, fatigued characters are no longer fatigued.',
	flatfooted = 'A character who has not yet acted during a combat is flat-footed, unable to react normally to the situation. A flat-footed character loses his Dexterity bonus to AC (if any) and cannot make attacks of opportunity.',
	frightened = 'Fantasy Grounds Automation: ATK:-2; SAVE:-2; SKILL:-2; ABIL:-2\nA frightened creature flees from the source of its fear as best it can. If unable to flee, it may fight. A frightened creature takes a –2 penalty on all attack rolls, saving throws, skill checks, and ability checks. A frightened creature can use special abilities, including spells, to flee; indeed, the creature must use such means if they are the only way to escape./nFrightened is like shaken, except that the creature must flee if possible. Panicked is a more extreme state of fear.',
	grappled = 'Fantasy Grounds Automation: GRANTCA; ATK: -2; DEX: -4\nA grappled creature is restrained by a creature, trap, or effect. Grappled creatures cannot move and take a –4 penalty to Dexterity. A grappled creature takes a –2 penalty on all attack rolls and combat maneuver checks, except those made to grapple or escape a grapple. In addition, grappled creatures can take no action that requires two hands to perform. A grappled character who attempts to cast a spell or use a spell-like ability must make a concentration check (DC 10 + grappler’s CMB + spell level, see Concentration), or lose the spell. Grappled creatures cannot make attacks of opportunity.\nA grappled creature cannot use Stealth to hide from the creature grappling it, even if a special ability, such as hide in plain sight, would normally allow it to do so. If a grappled creature becomes invisible, through a spell or other ability, it gains a +2 circumstance bonus on its CMD to avoid being grappled, but receives no other benefit.',
	helpless = 'Fantasy Grounds Automation: AC:-4 melee\nA helpless character is paralyzed, held, bound, sleeping, unconscious, or otherwise completely at an opponent’s mercy. A helpless target is treated as having a Dexterity of 0 (–5 modifier). Melee attacks against a helpless target get a +4 bonus (equivalent to attacking a prone target). Ranged attacks get no special bonus against helpless targets. Rogues can sneak attack helpless targets.\nAs a full-round action, an enemy can use a melee weapon to deliver a coup de grace to a helpless foe. An enemy can also use a bow or crossbow, provided he is adjacent to the target. The attacker automatically hits and scores a critical hit. (A rogue also gets his sneak attack damage bonus against a helpless foe when delivering a coup de grace.) If the defender survives, he must make a Fortitude save (DC 10 + damage dealt) or die. Delivering a coup de grace provokes attacks of opportunity.\nCreatures that are immune to critical hits do not take critical damage, nor do they need to make Fortitude saves to avoid being killed by a coup de grace.',
	incorporeal = 'Creatures with the incorporeal condition do not have a physical body. Incorporeal creatures are immune to all nonmagical attack forms. Incorporeal creatures take half damage (50%) from magic weapons, spells, spell-like effects, and supernatural effects. Incorporeal creatures take full damage from other incorporeal creatures and effects, as well as all force effects.',
	invisible = 'Fantasy Grounds Automation: ATK:2; CA; TCONC\nInvisible creatures are visually undetectable. An invisible creature gains a +2 bonus on attack rolls against a sighted opponent, and ignores its opponent’s Dexterity bonus to AC (if any). See Invisibility, under Special Abilities.',
	kneeling = 'Fantasy Grounds Automation: AC: -2 melee; AC: 2 ranged',
	nauseated = 'Creatures with the nauseated condition experience stomach distress. Nauseated creatures are unable to attack, cast spells, concentrate on spells, or do anything else requiring attention. The only action such a character can take is a single move actions per turn.',
	panicked = 'Fantasy Grounds Automation: ATK:-2; SAVE:-2; SKILL:-2; ABIL:-2\nA panicked creature must drop anything it holds and flee at top speed from the source of its fear, as well as any other dangers it encounters, along a random path. It can’t take any other actions. In addition, the creature takes a –2 penalty on all saving throws, skill checks, and ability checks. If cornered, a panicked creature cowers and does not attack, typically using the total defense action in combat. A panicked creature can use special abilities, including spells, to flee; indeed, the creature must use such means if they are the only way to escape.',
	paralyzed = 'Fantasy Grounds Automation: AC:-4 melee\nA paralyzed character is frozen in place and unable to move or act. A paralyzed character has effective Dexterity and Strength scores of 0 and is helpless, but can take purely mental actions. A winged creature f lying in the air at the time that it becomes paralyzed cannot flap its wings and falls. A paralyzed swimmer can’t swim and may drown. A creature can move through a space occupied by a paralyzed creature—ally or not. Each square occupied by a paralyzed creature, however, counts as 2 squares to move through.',
	petrified = 'Fantasy Grounds Automation: AC:-4 melee\nA petrified character has been turned to stone and is considered unconscious. If a petrified character cracks or breaks, but the broken pieces are joined with the body as he returns to flesh, he is unharmed. If the character’s petrified body is incomplete when it returns to flesh, the body is likewise incomplete and there is some amount of permanent hit point loss and/or debilitation.',
	pinned = 'Fantasy Grounds Automation: GRANTCA, AC:-4\nA pinned creature is tightly bound and can take few actions. A pinned creature cannot move and is denied its Dexterity bonus. A pinned character also takes an additional –4 penalty to his Armor Class. A pinned creature is limited in the actions that it can take. A pinned creature can always attempt to free itself, usually through a combat maneuver check or Escape Artist check. A pinned creature can take verbal and mental actions, but cannot cast any spells that require a somatic or material component. A pinned character who attempts to cast a spell or use a spell-like ability must make a concentration check (DC 10 + grappler’s CMB + spell level) or lose the spell. Pinned is a more severe version of grappled, and their effects do not stack.',
	prone = 'Fantasy Grounds Automation: ATK:-4 melee; AC:-4 melee; AC:4 ranged\nThe character is lying on the ground. A prone attacker has a –4 penalty on melee attack rolls and cannot use a ranged weapon (except for a crossbow). A prone defender gains a +4 bonus to Armor Class against ranged attacks, but takes a –4 penalty to AC against melee attacks.\nStanding up is a move-equivalent action that provokes an attack of opportunity.',
	rebuked = 'Fantasy Grounds Automation: AC:-2',
	running = 'Fantasy Grounds Automation: GRANTCA\nYou can run as a full-round action. If you do, you do not also get a 5-foot step. When you run, you can move up to four times your speed in a straight line (or three times your speed if you’re in heavy armor). You lose any Dexterity bonus to AC unless you have the Run feat.\nYou can run for a number of rounds equal to your Constitution score, but after that you must make a DC 10 Constitution check to continue running. You must check again each round in which you continue to run, and the DC of this check increases by 1 for each check you have made. When you fail this check, you must stop running. A character who has run to his limit must rest for 1 minute (10 rounds) before running again. During a rest period, a character can move no faster than a normal move action.\nYou can’t run across difficult terrain or if you can’t see where you’re going.\nA run represents a speed of about 13 miles per hour for an unencumbered human.',
	shaken = 'Fantasy Grounds Automation: ATK:-2; SAVE:-2; SKILL:-2; ABIL:-2\nA shaken character takes a –2 penalty on attack rolls, saving throws, skill checks, and ability checks. Shaken is a less severe state of fear than frightened or panicked.',
	sickened = 'Fantasy Grounds Automation: ATK:-2; DMG:-2; SAVE:-2; SKILL:-2; ABIL:-2\nThe character takes a –2 penalty on all attack rolls, weapon damage rolls, saving throws, skill checks, and ability checks.',
	sitting = 'Fantasy Grounds Automation: AC:-2 melee; AC:2 ranged',
	slowed = "Fantasy Grounds Automation: ATK:-1; AC:-1; REF:-1\nAn affected creature moves and attacks at a drastically slowed rate. Creatures affected by this spell are staggered and can take only a single move action or standard action each turn, but not both (nor may it take full-round actions). Additionally, it takes a –1 penalty on attack rolls, AC, and Reflex saves. A slowed creature moves at half its normal speed (round down to the next 5-foot increment), which affects the creature's jumping distance as normal for decreased speed.",
	squeezing = 'Fantasy Grounds Automation: AC:-4; ATK:-4\nIn some cases, you may have to squeeze into or through an area that isn’t as wide as the space you take up. You can squeeze through or into a space that is at least half as wide as your normal space. Each move into or through a narrow space counts as if it were 2 squares, and while squeezed in a narrow space, you take a –4 penalty on attack rolls and a –4 penalty to AC.',
	stable = 'Fantasy Grounds Automation: no automatic death saving throws\nA character who was dying but who has stopped losing hit points each round and still has negative hit points is stable. The character is no longer dying, but is still unconscious. If the character has become stable because of aid from another character (such as a Heal check or magical healing), then the character no longer loses hit points. The character can make a DC 10 Constitution check each hour to become conscious and disabled (even though his hit points are still negative). The character takes a penalty on this roll equal to his negative hit point total.\nIf a character has become stable on his own and hasn’t had help, he is still at risk of losing hit points. Each hour he can make a Constitution check to become stable (as a character that has received aid), but each failed check causes him to lose 1 hit point.',
	stunned = 'Fantasy Grounds Automation: AC:-2; GRANTCA\nA stunned creature drops everything held, can’t take actions, takes a –2 penalty to AC, and loses its Dexterity bonus to AC (if any).',
	turned = 'Fantasy Grounds Automation: AC:-2',
	unconscious = 'Fantasy Grounds Automation: AC:-4 melee\nUnconscious creatures are knocked out and helpless. Unconsciousness can result from having negative hit points (but not more than the creature’s Constitution score), or from nonlethal damage in excess of current hit points.',
}
