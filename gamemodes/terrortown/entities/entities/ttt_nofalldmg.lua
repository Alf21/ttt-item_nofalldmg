if SERVER then
	AddCSLuaFile()
	
	resource.AddFile("materials/vgui/ttt/icon_nofalldmg.vmt")
	resource.AddFile("materials/vgui/ttt/perks/hud_nofalldmg.png")
end

EQUIP_NOFALLDMG = (GenerateNewEquipmentID and GenerateNewEquipmentID()) or 16

local nofalldmg = {
	id = EQUIP_NOFALLDMG,
	loadout = false,
	type = "item_passive",
	material = "vgui/ttt/icon_nofalldmg",
	name = "No Fall Damage",
	desc = "You don't get falldamage anymore!",
	hud = true
}

local flag = {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}

local detectiveCanUse = CreateConVar("ttt_nofalldmg_det", 1, flag, "Should the Detective be able to buy NoFallDamage.")
local traitorCanUse = CreateConVar("ttt_nofalldmg_tr", 1, flag, "Should the Traitor be able to use buy NoFallDamage.")

if detectiveCanUse:GetBool() then
	table.insert(EquipmentItems[ROLE_DETECTIVE], nofalldmg)
end

if traitorCanUse:GetBool() then
	table.insert(EquipmentItems[ROLE_TRAITOR], nofalldmg)
end

if SERVER then
	hook.Add("ScalePlayerDamage", "TTTNoFallDmg", function(ply, hitgroup, dmginfo)
        if ply:IsActive() and ply:HasEquipmentItem(EQUIP_NOFALLDMG) then
            if dmginfo:IsFallDamage() then
				dmginfo:ScaleDamage(0)
			end
        end
    end)

    hook.Add("EntityTakeDamage", "TTTNoFallDmg", function(target, dmginfo)
        if not target or not IsValid(target) or not target:IsPlayer() then return end
    
        if target:IsActive() and target:HasEquipmentItem(EQUIP_NOFALLDMG) then
            if dmginfo:IsFallDamage() then -- check its fall dmg.
                dmginfo:ScaleDamage(0) -- no dmg
            end
        end
    end)

    hook.Add("OnPlayerHitGround", "TTTNoFallDmg", function(ply)
        if ply:IsActive() and ply:HasEquipmentItem(EQUIP_NOFALLDMG) then
			return false
        end
	end)
else
	-- feel for to use this function for your own perk, but please credit Zaratusa
	-- your perk needs a "hud = true" in the table, to work properly
	local defaultY = ScrH() / 2 + 20
	
	local function getYCoordinate(currentPerkID)
		local amount, i, perk = 0, 1
		local client = LocalPlayer()
		
		while i < currentPerkID do
			local role = client:GetRole()

			if role == ROLE_INNOCENT then -- he gets it in a special way
				if GetEquipmentItem(ROLE_TRAITOR, i) then
					role = ROLE_TRAITOR -- Temp fix what if a perk is just for Detective
				elseif GetEquipmentItem(ROLE_DETECTIVE, i) then
					role = ROLE_DETECTIVE
				end
			end

			perk = GetEquipmentItem(role, i)

			if istable(perk) and perk.hud and client:HasEquipmentItem(perk.id) then
				amount = amount + 1
			end
			
			i = i * 2
		end

		return defaultY - 80 * amount
	end

	local yCoordinate = defaultY
	
	-- best performance, but the has about 0.5 seconds delay to the HasEquipmentItem() function
	hook.Add("TTTBoughtItem", "TTTNoFallDmg", function()
		if LocalPlayer():HasEquipmentItem(EQUIP_NOFALLDMG) then
			yCoordinate = getYCoordinate(EQUIP_NOFALLDMG)
		end
	end)
	
	local material = Material("vgui/ttt/perks/hud_nofalldmg.png")
	
	hook.Add("HUDPaint", "TTTNoFallDmg", function()
		if LocalPlayer():HasEquipmentItem(EQUIP_NOFALLDMG) then
			surface.SetMaterial(material)
			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawTexturedRect(20, yCoordinate, 64, 64)
		end
	end)

	hook.Add("TTTBodySearchEquipment", "TTTNoFallDmgCorpseIcon", function(search, eq)
		search.eq_nofalldmg = util.BitSet(eq, EQUIP_NOFALLDMG)
	end)

	hook.Add("TTTBodySearchPopulate", "TTTNoFallDmgCorpseIcon", function(search, raw)
		if not raw.eq_nofalldmg then return end

		local highest = 0
		
		for _, v in pairs(search) do
			highest = math.max(highest, v.p)
		end

		search.eq_nofalldmg = {img = "vgui/ttt/icon_nofalldmg", text = "They didn't got falldamage.", p = highest + 1}
	end)
end
