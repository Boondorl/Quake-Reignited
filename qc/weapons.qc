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

void (entity targ, entity inflictor, entity attacker, float damage, float pain, float ignore_armor) T_Damage;
void () player_run;
void(entity inflictor, entity attacker, float max_damage, float min_damage, float dist, float pain, entity impact) T_RadiusDamage;
void(vector org, vector vel, float damage) SpawnBlood;
void() SuperDamageSound;


// called by worldspawn
void() W_Precache =
{
	precache_sound ("weapons/r_exp3.wav");	// new rocket explosion
	precache_sound ("weapons/rocket1i.wav");	// spike gun
	precache_sound ("weapons/sgun1.wav");
	precache_sound ("weapons/guncock.wav");	// player shotgun
	precache_sound ("weapons/ric1.wav");	// ricochet (used in c code)
	precache_sound ("weapons/ric2.wav");	// ricochet (used in c code)
	precache_sound ("weapons/ric3.wav");	// ricochet (used in c code)
	precache_sound ("weapons/spike2.wav");	// super spikes
	precache_sound ("weapons/tink1.wav");	// spikes tink (used in c code)
	precache_sound ("weapons/grenade.wav");	// grenade launcher
	precache_sound ("weapons/bounce.wav");		// grenade bounce
	precache_sound ("weapons/shotgn2.wav");	// super shotgun
};

float() crandom =
{
	return 2*(random() - 0.5);
};

/*
================
GetAimDirection

Find out where the player is looking.
================
*/
vector(vector orig, float auto_aim_range) GetAimDirection =
{
	makevectors(self.v_angle);
	
	local vector dir;
	if (auto_aim_range > 0)
		dir = aim(self, auto_aim_range);
	else
		dir = v_forward;
	
	local vector start = self.origin + self.view_ofs;
	traceline(start, start + dir*3000, TRUE, self);
	return normalize(trace_endpos - orig);
};

/*
================
W_FireAxe
================
*/
void() W_FireAxe =
{
	makevectors (self.v_angle);
	
	local vector source = self.origin + self.view_ofs;
	traceline (source, source + v_forward*64, FALSE, self);
	if (trace_fraction == 1)
		return;
	
	if (self.invisible_finished > time)
		self.show_hostile = time + 0.1;
	else
		self.show_hostile = time + 1;

	local vector org = trace_endpos - v_forward*4;
	if (trace_ent.takedamage)
	{
		trace_ent.axhitme = 1;
		SpawnBlood (org, '0 0 0', 20);
		local float damage = 54;
		if (trace_ent.is_zombie)
			damage *= 0.5;
		
		T_Damage (trace_ent, self, self, damage, 75, FALSE);
	}
	else
	{	// hit wall
		sound (self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM);
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
	}
};


//============================================================================


vector() wall_velocity =
{
	local vector vel;

	vel = normalize (self.velocity);
	vel = normalize(vel + v_up*(random()- 0.5) + v_right*(random()- 0.5));
	vel = vel + 2*trace_plane_normal;
	vel = vel * 200;

	return vel;
};


/*
================
SpawnMeatSpray
================
*/
void(vector org, vector vel) SpawnMeatSpray =
{
	local entity missile;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_NOT;

	makevectors (self.angles);

	missile.velocity = vel;
	missile.velocity_z = missile.velocity_z + 250 + 50*random();

	missile.avelocity = '3000 1000 2000';

	// set missile duration
	missile.nextthink = time + 1;
	missile.think = SUB_Remove;

	setmodel (missile, "progs/zom_gib.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, org);
};

/*
================
SpawnBlood
================
*/
void(vector org, vector vel, float damage) SpawnBlood =
{
	particle (org, vel*0.1, 73, damage*2);
};

/*
================
spawn_touchblood
================
*/
void(float damage) spawn_touchblood =
{
	local vector vel;

	vel = wall_velocity () * 0.2;
	SpawnBlood (self.origin + vel*0.01, vel, damage);
};


/*
================
SpawnChunk
================
*/
void(vector org, vector vel) SpawnChunk =
{
	particle (org, vel*0.02, 0, 10);
};

/*
==============================================================================

MULTI-DAMAGE

Collects multiple small damages into a single damage

==============================================================================
*/

entity multi_ent;
float multi_damage;

void() ClearMultiDamage =
{
	multi_ent = world;
	multi_damage = 0;
};

void() ApplyMultiDamage =
{
	if (!multi_ent)
		return;
	T_Damage (multi_ent, self, self, multi_damage, 0, FALSE);
};

void(entity hit, float damage) AddMultiDamage =
{
	if (!hit)
		return;

	if (hit != multi_ent)
	{
		ApplyMultiDamage ();
		multi_damage = damage;
		multi_ent = hit;
	}
	else
		multi_damage = multi_damage + damage;
};

/*
==============================================================================

BULLETS

==============================================================================
*/

/*
================
TraceAttack
================
*/
void(float damage, vector dir) TraceAttack =
{
	local vector vel, org;

	vel = normalize(dir + v_up*crandom() + v_right*crandom());
	vel = vel + 2*trace_plane_normal;
	vel = vel * 200;

	org = trace_endpos - dir*4;

	if (trace_ent.takedamage)
	{
		SpawnBlood (org, vel*0.2, damage);
		AddMultiDamage (trace_ent, damage);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
	}
};

/*
================
FireBullets

Used by shotgun, super shotgun, and enemy soldier firing
Go to the trouble of combining multiple pellets into a single damage call.
================
*/
void(float shotcount, vector dir, vector spread) FireBullets =
{
	local vector direction;
	local vector src;

	makevectors(self.v_angle);

	src = self.origin + v_forward*10;
	src_z = self.absmin_z + self.size_z * 0.7;

	ClearMultiDamage ();
	while (shotcount > 0)
	{
		direction = dir + crandom()*spread_x*v_right + crandom()*spread_y*v_up;

		traceline (src, src + direction*2048, FALSE, self);
		if (trace_fraction != 1.0)
			TraceAttack (4, direction);

		shotcount = shotcount - 1;
	}
	ApplyMultiDamage ();
};

/*
================
Enhanced pellet functionality
================
*/
void() T_PelletTouch =
{
	if (other == self.owner)
		return;		// don't explode on owner

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	
	if (other.takedamage)
	{
		local float damage = 4;
		local vector vel = normalize(self.fast_velocity);
		SpawnBlood(self.origin - vel*4, vel*40, damage);
		
		if (other.is_zombie)
			damage *= 0.5;
		
		T_Damage(other, self, self.owner, damage, 5.6, FALSE);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}
	
	remove(self);
};

void() FastProjectileThink =
{
	if (self.special <= time)
	{
		remove(self);
		return;
	}
	
	self.nextthink = time; // Update as fast as possible
	
	traceline (self.origin, self.origin + self.fast_velocity*frametime, FALSE, self.owner);
	setorigin (self, trace_endpos);
	
	if (trace_fraction == 1)
		return;
	
	other = trace_ent;
	self.touch();
};

/*
================
PelletAttack

Alternative to TraceAttack that uses fast moving
projectiles instead of a tracer.
================
*/
void(vector src, vector dir) PelletAttack =
{
	local entity missile = spawn();
	missile.owner = self;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_BBOX;
	missile.classname = "pellet";
			
	missile.velocity = dir * 0.01; // forces internal collision checking (needed if inside entity)
	missile.fast_velocity = dir * 2000;
	missile.angles = vectoangles(missile.fast_velocity);
	
	missile.nextthink = time + 0.02; // Add a small initial delay to force a collision check at spawn
	missile.think = FastProjectileThink;
	missile.touch = T_PelletTouch;
	missile.special = time + 2;

	setmodel (missile, "progs/s_pellet.mdl");
	setsize (missile, VEC_ORIGIN, VEC_ORIGIN);		
	setorigin (missile, src);
};

void(float shotcount, float inner_shotcount, vector dir, vector spread) FirePellets =
{
	makevectors(self.v_angle);

	local vector src = self.origin + '0 0 15';
	local vector inner_spread = spread * 0.5;
	local vector direction;
	while (shotcount > 0)
	{
		local float x, y;
		do
		{
			x = crandom();
			y = crandom();
		} while (x*x + y*y > 1);
		
		if (inner_shotcount > 0)
		{
			direction = normalize(dir + x*inner_spread_x*v_right + y*inner_spread_y*v_up);
			--inner_shotcount;
		}
		else
			direction = normalize(dir + x*spread_x*v_right + y*spread_y*v_up);

		PelletAttack (src, direction);
		--shotcount;
	}
};

/*
================
W_FireShotgun
================
*/
void() W_FireShotgun =
{
	sound (self, CHAN_WEAPON, "weapons/guncock.wav", 1, ATTN_NORM);

	--self.ammo_shells;
	self.currentammo = self.ammo_shells;
	FirePellets(9, 5, GetAimDirection(self.origin+'0 0 15', 2000), '0.0629 0.0629 0');
	self.punchangle_x = -2;
};


/*
================
W_FireSuperShotgun
================
*/
void() W_FireSuperShotgun =
{
	sound (self ,CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);

	if (self.ammo_shells == 1)
	{
		--self.ammo_shells;
		FirePellets(9, 5, GetAimDirection(self.origin+'0 0 15', 2000), '0.0629 0.0629 0');
		self.punchangle_x = -2;
	}
	else
	{
		self.ammo_shells -= 2;
		FirePellets(18, 10, GetAimDirection(self.origin+'0 0 15', 2000), '0.1263 0.1263 0');
		self.punchangle_x = -4;
	}
	
	self.currentammo = self.ammo_shells;
};


/*
==============================================================================

ROCKETS

==============================================================================
*/

void()	s_explode1	=	[0,		s_explode2] {};
void()	s_explode2	=	[1,		s_explode3] {};
void()	s_explode3	=	[2,		s_explode4] {};
void()	s_explode4	=	[3,		s_explode5] {};
void()	s_explode5	=	[4,		s_explode6] {};
void()	s_explode6	=	[5,		SUB_Remove] {};

void() BecomeExplosion =
{
	self.movetype = MOVETYPE_NONE;
	self.velocity = '0 0 0';
	self.touch = SUB_Null;
	setmodel (self, "progs/s_explod.spr");
	self.solid = SOLID_NOT;
	s_explode1 ();
};

void() T_MissileTouch =
{
	if (other == self.owner)
		// don't explode on owner
		return;

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	T_Damage (other, self, self.owner, 50, 50, FALSE );
	T_RadiusDamage (self, self.owner, 50, 30, 160, 50, other);

	self.origin = self.origin - 8*normalize(self.velocity);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BecomeExplosion ();
};

/*
================
W_FireRocket
================
*/
void() W_FireRocket =
{
	makevectors (self.v_angle);

	--self.ammo_rockets;
	self.currentammo = self.ammo_rockets;

	sound (self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);

	self.punchangle_x = -2;

	local entity missile = FireProjectile(self.origin, GetAimDirection(self.origin, 1000), 1250, 3.5, "progs/missile.mdl");
	missile.classname = "missile";
	missile.touch = T_MissileTouch;
};

/*
===============================================================================

LIGHTNING

===============================================================================
*/

/*
=================
LightningDamage
=================
*/
void(vector p1, vector p2, entity from, float damage) LightningDamage =
{
	local entity e1, e2;
	local vector f;

	f = p2 - p1;
	normalize (f);
	f_x = 0 - f_y;
	f_y = f_x;
	f_z = 0;
	f = f*16;

	e1 = e2 = world;

	traceline (p1, p2, FALSE, self);
	if (trace_ent.takedamage)
	{
		particle (trace_endpos, '0 0 100', 225, damage*4);
		T_Damage (trace_ent, from, from, damage, 100, FALSE);
		if (self.classname == "player")
		{
			if (other.classname == "player")
				trace_ent.velocity_z = trace_ent.velocity_z + 400;
		}
	}
	e1 = trace_ent;

	traceline (p1 + f, p2 + f, FALSE, self);
	if (trace_ent != e1 && trace_ent.takedamage)
	{
		particle (trace_endpos, '0 0 100', 225, damage*4);
		T_Damage (trace_ent, from, from, damage, 100, FALSE);
	}
	e2 = trace_ent;

	traceline (p1 - f, p2 - f, FALSE, self);
	if (trace_ent != e1 && trace_ent != e2 && trace_ent.takedamage)
	{
		particle (trace_endpos, '0 0 100', 225, damage*4);
		T_Damage (trace_ent, from, from, damage, 100, FALSE);
	}
};

void(vector org, vector end, float dmg, float pain, float mindist, float mindmg, float minpain) LightningAttack =
{
	traceline(org, end, FALSE, self);
	SpawnLightning(self, org, trace_endpos);
	if (!trace_ent.takedamage)
		return;
	
	if ((trace_ent.flags & FL_MONSTER) && !trace_ent.is_boss)
	{
		trace_ent.in_pain = FALSE;
		trace_ent.pain_finished = 0;
	}
	
	particle (trace_endpos, '0 0 100', 225, dmg*4);
	T_Damage(trace_ent, self, self, dmg, pain, FALSE);
	
	if (mindist <= 0)
		return;
	
	local entity hit = trace_ent;
	local entity head = findradius(hit.origin, mindist);
	while (head)
	{
		if (!head.takedamage || head == hit || head == self
			|| ((head.flags & FL_MONSTER) && (self.flags & FL_MONSTER))
			|| (head.classname == "player" && self.classname == "player"))
		{
			head = head.chain;
			continue;
		}
			
		traceline(hit.origin, head.origin, TRUE, hit);
		if (trace_fraction == 1)
		{
			T_Damage(head, self, self, mindmg, minpain, FALSE);
			particle (trace_endpos, '0 0 100', 225, mindmg*4);
			SpawnLightning(head, hit.origin, trace_endpos);
		}
		
		head = head.chain;
	}
};


void() W_FireLightning =
{
	// explode if under water
	if (self.waterlevel > 1)
	{
		local float cells = self.ammo_cells;
		self.currentammo = self.ammo_cells = 0;
		T_RadiusDamage (self, self, 24*cells, 24*cells, 24*cells, 10000, world);
		return;
	}

	if (self.t_width < time)
	{
		sound (self, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM);
		self.t_width = time + 0.6;
	}
	self.punchangle_x = -2;

	--self.ammo_cells;
	self.currentammo = self.ammo_cells;
	
	makevectors(self.v_angle);
	local vector org = self.origin + '0 0 15';
	LightningAttack(org, org+GetAimDirection(org,600)*600, 24, 10000, 300, 12, 25);
};


//=============================================================================


void() GrenadeExplode =
{
	T_RadiusDamage (self, self.owner, 80, 60, 160, 50, self.special_ent);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BecomeExplosion ();
};

void() GrenadeTouch =
{
	if (other == self.owner)
		// don't explode on owner
		return;
	if (other.takedamage)
	{
		T_Damage(other, self, self.owner, 20, 25, FALSE);
		self.special_ent = other;
		GrenadeExplode();
		return;
	}
	// bounce sound
	sound (self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM);
	if (self.velocity == '0 0 0')
		self.avelocity = '0 0 0';
};

/*
================
W_FireGrenade
================
*/
void() W_FireGrenade =
{
	--self.ammo_rockets;
	self.currentammo = self.ammo_rockets;
	
	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);
	
	makevectors (self.v_angle);
	
	// 650 is used to keep a similar velocity to vanilla now that it rotates the tragectory
	local entity missile = FireProjectile(self.origin, GetAimDirection(self.origin, 1000), 650, 2.5, "progs/grenade.mdl");
	missile.classname = "grenade";
	missile.movetype = MOVETYPE_BOUNCE;
	missile.think = GrenadeExplode;
	missile.touch = GrenadeTouch;
	missile.avelocity = '300 300 300';
	
	local float p = missile.angles_x;
	if (p > 90) // thanks, Kex
		p -= 360;
	
	local float spd = vlen(missile.velocity);
	missile.velocity = normalize(missile.velocity/spd + v_up*0.364*(1 - fabs(p)/90)) * spd;
	missile.angles = vectoangles(missile.velocity);
	
	self.punchangle_x = -2;
};


//=============================================================================

void() spike_touch;
void() superspike_touch;


/*
===============
launch_spike

Used for both the player and the ogre
===============
*/
void(vector org, vector dir) launch_spike =
{
	newmis = spawn ();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;

	newmis.angles = vectoangles(dir);

	newmis.touch = spike_touch;
	newmis.classname = "spike";
	newmis.think = SUB_Remove;
	newmis.nextthink = time + 6;
	setmodel (newmis, "progs/spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
	setorigin (newmis, org);

	newmis.velocity = dir * 1000;
};

void(float o) W_FireSuperSpikes =
{
	makevectors (self.v_angle);
	
	sound (self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
	
	local vector dir = v_up;
	if (self.sng_barrel)
		dir = v_right;
	
	--self.ammo_nails;
	local vector orig = self.origin + '0 0 15';
	local entity missile = FireProjectile(orig+dir*o, GetAimDirection(orig, 1000), 1000, 6, "progs/s_spike.mdl");
	missile.classname = "spike";
	missile.touch = spike_touch;
	
	if (self.ammo_nails > 0)
	{
		--self.ammo_nails;
		missile = FireProjectile(orig-dir*o, GetAimDirection(orig, 1000), 1000, 6, "progs/s_spike.mdl");
		missile.classname = "spike";
		missile.touch = spike_touch;
	}
	
	self.punchangle_x = -2;
	self.currentammo = self.ammo_nails;
	self.sng_barrel = !self.sng_barrel;
	if (self.sng_step < 5)
		++self.sng_step;
};

void(float ox) W_FireSpikes =
{
	makevectors (self.v_angle);

	sound (self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
	
	--self.ammo_nails;
	self.currentammo = self.ammo_nails;
	if (self.ng_barrel)
		ox *= -1;
	
	local vector orig = self.origin + '0 0 15';
	local entity missile = FireProjectile(orig+v_right*ox, GetAimDirection(orig, 1000), 1250, 6, "progs/spike.mdl");
	missile.classname = "spike";
	missile.touch = spike_touch;

	self.punchangle_x = -2;
	self.ng_barrel = !self.ng_barrel;
};


void() spike_touch =
{
	if (other == self.owner)
		return;

	if (other.solid == SOLID_TRIGGER)
		// trigger field, do nothing
		return;

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	// hit something that bleeds
	if (other.takedamage)
	{
		spawn_touchblood (9);
		T_Damage (other, self, self.owner, 9, 9, FALSE);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);

		if (self.classname == "wizspike")
			WriteByte (MSG_BROADCAST, TE_WIZSPIKE);
		else if (self.classname == "knightspike")
			WriteByte (MSG_BROADCAST, TE_KNIGHTSPIKE);
		else
			WriteByte (MSG_BROADCAST, TE_SPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

	remove(self);

};

void() superspike_touch =
{
	if (other == self.owner)
		return;

	if (other.solid == SOLID_TRIGGER)
		// trigger field, do nothing
		return;

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	// hit something that bleeds
	if (other.takedamage)
	{
		spawn_touchblood (18);
		T_Damage (other, self, self.owner, 18, 18, FALSE);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_SUPERSPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

	remove(self);

};


/*
===============================================================================

PLAYER WEAPON USE

===============================================================================
*/

void() W_SetCurrentAmmo =
{
	local string model;

	self.items -= (self.items & (IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS));

	if (self.weapon == IT_AXE)
	{
		self.currentammo = 0;
		model = "progs/v_axe.mdl";
	}
	else if (self.weapon == IT_SHOTGUN)
	{
		self.currentammo = self.ammo_shells;
		model = "progs/v_shot.mdl";
		self.items |= IT_SHELLS;
	}
	else if (self.weapon == IT_SUPER_SHOTGUN)
	{
		self.currentammo = self.ammo_shells;
		model = "progs/v_shot2.mdl";
		self.items |= IT_SHELLS;
	}
	else if (self.weapon == IT_NAILGUN)
	{
		self.currentammo = self.ammo_nails;
		model = "progs/v_nail.mdl";
		self.items |= IT_NAILS;
	}
	else if (self.weapon == IT_SUPER_NAILGUN)
	{
		self.currentammo = self.ammo_nails;
		model = "progs/v_nail2.mdl";
		self.items |= IT_NAILS;
	}
	else if (self.weapon == IT_GRENADE_LAUNCHER)
	{
		self.currentammo = self.ammo_rockets;
		model = "progs/v_rock.mdl";
		self.items |= IT_ROCKETS;
	}
	else if (self.weapon == IT_ROCKET_LAUNCHER)
	{
		self.currentammo = self.ammo_rockets;
		model = "progs/v_rock2.mdl";
		self.items |= IT_ROCKETS;
	}
	else if (self.weapon == IT_LIGHTNING)
	{
		self.currentammo = self.ammo_cells;
		model = "progs/v_light.mdl";
		self.items |= IT_CELLS;
	}
	else
	{
		self.currentammo = 0;
		model = string_null;
	}
	
	if (model != self.weaponmodel)
	{
		self.sng_barrel = self.sng_step = self.special = 0;
		player_run ();
		self.weaponmodel = model;
		self.weaponframe = 0;
	}
};

float() W_BestWeapon =
{
	local float it;

	it = self.items;

	if (self.waterlevel <= 1 && self.ammo_cells >= 1 && (it & IT_LIGHTNING) )
		return IT_LIGHTNING;
	else if(self.ammo_nails >= 2 && (it & IT_SUPER_NAILGUN) )
		return IT_SUPER_NAILGUN;
	else if(self.ammo_shells >= 2 && (it & IT_SUPER_SHOTGUN) )
		return IT_SUPER_SHOTGUN;
	else if(self.ammo_nails >= 1 && (it & IT_NAILGUN) )
		return IT_NAILGUN;
	else if(self.ammo_shells >= 1 && (it & IT_SHOTGUN) )
		return IT_SHOTGUN;

	return IT_AXE;
};

float() W_CheckNoAmmo =
{
	if (self.currentammo > 0 || self.weapon == IT_AXE)
		return TRUE;

	self.weapon = W_BestWeapon ();
	W_SetCurrentAmmo();

	return FALSE;
};

/*
============
W_Attack

An attack impulse can be triggered now
============
*/
void()	player_axe1;
void()	player_axeb1;
void()	player_axec1;
void()	player_axed1;
void()	player_shot1;
void()	player_nail1;
void()  player_nail2;
void()	player_light1;
void()	player_rocket1;

void() W_Attack =
{
	local float r;

	if (!W_CheckNoAmmo ())
		return;

	// calculate forward angle for velocity
	makevectors(self.v_angle);
	// wake monsters up
	if (self.invisible_finished > time)
		self.show_hostile = time + 0.1;
	else
		self.show_hostile = time + 1;

	if (self.weapon == IT_AXE)
	{
		self.show_hostile = 0;
		sound (self, CHAN_WEAPON, "weapons/ax1.wav", 1, ATTN_NORM);
		r = random();
		if (r < 0.25)
			player_axe1 ();
		else if (r<0.5)
			player_axeb1 ();
		else if (r<0.75)
			player_axec1 ();
		else
			player_axed1 ();
		self.attack_finished = time + FRAME*37;
	}
	else if (self.weapon == IT_SHOTGUN)
	{
		player_shot1 ();
		W_FireShotgun ();
		self.attack_finished = time + FRAME*37;
	}
	else if (self.weapon == IT_SUPER_SHOTGUN)
	{
		player_shot1 ();
		W_FireSuperShotgun ();
		self.attack_finished = time + FRAME*50;
	}
	else if (self.weapon == IT_NAILGUN)
	{
		if (self.ng_barrel)
			player_nail2();
		else
			player_nail1();
	}
	else if (self.weapon == IT_SUPER_NAILGUN)
	{
		player_nail1 ();
	}
	else if (self.weapon == IT_GRENADE_LAUNCHER)
	{
		player_rocket1();
		W_FireGrenade();
		self.attack_finished = time + FRAME*42;
	}
	else if (self.weapon == IT_ROCKET_LAUNCHER)
	{
		player_rocket1();
		W_FireRocket();
		self.attack_finished = time + FRAME*57;
	}
	else if (self.weapon == IT_LIGHTNING)
	{
		sound (self, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_NORM);
		player_light1();
	}
};

/*
============
W_ChangeWeapon

============
*/
void() W_ChangeWeapon =
{
	local float it, am, fl;

	it = self.items;
	am = 0;
	fl = 0;

	if (self.impulse == 1)
	{
		fl = IT_AXE;
	}
	else if (self.impulse == 2)
	{
		fl = IT_SHOTGUN;
		if (self.ammo_shells < 1)
			am = 1;
	}
	else if (self.impulse == 3)
	{
		fl = IT_SUPER_SHOTGUN;
		if (self.ammo_shells < 1)
			am = 1;
	}
	else if (self.impulse == 4)
	{
		fl = IT_NAILGUN;
		if (self.ammo_nails < 1)
			am = 1;
	}
	else if (self.impulse == 5)
	{
		fl = IT_SUPER_NAILGUN;
		if (self.ammo_nails < 1)
			am = 1;
	}
	else if (self.impulse == 6)
	{
		fl = IT_GRENADE_LAUNCHER;
		if (self.ammo_rockets < 1)
			am = 1;
	}
	else if (self.impulse == 7)
	{
		fl = IT_ROCKET_LAUNCHER;
		if (self.ammo_rockets < 1)
			am = 1;
	}
	else if (self.impulse == 8)
	{
		fl = IT_LIGHTNING;
		if (self.ammo_cells < 1)
			am = 1;
	}

	self.impulse = 0;

	if (!(self.items & fl))
	{
		// don't have the weapon or the ammo
		sprint (self, "no weapon.\n");
		return;
	}

	if (am)
	{
		// don't have the ammo
		sprint (self, "not enough ammo.\n");
		return;
	}

	// set weapon, set ammo
	self.weapon = fl;
	W_SetCurrentAmmo ();
};

/*
============
CheatCommand
============
*/
void() CheatCommand =
{
	if (deathmatch)
		return;

	self.ammo_rockets = ROCKET_MAX;
	self.ammo_nails = NAIL_MAX;
	self.ammo_shells = SHELL_MAX;
	self.ammo_cells = CELL_MAX;
	self.items = self.items |
		IT_AXE |
		IT_SHOTGUN |
		IT_SUPER_SHOTGUN |
		IT_NAILGUN |
		IT_SUPER_NAILGUN |
		IT_GRENADE_LAUNCHER |
		IT_ROCKET_LAUNCHER |
		IT_LIGHTNING |
		IT_KEY1 | IT_KEY2;

	self.impulse = 0;
	W_SetCurrentAmmo();
};

/*
============
CycleWeaponCommand

Go to the next weapon with ammo
============
*/
void() CycleWeaponCommand =
{
	local float it, am;

	it = self.items;
	self.impulse = 0;

	while (1)
	{
		am = 0;
		
		if (self.weapon == IT_LIGHTNING)
		{
			self.weapon = IT_AXE;
		}
		else if (self.weapon == IT_AXE)
		{
			self.weapon = IT_SHOTGUN;
			if (self.ammo_shells < 1)
				am = 1;
		}
		else if (self.weapon == IT_SHOTGUN)
		{
			self.weapon = IT_SUPER_SHOTGUN;
			if (self.ammo_shells < 1)
				am = 1;
		}
		else if (self.weapon == IT_SUPER_SHOTGUN)
		{
			self.weapon = IT_NAILGUN;
			if (self.ammo_nails < 1)
				am = 1;
		}
		else if (self.weapon == IT_NAILGUN)
		{
			self.weapon = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 1)
				am = 1;
		}
		else if (self.weapon == IT_SUPER_NAILGUN)
		{
			self.weapon = IT_GRENADE_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_GRENADE_LAUNCHER)
		{
			self.weapon = IT_ROCKET_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_ROCKET_LAUNCHER)
		{
			self.weapon = IT_LIGHTNING;
			if (self.ammo_cells < 1)
				am = 1;
		}

		if ( (self.items & self.weapon) && am == 0)
		{
			W_SetCurrentAmmo ();
			return;
		}
	}
};

/*
============
CycleWeaponReverseCommand

Go to the prev weapon with ammo
============
*/
void() CycleWeaponReverseCommand =
{
	local float it, am;

	it = self.items;
	self.impulse = 0;

	while (1)
	{
		am = 0;
		
		if (self.weapon == IT_LIGHTNING)
		{
			self.weapon = IT_ROCKET_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_ROCKET_LAUNCHER)
		{
			self.weapon = IT_GRENADE_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_GRENADE_LAUNCHER)
		{
			self.weapon = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 1)
				am = 1;
		}
		else if (self.weapon == IT_SUPER_NAILGUN)
		{
			self.weapon = IT_NAILGUN;
			if (self.ammo_nails < 1)
				am = 1;
		}
		else if (self.weapon == IT_NAILGUN)
		{
			self.weapon = IT_SUPER_SHOTGUN;
			if (self.ammo_shells < 1)
				am = 1;
		}
		else if (self.weapon == IT_SUPER_SHOTGUN)
		{
			self.weapon = IT_SHOTGUN;
			if (self.ammo_shells < 1)
				am = 1;
		}
		else if (self.weapon == IT_SHOTGUN)
		{
			self.weapon = IT_AXE;
		}
		else if (self.weapon == IT_AXE)
		{
			self.weapon = IT_LIGHTNING;
			if (self.ammo_cells < 1)
				am = 1;
		}

		if ( (it & self.weapon) && am == 0)
		{
			W_SetCurrentAmmo ();
			return;
		}
	}
};

/*
============
ServerflagsCommand

Just for development
============
*/
void() ServerflagsCommand =
{
	serverflags = serverflags * 2 + 1;
};

void() QuadCheat =
{
	if (deathmatch)
		return;
	self.super_time = 1;
	self.super_damage_finished = time + 30;
	self.items = self.items | IT_QUAD;
	dprint ("quad cheat\n");
};

void() InvisCheat =
{
	if (deathmatch)
		return;
	self.invisible_time = 1;
	self.invisible_finished = time + 30;
	self.items = self.items | IT_INVISIBILITY;
	dprint ("invis cheat\n");
};

/*
============
ImpulseCommands

============
*/
void() ImpulseCommands =
{
	if (self.impulse >= 1 && self.impulse <= 8)
		W_ChangeWeapon ();

	if (self.impulse == 9)
		CheatCommand ();
	if (self.impulse == 10)
		CycleWeaponCommand ();
	if (self.impulse == 11)
		ServerflagsCommand ();
	if (self.impulse == 12)
		CycleWeaponReverseCommand ();
	if (self.impulse == 254)
		InvisCheat();
	if (self.impulse == 255)
		QuadCheat ();

	self.impulse = 0;
};

/*
============
W_WeaponFrame

Called every frame so impulse events can be handled as well as possible
============
*/
void() W_WeaponFrame =
{
	if (self.attack_finished > time && self.attack_finished - time >= EPSILON)
		return;

	ImpulseCommands ();

	// check for attack
	if (self.button0)
	{
		SuperDamageSound ();
		W_Attack ();
	}
};

/*
========
SuperDamageSound

Plays sound if needed
========
*/
void() SuperDamageSound =
{
	if (self.super_damage_finished <= time)
		return;
	
	if (!(self.weapon & (IT_AXE | IT_NAILGUN | IT_SUPER_NAILGUN | IT_LIGHTNING)))
		self.super_sound = 0;
	
	if (self.super_sound <= time)
	{
		if (self.weapon == IT_AXE)
			self.super_sound = time + 1;
		else if (self.weapon & (IT_NAILGUN | IT_SUPER_NAILGUN | IT_LIGHTNING))
			self.super_sound = time + 0.9;
		
		sound (self, CHAN_BODY, "items/damage3.wav", 1, ATTN_NORM);
	}
};


