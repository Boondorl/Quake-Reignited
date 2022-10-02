/************************************************************************************
***  Copyright (C) 1996-1997  Id Software, Inc.
***  Modifications Copyright (C) 2022  Boondorl
***
***  This program is free software: you can redistribute it and/or modify
***  it under the terms of the GNU General Public License as published by
***  the Free Software Foundation, either version 3 of the License, or
***  (at your option) any later version.
***
***  This program is distributed in the hope that it will be useful,
***  but WITHOUT ANY WARRANTY; without even the implied warranty of
***  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
***  GNU General Public License for more details.
***
***  You should have received a copy of the GNU General Public License
***  along with this program. If not, see https://www.gnu.org/licenses/gpl-3.0.html.
***
***  See file 'LICENSE' for details.
************************************************************************************/
void() W_SetCurrentAmmo;
/* ALL LIGHTS SHOULD BE 0 1 0 IN COLOR ALL OTHER ITEMS SHOULD
BE .8 .3 .4 IN COLOR */


void() SUB_regen =
{
	// restore original model
	self.model = self.mdl;
	// allow it to be touched again
	self.solid = SOLID_TRIGGER;
	// play respawn sound
	sound (self, CHAN_VOICE, "items/itembk2.wav", 1, ATTN_NORM);
	setorigin (self, self.origin);
};



/*QUAKED noclass (0 0 0) (-8 -8 -8) (8 8 8)
prints a warning message when spawned
*/
void() noclass =
{
	dprint ("noclass spawned at");
	dprint (vtos(self.origin));
	dprint ("\n");
	remove (self);
};

void(entity targ) AddPickedUp =
{
	if (targ.classname != "player")
		return;
	
	local entity t = spawn();
	t.special_ent = targ;
	
	if (!self.special_ent)
		self.special_ent = t;
	else
	{
		local entity cur = self.special_ent;
		while (cur.chain)
			cur = cur.chain;
		
		cur.chain = t;
	}
};

float(entity targ) AlreadyPickedUp = 
{
	if (targ.classname != "player")
		return TRUE;
	
	if (!self.special_ent)
		return FALSE;
	
	local entity cur = self.special_ent;
	while (cur)
	{
		if (cur.special_ent == targ)
			return TRUE;
		
		cur = cur.chain;
	}
	
	return FALSE;
};

/*
============
PlaceItem

plants the object on the floor
============
*/
void() PlaceItem =
{
	local float oldz;

	// so it can be restored on respawn
	self.mdl = self.model;
	// make extra wide
	self.flags = FL_ITEM;
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_TOSS;
	self.velocity = '0 0 0';
	self.origin_z = self.origin_z + 6;
	oldz = self.origin_z;
	if (!droptofloor())
	{
		dprint ("Bonus item fell out of level at ");
		dprint (vtos(self.origin));
		dprint ("\n");
		remove(self);
		return;
	}
};

/*
============
StartItem

Sets the clipping size and plants the object on the floor
============
*/
void() StartItem =
{
	self.nextthink = time + 0.2;	// items start after other solids
	self.think = PlaceItem;
};

/*
=========================================================================

HEALTH BOX

=========================================================================
*/
//
// T_Heal: add health to an entity, limiting health to max_health
// "ignore" will ignore max_health limit
//
float (entity e, float healamount, float ignore) T_Heal =
{
	if (e.health <= 0 || (!ignore && e.health >= e.max_health))
		return FALSE;
	
	e.health += ceil(healamount);
	if (!ignore && e.health > e.max_health)
		e.health = e.max_health;

	if (e.health > MAX_HEALTH)
		e.health = MAX_HEALTH;
	
	return TRUE;
};

/*QUAKED item_health (.3 .3 1) (0 0 0) (32 32 32) rotten megahealth
Health box. Normally gives 25 points.
Rotten box heals 5-10 points,
megahealth will add 100 health, then
rot you down to your maximum health limit,
one point per second.
*/

float	H_ROTTEN = 1;
float	H_MEGA = 2;
.float	healamount, healtype;
void() health_touch;
void() item_megahealth_rot;

void() item_health =
{
	self.touch = health_touch;

	if (self.spawnflags & H_ROTTEN)
	{
		precache_model("maps/b_bh10.bsp");

		precache_sound("items/r_item1.wav");
		setmodel(self, "maps/b_bh10.bsp");
		self.noise = "items/r_item1.wav";
		self.healamount = 10;
		self.healtype = 0;
	}
	else if (self.spawnflags & H_MEGA)
	{
		precache_model("maps/b_bh100.bsp");
		precache_sound("items/r_item2.wav");
		setmodel(self, "maps/b_bh100.bsp");
		self.noise = "items/r_item2.wav";
		self.healamount = 50;
		self.healtype = 2;
	}
	else
	{
		precache_model("maps/b_bh25.bsp");
		precache_sound("items/health1.wav");
		setmodel(self, "maps/b_bh25.bsp");
		self.noise = "items/health1.wav";
		self.healamount = 25;
		self.healtype = 1;
	}
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};


void() health_touch =
{
	if (other.classname != "player")
		return;

	// Megahealth?  Ignore max_health...
	local float shouldstay = coop == 1 && self.healtype != 2;
	if (self.healtype == 2)
	{
		if (other.health >= MAX_HEALTH)
			return;
		if (!T_Heal(other, self.healamount, TRUE))
			return;
		
		sprint(other, "Picked up a Megahealth\n");
	}
	else
	{
		if (shouldstay)
		{
			if (AlreadyPickedUp(other))
				return;
		}
		
		if (!T_Heal(other, self.healamount, FALSE))
			return;

		sprint(other, "Restored ");
		sprint(other, ftos(self.healamount));
		sprint(other, " health\n");
	}

	// health touch sound
	sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM);

	stuffcmd (other, "bf\n");

	/*if (self.healtype == 2)
	{
		other.items |= IT_SUPERHEALTH;
		other.mega_finished = time + 5;
		self.owner = other;
	}
	else */if (deathmatch == 1)
	{
		self.nextthink = time + 20;
		self.think = SUB_regen;
	}

	activator = other;
	// fire all targets / killtargets
	SUB_UseTargets();
	if (!shouldstay || self.target != string_null)
	{
		self.model = string_null;
		self.solid = SOLID_NOT;
	}
	else if (shouldstay)
		AddPickedUp(other);
};

void() item_megahealth_rot =
{
	other = self.owner;

	if (other.health > other.max_health)
	{
		other.health = other.health - 1;
		self.nextthink = time + 1;
		return;
	}

	// it is possible for a player to die and respawn between rots, so don't
	// just blindly subtract the flag off
	other.items = other.items - (other.items & IT_SUPERHEALTH);

	// deathmatch 2 is silly old rules
	if (deathmatch == 1)
	{
		self.nextthink = time + 20;
		self.think = SUB_regen;
	}
};

/*
===============================================================================

ARMOR

===============================================================================
*/

void() armor_touch =
{
	if (other.health <= 0 || other.armorvalue >= self.armorvalue)
		return;
	if (other.classname != "player")
		return;
	
	local float shouldstay = coop == 1 && !self.aflag;
	if (shouldstay)
	{
		if (AlreadyPickedUp(other))
			return;
	}

	other.armortype = self.armortype;
	other.armorvalue = self.armorvalue;
	other.items -= (other.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3));
	other.items |= self.items;
	
	if (deathmatch == 1)
	{
		self.nextthink = time + 20;
		self.think = SUB_regen;
	}

	sprint(other, self.message);
	sprint(other, "\n");
	self.message = string_null;
	// armor touch sound
	sound(other, CHAN_ITEM, "items/armor1.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

	activator = other;
	// fire all targets / killtargets
	SUB_UseTargets();
	if (!shouldstay || self.target != string_null)
	{
		self.solid = SOLID_NOT;
		self.model = string_null;
	}
	else if (shouldstay)
		AddPickedUp(other);
};


/*QUAKED item_armor1 (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() item_armor1 =
{
	self.touch = armor_touch;
	self.message = "Picked up some worn down armor";
	self.armorvalue = LIGHT_ARMOR;
	self.armortype = LIGHT_ARMOR_TYPE;
	self.items = IT_ARMOR1;
	precache_model ("progs/armor.mdl");
	setmodel (self, "progs/armor.mdl");
	self.skin = 0;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED item_armor2 (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() item_armor2 =
{
	self.touch = armor_touch;
	self.message = "Picked up some armor";
	self.armorvalue = MEDIUM_ARMOR;
	self.armortype = MEDIUM_ARMOR_TYPE;
	self.items = IT_ARMOR2;
	precache_model ("progs/armor.mdl");
	setmodel (self, "progs/armor.mdl");
	self.skin = 1;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED item_armorInv (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() item_armorInv =
{
	self.touch = armor_touch;
	self.message = "Picked up some heavy armor";
	self.armorvalue = HEAVY_ARMOR;
	self.armortype = HEAVY_ARMOR_TYPE;
	self.items = IT_ARMOR3;
	self.aflag = TRUE;
	precache_model ("progs/armor.mdl");
	setmodel (self, "progs/armor.mdl");
	self.skin = 2;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*
===============================================================================

WEAPONS

===============================================================================
*/

void() bound_other_ammo =
{
	if (other.ammo_shells > SHELL_MAX)
		other.ammo_shells = SHELL_MAX;
	if (other.ammo_nails > NAIL_MAX)
		other.ammo_nails = NAIL_MAX;
	if (other.ammo_rockets > ROCKET_MAX)
		other.ammo_rockets = ROCKET_MAX;
	if (other.ammo_cells > CELL_MAX)
		other.ammo_cells = CELL_MAX;
};

float(entity e, float type) CheckAmmoPickup =
{
	if (type == IT_SHELLS)
		return e.ammo_shells < SHELL_MAX;
	if (type == IT_NAILS)
		return e.ammo_nails < NAIL_MAX;
	if (type == IT_ROCKETS)
		return e.ammo_rockets < ROCKET_MAX;
	if (type == IT_CELLS)
		return e.ammo_cells < CELL_MAX;
	
	return TRUE;
};

void(entity e, float type, float amt) AddAmmo =
{
	if (type == IT_SHELLS)
	{
		e.ammo_shells += amt;
		if (e.ammo_shells > SHELL_MAX)
			e.ammo_shells = SHELL_MAX;
	}
	else if (type == IT_NAILS)
	{
		e.ammo_nails += amt;
		if (e.ammo_nails > NAIL_MAX)
			e.ammo_nails = NAIL_MAX;
	}
	else if (type == IT_ROCKETS)
	{
		e.ammo_rockets += amt;
		if (e.ammo_rockets > ROCKET_MAX)
			e.ammo_rockets = ROCKET_MAX;
	}
	else if (type == IT_CELLS)
	{
		e.ammo_cells += amt;
		if (e.ammo_cells > CELL_MAX)
			e.ammo_cells = CELL_MAX;
	}
};


float(float w) RankForWeapon =
{
	if (w == IT_LIGHTNING)
		return 1;
	if (w == IT_ROCKET_LAUNCHER)
		return 2;
	if (w == IT_SUPER_NAILGUN)
		return 3;
	if (w == IT_GRENADE_LAUNCHER)
		return 4;
	if (w == IT_SUPER_SHOTGUN)
		return 5;
	if (w == IT_NAILGUN)
		return 6;
	return 7;
};

/*
=============
Deathmatch_Weapon

Deathmatch weapon change rules for picking up a weapon

.float		ammo_shells, ammo_nails, ammo_rockets, ammo_cells;
=============
*/
void(float old, float new) Deathmatch_Weapon =
{
	local float or, nr;

	// change self.weapon if desired
	or = RankForWeapon (self.weapon);
	nr = RankForWeapon (new);
	if ( nr < or )
		self.weapon = new;
};

/*
=============
weapon_touch
=============
*/
float() W_BestWeapon;

void() weapon_touch =
{
	if (other.health <= 0 || !(other.flags & FL_CLIENT))
		return;
	
	if (coop == 1)
	{
		if (AlreadyPickedUp(other))
			return;
	}
	
	if (other.items & self.weapon)
	{
		if (deathmatch == 2)
			return;
		if (!CheckAmmoPickup(other, self.aflag))
			return;
	}
	
	local float hadweap = other.items & self.weapon;
	other.items |= self.weapon;
	AddAmmo(other, self.aflag, self.cnt);
	
	local float weap = self.weapon;
	local entity o = self;
	
	self = other;
	if (!hadweap)
	{
		if (deathmatch)
			Deathmatch_Weapon(self.weapon, weap);
		else if (self.waterlevel <= 1 || weap != IT_LIGHTNING)
			self.weapon = weap;
	}
	
	W_SetCurrentAmmo();
	self = o;

	sprint (other, "Picked up a ");
	sprint (other, self.netname);
	sprint (other, "\n");
	// weapon touch sound
	sound (other, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	
	if (deathmatch == 1)
	{
		self.nextthink = time + 30;
		self.think = SUB_regen;
	}

	activator = other;
	SUB_UseTargets();			// fire all targets / killtargets
	if (coop != 1 || self.target != string_null)
	{
		self.model = string_null;
		self.solid = SOLID_NOT;
	}
	else if (coop == 1)
		AddPickedUp(other);
};


/*QUAKED weapon_supershotgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_supershotgun =
{
	precache_model ("progs/g_shot.mdl");
	setmodel (self, "progs/g_shot.mdl");
	self.weapon = IT_SUPER_SHOTGUN;
	self.aflag = IT_SHELLS;
	self.cnt = 4;
	self.netname = "Double-barrelled Shotgun";
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED weapon_nailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_nailgun =
{
	precache_model ("progs/g_nail.mdl");
	setmodel (self, "progs/g_nail.mdl");
	self.weapon = IT_NAILGUN;
	self.aflag = IT_NAILS;
	self.cnt = 30;
	self.netname = "Nailgun";
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED weapon_supernailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_supernailgun =
{
	precache_model ("progs/g_nail2.mdl");
	setmodel (self, "progs/g_nail2.mdl");
	self.weapon = IT_SUPER_NAILGUN;
	self.aflag = IT_NAILS;
	self.cnt = 30;
	self.netname = "Super Nailgun";
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED weapon_grenadelauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_grenadelauncher =
{
	precache_model ("progs/g_rock.mdl");
	setmodel (self, "progs/g_rock.mdl");
	self.weapon = IT_GRENADE_LAUNCHER;
	self.aflag = IT_ROCKETS;
	self.cnt = 2;
	self.netname = "Grenade Launcher";
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED weapon_rocketlauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_rocketlauncher =
{
	precache_model ("progs/g_rock2.mdl");
	setmodel (self, "progs/g_rock2.mdl");
	self.weapon = IT_ROCKET_LAUNCHER;
	self.aflag = IT_ROCKETS;
	self.cnt = 2;
	self.netname = "Rocket Launcher";
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};


/*QUAKED weapon_lightning (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_lightning =
{
	precache_model ("progs/g_light.mdl");
	setmodel (self, "progs/g_light.mdl");
	self.weapon = IT_LIGHTNING;
	self.aflag = IT_CELLS;
	self.cnt = 10;
	self.netname = "Thunderbolt";
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};


/*
===============================================================================

AMMO

===============================================================================
*/

void() ammo_touch =
{
	if (other.health <= 0)
		return;
	if (other.classname != "player")
		return;
	
	if (coop == 1)
	{
		if (AlreadyPickedUp(other))
			return;
	}
	
	if (!CheckAmmoPickup(other, self.aflag))
		return;
	
	AddAmmo(other, self.aflag, self.cnt);

	sprint (other, "Picked up ");
	sprint (other, ftos(self.cnt));
	sprint (other, " ");
	sprint (other, self.netname);
	if (self.cnt != 1)
		sprint(other, "s");
	sprint (other, "\n");
	
	// ammo touch sound
	sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	
	local entity o = self;
	self = other;
	
	W_SetCurrentAmmo();
	
	self = o;
	
	if (deathmatch == 1)
	{
		self.nextthink = time + 30;
		self.think = SUB_regen;
	}
	
	activator = other;
	// fire all targets / killtargets
	SUB_UseTargets();
	
	if (coop != 1 || self.target != string_null)
	{
		self.model = string_null;
		self.solid = SOLID_NOT;
	}
	else if (coop == 1)
		AddPickedUp(other);
};




float WEAPON_BIG2 = 1;

/*QUAKED item_shells (0 .5 .8) (0 0 0) (32 32 32) big
*/
void() item_shells =
{
	self.touch = ammo_touch;
	self.aflag = IT_SHELLS;
	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/b_shell1.bsp");
		setmodel (self, "maps/b_shell1.bsp");
		self.cnt = 30;
	}
	else
	{
		precache_model ("maps/b_shell0.bsp");
		setmodel (self, "maps/b_shell0.bsp");
		self.cnt = 15;
	}
	self.weapon = 1;
	self.netname = "shell";
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};

/*QUAKED item_spikes (0 .5 .8) (0 0 0) (32 32 32) big
*/
void() item_spikes =
{
	self.touch = ammo_touch;
	self.aflag = IT_NAILS;
	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/b_nail1.bsp");
		setmodel (self, "maps/b_nail1.bsp");
		self.cnt = 50;
	}
	else
	{
		precache_model ("maps/b_nail0.bsp");
		setmodel (self, "maps/b_nail0.bsp");
		self.cnt = 25;
	}
	self.weapon = 2;
	self.netname = "nail";
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};

/*QUAKED item_rockets (0 .5 .8) (0 0 0) (32 32 32) big
*/
void() item_rockets =
{
	self.touch = ammo_touch;
	self.aflag = IT_ROCKETS;
	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/b_rock1.bsp");
		setmodel (self, "maps/b_rock1.bsp");
		self.cnt = 4;
	}
	else
	{
		precache_model ("maps/b_rock0.bsp");
		setmodel (self, "maps/b_rock0.bsp");
		self.cnt = 2;
	}
	self.weapon = 3;
	self.netname = "rocket";
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};


/*QUAKED item_cells (0 .5 .8) (0 0 0) (32 32 32) big
*/
void() item_cells =
{
	self.touch = ammo_touch;
	self.aflag = IT_CELLS;
	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/b_batt1.bsp");
		setmodel (self, "maps/b_batt1.bsp");
		self.cnt = 15;
	}
	else
	{
		precache_model ("maps/b_batt0.bsp");
		setmodel (self, "maps/b_batt0.bsp");
		self.cnt = 10;
	}
	self.weapon = 4;
	self.netname = "cell";
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};


/*QUAKED item_weapon (0 .5 .8) (0 0 0) (32 32 32) shotgun rocket spikes big
DO NOT USE THIS!!!! IT WILL BE REMOVED!
*/

float WEAPON_SHOTGUN = 1;
float WEAPON_ROCKET = 2;
float WEAPON_SPIKES = 4;
float WEAPON_BIG = 8;
void() item_weapon =
{
	self.touch = ammo_touch;

	if (self.spawnflags & WEAPON_SHOTGUN)
	{
		self.aflag = IT_SHELLS;
		if (self.spawnflags & WEAPON_BIG)
		{
			precache_model ("maps/b_shell1.bsp");
			setmodel (self, "maps/b_shell1.bsp");
			self.cnt = 30;
		}
		else
		{
			precache_model ("maps/b_shell0.bsp");
			setmodel (self, "maps/b_shell0.bsp");
			self.cnt = 15;
		}
		self.weapon = 1;
		self.netname = "shell";
	}
	else if (self.spawnflags & WEAPON_SPIKES)
	{
		self.aflag = IT_NAILS;
		if (self.spawnflags & WEAPON_BIG)
		{
			precache_model ("maps/b_nail1.bsp");
			setmodel (self, "maps/b_nail1.bsp");
			self.cnt = 50;
		}
		else
		{
			precache_model ("maps/b_nail0.bsp");
			setmodel (self, "maps/b_nail0.bsp");
			self.cnt = 25;
		}
		self.weapon = 2;
		self.netname = "nail";
	}
	else if (self.spawnflags & WEAPON_ROCKET)
	{
		self.aflag = IT_ROCKETS;
		if (self.spawnflags & WEAPON_BIG)
		{
			precache_model ("maps/b_rock1.bsp");
			setmodel (self, "maps/b_rock1.bsp");
			self.cnt = 4;
		}
		else
		{
			precache_model ("maps/b_rock0.bsp");
			setmodel (self, "maps/b_rock0.bsp");
			self.cnt = 2;
		}
		self.weapon = 3;
		self.netname = "rocket";
	}

	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};


/*
===============================================================================

KEYS

===============================================================================
*/

void() key_touch =
{
	if (other.health <= 0 || (other.items & self.items))
		return;
	if (other.classname != "player")
		return;

	sprint (other, "Picked up a ");
	sprint (other, self.netname);
	sprint (other,"\n");

	sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	other.items |= self.items;

	if (!coop)
	{
		self.solid = SOLID_NOT;
		self.model = string_null;
	}

	activator = other;
	SUB_UseTargets();
};


void() key_setsounds =
{
	if (world.worldtype == 0)
	{
		precache_sound ("misc/medkey.wav");
		self.noise = "misc/medkey.wav";
	}
	if (world.worldtype == 1)
	{
		precache_sound ("misc/runekey.wav");
		self.noise = "misc/runekey.wav";
	}
	if (world.worldtype == 2)
	{
		precache_sound2 ("misc/basekey.wav");
		self.noise = "misc/basekey.wav";
	}
};

/*QUAKED item_key1 (0 .5 .8) (-16 -16 -24) (16 16 32)
SILVER key
In order for keys to work
you MUST set your maps
worldtype to one of the
following:
0: medieval
1: metal
2: base
*/

void() item_key1 =
{
	if (world.worldtype == 0)
	{
		precache_model ("progs/w_s_key.mdl");
		setmodel (self, "progs/w_s_key.mdl");
		self.netname = "silver key";
	}
	else if (world.worldtype == 1)
	{
		precache_model ("progs/m_s_key.mdl");
		setmodel (self, "progs/m_s_key.mdl");
		self.netname = "silver runekey";
	}
	else if (world.worldtype == 2)
	{
		precache_model2 ("progs/b_s_key.mdl");
		setmodel (self, "progs/b_s_key.mdl");
		self.netname = "silver keycard";
	}
	key_setsounds();
	self.touch = key_touch;
	self.items = IT_KEY1;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};

/*QUAKED item_key2 (0 .5 .8) (-16 -16 -24) (16 16 32)
GOLD key
In order for keys to work
you MUST set your maps
worldtype to one of the
following:
0: medieval
1: metal
2: base
*/

void() item_key2 =
{
	if (world.worldtype == 0)
	{
		precache_model ("progs/w_g_key.mdl");
		setmodel (self, "progs/w_g_key.mdl");
		self.netname = "gold key";
	}
	if (world.worldtype == 1)
	{
		precache_model ("progs/m_g_key.mdl");
		setmodel (self, "progs/m_g_key.mdl");
		self.netname = "gold runekey";
	}
	if (world.worldtype == 2)
	{
		precache_model2 ("progs/b_g_key.mdl");
		setmodel (self, "progs/b_g_key.mdl");
		self.netname = "gold keycard";
	}
	key_setsounds();
	self.touch = key_touch;
	self.items = IT_KEY2;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};



/*
===============================================================================

END OF LEVEL RUNES

===============================================================================
*/

void() sigil_touch =
{
	if (other.health <= 0)
		return;
	if (other.classname != "player")
		return;

	centerprint (other, "Picked up a rune");

	sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	self.solid = SOLID_NOT;
	self.model = string_null;
	serverflags |= (self.spawnflags & 15);
	// so rune doors won't find it
	self.classname = string_null;

	activator = other;
	SUB_UseTargets();
};


/*QUAKED item_sigil (0 .5 .8) (-16 -16 -24) (16 16 32) E1 E2 E3 E4
End of level sigil, pick up to end episode and return to jrstart.
*/

void() item_sigil =
{
	if (!self.spawnflags)
		objerror ("no spawnflags");

	precache_sound ("misc/runekey.wav");
	self.noise = "misc/runekey.wav";

	if (self.spawnflags & 1)
	{
		precache_model ("progs/end1.mdl");
		setmodel (self, "progs/end1.mdl");
	}
	if (self.spawnflags & 2)
	{
		precache_model2 ("progs/end2.mdl");
		setmodel (self, "progs/end2.mdl");
	}
	if (self.spawnflags & 4)
	{
		precache_model2 ("progs/end3.mdl");
		setmodel (self, "progs/end3.mdl");
	}
	if (self.spawnflags & 8)
	{
		precache_model2 ("progs/end4.mdl");
		setmodel (self, "progs/end4.mdl");
	}

	self.touch = sigil_touch;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};

/*
===============================================================================

POWERUPS

===============================================================================
*/

void() powerup_touch;


void() powerup_touch =
{
	if (other.health <= 0)
		return;
	if (other.classname != "player")
		return;

	sprint (other, self.message);
	sprint (other,"\n");
	self.message = string_null;

	if (deathmatch)
	{
		self.mdl = self.model;

		if ((self.classname == "item_artifact_invulnerability") ||
			(self.classname == "item_artifact_invisibility"))
			self.nextthink = time + 60*5;
		else
			self.nextthink = time + 60;

		self.think = SUB_regen;
	}

	sound (other, CHAN_VOICE, self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	self.solid = SOLID_NOT;
	other.items |= self.items;
	self.model = string_null;

	// do the appropriate action
	if (self.classname == "item_artifact_envirosuit")
	{
		other.rad_time = 1;
		other.radsuit_finished = time + 30;
	}
	else if (self.classname == "item_artifact_invulnerability")
	{
		other.invincible_time = 1;
		other.invincible_finished = time + 20;
	}
	else if (self.classname == "item_artifact_invisibility")
	{
		other.invisible_time = 1;
		other.invisible_finished = time + 30;
	}
	else if (self.classname == "item_artifact_super_damage")
	{
		other.super_time = 1;
		other.super_damage_finished = time + 30;
	}

	activator = other;
	SUB_UseTargets();
};



/*QUAKED item_artifact_invulnerability (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is invulnerable for 20 seconds
*/
void() item_artifact_invulnerability =
{
	self.touch = powerup_touch;

	precache_model ("progs/invulner.mdl");
	precache_sound ("items/protect.wav");
	precache_sound ("items/protect2.wav");
	precache_sound ("items/protect3.wav");
	self.noise = "items/protect.wav";
	setmodel (self, "progs/invulner.mdl");
	self.netname = "Pentagram of Protection";
	self.message = "The pentagram shields you from harm";
	self.items = IT_INVULNERABILITY;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};

/*QUAKED item_artifact_envirosuit (0 .5 .8) (-16 -16 -24) (16 16 32)
Player takes no damage from water or slime for 30 seconds
*/
void() item_artifact_envirosuit =
{
	self.touch = powerup_touch;

	precache_model ("progs/suit.mdl");
	precache_sound ("items/suit.wav");
	precache_sound ("items/suit2.wav");
	self.noise = "items/suit.wav";
	setmodel (self, "progs/suit.mdl");
	self.netname = "Biosuit";
	self.message = "The suit protects you from hazards";
	self.items = IT_SUIT;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};


/*QUAKED item_artifact_invisibility (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is invisible for 30 seconds
*/
void() item_artifact_invisibility =
{
	self.touch = powerup_touch;

	precache_model ("progs/invisibl.mdl");
	precache_sound ("items/inv1.wav");
	precache_sound ("items/inv2.wav");
	precache_sound ("items/inv3.wav");
	self.noise = "items/inv1.wav";
	setmodel (self, "progs/invisibl.mdl");
	self.netname = "Ring of Shadows";
	self.message = "The ring cloaks you in darkness";
	self.items = IT_INVISIBILITY;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};


/*QUAKED item_artifact_super_damage (0 .5 .8) (-16 -16 -24) (16 16 32)
The next attack from the player will do 4x damage
*/
void() item_artifact_super_damage =
{
	self.touch = powerup_touch;

	precache_model ("progs/quaddama.mdl");
	precache_sound ("items/damage.wav");
	precache_sound ("items/damage2.wav");
	precache_sound ("items/damage3.wav");
	self.noise = "items/damage.wav";
	setmodel (self, "progs/quaddama.mdl");
	self.netname = "Damage Amplifier";
	self.message = "The amplifier's power surges through you";
	self.items = IT_QUAD;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};



/*
===============================================================================

PLAYER BACKPACKS

===============================================================================
*/

void() BackpackTouch =
{
	if (other.health <= 0)
		return;
	if (other.classname != "player")
		return;
	
	// nothing to pick up
	local float nopickup = (other.items & self.items) == self.items;
	if (nopickup)
	{
		nopickup &= (self.ammo_shells <= 0 || !CheckAmmoPickup(other, IT_SHELLS));
		if (nopickup)
		{
			nopickup &= (self.ammo_nails <= 0 || !CheckAmmoPickup(other, IT_NAILS));
			if (nopickup)
			{
				nopickup &= (self.ammo_rockets <= 0 || !CheckAmmoPickup(other, IT_ROCKETS));
				if (nopickup)
					nopickup &= (self.ammo_cells <= 0 || !CheckAmmoPickup(other, IT_CELLS));
			}
		}
	}
	
	if (nopickup)
		return;

	other.items |= self.items;
	AddAmmo(other, IT_SHELLS, self.ammo_shells);
	AddAmmo(other, IT_NAILS, self.ammo_nails);
	AddAmmo(other, IT_ROCKETS, self.ammo_rockets);
	AddAmmo(other, IT_CELLS, self.ammo_cells);
	
	local entity o = self;
	self = other;
	
	W_SetCurrentAmmo();
	
	self = o;

	if (!(self.ammo_shells + self.ammo_nails + self.ammo_rockets + self.ammo_cells))
		sprint(other, "Picked up a backpack full of weapons\n");
	else
	{
		local float acount;
		sprint(other, "Picked up ");
		if (self.ammo_shells > 0)
		{
			acount = TRUE;
			sprint (other, ftos(self.ammo_shells));
			if (self.ammo_shells == 1)
				sprint(other, " shell");
			else
				sprint (other, " shells");
		}
		if (self.ammo_nails > 0)
		{
			if (acount)
				sprint(other, ", ");
			
			acount = TRUE;
			sprint (other, ftos(self.ammo_nails));
			if (self.ammo_nails == 1)
				sprint(other, " nail");
			else
				sprint (other, " nails");
		}
		if (self.ammo_rockets > 0)
		{
			if (acount)
				sprint(other, ", ");
			
			acount = TRUE;
			sprint (other, ftos(self.ammo_rockets));
			if (self.ammo_rockets == 1)
				sprint(other, " rocket");
			else
				sprint (other, " rockets");
		}
		if (self.ammo_cells > 0)
		{
			if (acount)
				sprint(other, ", and ");
			
			sprint (other, ftos(self.ammo_cells));
			if (self.ammo_cells == 1)
				sprint(other, " cell");
			else
				sprint (other, " cells");
		}

		sprint (other, "\n");
	}
	
	// backpack touch sound
	sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

	// remove the backpack
	remove(self);
};

/*
===============
DropBackpack
===============
*/
// only add weapons that can actually be picked up
float WORLD_WEAPONS = IT_SUPER_SHOTGUN|IT_NAILGUN|IT_SUPER_NAILGUN|IT_GRENADE_LAUNCHER|IT_ROCKET_LAUNCHER|IT_LIGHTNING;

void() DropBackpack =
{
	if (coop == 1)
	{
		if (self.classname == "player")
			return;
	}
	
	local float weapons = self.items & WORLD_WEAPONS;
	if (!weapons && !(self.ammo_shells + self.ammo_nails + self.ammo_rockets + self.ammo_cells))
		// nothing in it
		return;

	local entity item = spawn();
	item.origin = self.origin - '0 0 24';
	item.netname = "Backpack";

	item.items = weapons;
	item.ammo_shells = self.ammo_shells;
	item.ammo_nails = self.ammo_nails;
	item.ammo_rockets = self.ammo_rockets;
	item.ammo_cells = self.ammo_cells;

	item.velocity_z = 300;
	item.velocity_x = -100 + (random() * 200);
	item.velocity_y = -100 + (random() * 200);

	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_TOSS;
	setmodel (item, "progs/backpack.mdl");
	setsize (item, '-16 -16 0', '16 16 56');
	item.touch = BackpackTouch;
};
