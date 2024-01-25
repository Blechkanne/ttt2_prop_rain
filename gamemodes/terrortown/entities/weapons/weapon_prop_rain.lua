CreateConVar("ttt_proprain_sidelength", 300, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})
CreateConVar("ttt_proprain_proptimer", 100, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}) -- in ms
CreateConVar("ttt_proprain_iterations", 30, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})
CreateConVar("ttt_proprain_despawn_props", 0, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})
CreateConVar("ttt_proprain_despawn_seconds", 5, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})

SWEP.PrintName = "Prop Rain"
SWEP.Author = "Blechkanne"
SWEP.Instructions = "Left click to let it rain Props in a certain area"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Weight = 5
SWEP.AutoSwitchTo = true
SWEP.AutoSwitchFrom = false
SWEP.Slot = 4
SWEP.SlotPos = 4
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/weapons/c_slam.mdl"
SWEP.UseHands = true
SWEP.ShootSound = Sound("Weapon_Mortar.Incomming")

-- TTT Customisation
if (engine.ActiveGamemode() == "terrortown") then
	SWEP.Base = "weapon_tttbase"
	SWEP.Kind = WEAPON_EQUIP1
	SWEP.AutoSpawnable = false
	SWEP.CanBuy = { ROLE_TRAITOR, ROLE_JACKAL }
	SWEP.LimitedStock = true
	SWEP.Slot = 7
	SWEP.Icon = "VGUI/ttt/icon_prop_rain.vtf"

	-- The information shown in the buy menu
	SWEP.EquipMenuData = {
		type = "item_weapon",
		name = "Prop Rain",
		desc = [[IT IS RAINING PROPS!
Left Click to let it rain some props on your foes]]
	}

end

if SERVER then
	AddCSLuaFile()
	resource.AddFile("materials/vgui/ttt/blue_template_icon.vmt")
end

local max_height = 1000
local lowest_height = 200
local height = max_height
local power = -400000
local spreading = 1000
local hitpos = Vector(0,0,0)

local side_length = GetConVar( "ttt_proprain_sidelength" ):GetInt() or 300
local proptimer = GetConVar("ttt_proprain_proptimer"):GetInt() or 100
local iterations = GetConVar("ttt_proprain_iterations"):GetInt() or 30
local despawn_props = GetConVar("ttt_proprain_despawn_props"):GetBool() or 0
local despawn_props_seconds = GetConVar("ttt_proprain_despawn_seconds"):GetInt() or 5


function SWEP:PrimaryAttack()
	local owner             = self:GetOwner()
	local eyetrace          = owner:GetEyeTrace()
	local traceup           = util.QuickTrace(eyetrace.HitPos, Vector(0, 0, max_height))
	local distance_to_hit   = max_height * traceup.Fraction
	local fireable          = false

	hitpos = eyetrace.HitPos

	if eyetrace.HitSky or traceup.Hit then
		if distance_to_hit < lowest_height then
			fireable = false
		else
			fireable = true
			height = distance_to_hit * 0.9
		end
	else
		fireable = true
		height = max_height * 0.9
	end

	if not fireable then return end

	self:SetNextPrimaryFire(CurTime() + 0.5)
	self:StartPropRain()

	if CLIENT then return end
	self:Remove()
end

function SWEP:SecondaryAttack()
end

function SWEP:StartPropRain()
	self:EmitSound( self.ShootSound )
	if CLIENT then return end

	timer.Create("timer_spawn_prop", proptimer / 1000, iterations, function() SpawnProp() end)
end

function SpawnProp()
	local prop_table = {
		"models/props_c17/FurnitureCouch001a.mdl",
		"models/props_c17/bench01a.mdl",
		"models/props_c17/chair02a.mdl",
		"models/props_c17/oildrum001.mdl",
		"models/props_c17/oildrum001_explosive.mdl",
		"models/props_c17/FurnitureCouch002a.mdl",
		"models/props_junk/PopCan01a.mdl",
		"models/props_junk/MetalBucket01a.mdl",
		"models/props_junk/watermelon01.mdl",
		"models/props_junk/wood_crate001a.mdl",
		"models/props_junk/PlasticCrate01a.mdl",
		"models/props_c17/doll01.mdl",
		"models/props_lab/monitor01a.mdl"
	};
	local ent = ents.Create("prop_physics");
	if not ent:IsValid() then return end

	local randompos = Vector(math.random(-side_length, side_length), math.random(-side_length, side_length), height)
	randompos:Add(hitpos);

	ent:SetModel(prop_table[math.random(table.maxn(prop_table))])
	ent:SetPos(randompos)
	ent:SetAngles(AngleRand())
	ent:Spawn()


	local phys = ent:GetPhysicsObject()
	-- Entity Removal
	if not phys:IsValid() then ent:Remove() return end
	if despawn_props then timer.Simple(despawn_props_seconds, function()
		if not IsValid(ent) then return end
		ent:Remove()
	end) end

	local force = Vector(math.random(-spreading, spreading), math.random(-spreading, spreading), power)
	phys:ApplyForceCenter(force)
end

local material = Material("vgui/white")
local mat_color = Color(255, 0, 0, 30)
local draw_warning = false

function SWEP:PostDrawViewModel()
	if CLIENT then
		local player            = LocalPlayer()
		local eyetrace          = player:GetEyeTrace()
		local traceup           = util.QuickTrace(eyetrace.HitPos, Vector(0, 0, max_height))
		local distance_to_hit   = max_height * traceup.Fraction

		if (eyetrace.HitSky or traceup.Hit) and (distance_to_hit < lowest_height) then
			mat_color = Color(255, 0, 0, 30)
			draw_warning = true
		else
			height = max_height * 0.9
			mat_color = Color(0, 255, 0, 30)
			draw_warning = false
		end

		cam.Start3D()
		render.SetMaterial(material)
		render.SetColorMaterial()
		render.DrawBox(eyetrace.HitPos, Angle(0, 0, 0), -Vector(side_length / 2, side_length / 2, 0),Vector(side_length / 2, side_length / 2, 5), mat_color)
		render.DrawWireframeBox(eyetrace.HitPos, Angle(0, 0, 0), -Vector(side_length / 2, side_length / 2, 0),Vector(side_length / 2, side_length / 2, 5), mat_color, true)
		cam.End3D()
	end
end

function SWEP:DrawHUD()
	if CLIENT and draw_warning then
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 0, 0)
		surface.SetTextPos(ScrW() / 2 + 20, ScrH() / 2 - 10)
		surface.DrawText("Not enough space to the ceiling")
	end
end

if CLIENT then
	function SWEP:AddToSettingsMenu(parent)
		local form = vgui.CreateTTT2Form(parent, "prop_rain_addon_header")

		form:MakeHelp({
			label = "prop_rain_help_menu"
		})

		form:MakeCheckBox({
			label = "label_proprain_despawn_props",
			serverConvar = "ttt_proprain_despawn_props"
		})

		form:MakeSlider({
			label = "label_roprain_despawn_seconds",
			serverConvar = "ttt_proprain_despawn_seconds",
			min = 1,
			max = 60,
			decimal = 0
		})

		form:MakeSlider({
			label = "label_proprain_sidelength",
			serverConvar = "ttt_proprain_sidelength",
			min = 1,
			max = 2000,
			decimal = 0
		})

		form:MakeSlider({
			label = "label_proprain_proptimer",
			serverConvar = "ttt_proprain_proptimer",
			min = 50,
			max = 500,
			decimal = 0
		})

		form:MakeSlider({
			label = "label_proprain_iterations",
			serverConvar = "ttt_proprain_iterations",
			min = 1,
			max = 200,
			decimal = 0
		})
	end
end

cvars.AddChangeCallback("ttt_proprain_sidelength", function(cv, old, new)
	side_length = tonumber(new)
end)

cvars.AddChangeCallback("ttt_proprain_proptimer", function(cv, old, new)
	proptimer = tonumber(new)
end)

cvars.AddChangeCallback("ttt_proprain_iterations", function(cv, old, new)
	iterations = tonumber(new)
end)

cvars.AddChangeCallback("ttt_proprain_despawn_props", function(cv, old, new)
	despawn_props = tobool(new)
end)

cvars.AddChangeCallback("ttt_proprain_despawn_seconds", function(cv, old, new)
	despawn_props_seconds = tonumber(new)
end)
