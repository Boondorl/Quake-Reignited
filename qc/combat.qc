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

void() T_MissileTouch;
void() info_player_start;
void(entity targ, entity attacker) ClientObituary;

void() monster_death_use;

//============================================================================


/*
============
CheckCorners

Check sight to the edges of targ's bounding box at the given z position
============
*/
float(vector orig, entity targ, float z, entity ignore) CheckCorners =
{
	local vector offset;
	offset_z = z;
	
	offset_x = targ.maxs_x;
	offset_y = targ.maxs_y;
	traceline(orig, targ.origin + offset, TRUE, ignore);
	if (trace_fraction == 1)
		return TRUE;
	
	offset_x = targ.mins_x;
	offset_y = targ.mins_y;
	traceline(orig, targ.origin + offset, TRUE, ignore);
	if (trace_fraction == 1)
		return TRUE;
	
	offset_x = targ.mins_x;
	offset_y = targ.maxs_y;
	traceline(orig, targ.origin + offset, TRUE, ignore);
	if (trace_fraction == 1)
		return TRUE;
	
	offset_x = targ.maxs_x;
	offset_y = targ.mins_y;
	traceline(orig, targ.origin + offset, TRUE, ignore);
	if (trace_fraction == 1)
		return TRUE;
		
	return FALSE;
};

/*
============
CanDamage

Returns true if the inflictor can directly damage the target.  Used for
explosions and melee attacks.
============
*/
float(entity targ, entity inflictor) CanDamage =
{
	// bmodels need special checking because their origin is 0,0,0
	if (targ.movetype == MOVETYPE_PUSH)
	{
		traceline(inflictor.origin, 0.5 * (targ.absmin + targ.absmax), TRUE, self);
		return trace_fraction == 1;
	}
	
	traceline(inflictor.origin, targ.origin, TRUE, self);
	if (trace_fraction == 1)
		return TRUE;
	if (CheckCorners(inflictor.origin, targ, 0, self))
		return TRUE;
	if (CheckCorners(inflictor.origin, targ, targ.maxs_z, self))
		return TRUE;
	if (CheckCorners(inflictor.origin, targ, targ.mins_z, self))
		return TRUE;
	
	return FALSE;
};


/*
============
Killed
============
*/

void() SetLevelFailed;
float() IsCoop;

void(entity targ, entity attacker) Killed =
{
	local entity oself = self;
	self = targ;
	
	self.death_position = self.origin;

	if (self.health < -99)
		// don't let sbar look bad if a player
		self.health = -99;
		
	if (self.block_ent)
		remove(self.block_ent);

	if (self.movetype == MOVETYPE_PUSH || self.movetype == MOVETYPE_NONE)
	{	// doors, triggers, etc
		self.th_die ();
		self = oself;
		return;
	}

	self.enemy = attacker;

	// bump the monster counter
	if (self.flags & FL_MONSTER)
	{
		++killed_monsters;
		WriteByte (MSG_ALL, SVC_KILLEDMONSTER);
	}

	ClientObituary(self, attacker);

	self.touch = SUB_Null;

	monster_death_use();
	self.th_die ();
	
	if (IsCoop() && (coop & DISABLE_RESPAWN) && !failed)
	{
		if (self.classname == "player")
			SetLevelFailed();
	}

	self = oself;
};

/*
============
SetUnblocking

Basic death property setting.
============
*/
void() SetUnblocking =
{
	self.solid = SOLID_NOT;
	self.takedamage = DAMAGE_NO;
};


/*
============
AccumulatePain
============
*/
void(entity targ, float pain, entity attacker, float damage) AccumulatePain =
{
	if (targ.pain_finished > time || self.in_pain || targ.pain_threshold <= 0 || pain <= 0 || (targ.touch && targ.touch != SUB_Null))
		return;
	if (targ.classname == "player")
		return;
	
	targ.pain_amount += pain;
	if (targ.pain_amount >= targ.pain_threshold)
	{
		self.in_pain = TRUE;
		targ.pain_amount = 0;
		targ.in_attack = FALSE;
		targ.attack_state = AS_STRAIGHT; // cancel whatever attack they're in
		targ.th_pain(attacker, damage);
		
		local entity o = self;
		self = targ;
		SUB_AttackFinished(0.8, 0.8, TRUE);
		self = o;
	}
}

/*
============
ApplyArmor
============
*/
float(entity targ, float damage) ApplyArmor =
{
	if (targ.armorvalue <= 0 || targ.armortype <= 0 || damage <= 0)
		return damage;
	
	local float save, remaining;
	if (targ.items & IT_ARMOR3)
	{
		save = floor(damage*targ.armortype);
		if (targ.armorvalue - save < MEDIUM_ARMOR)
		{
			remaining = (save - (targ.armorvalue-MEDIUM_ARMOR));
			save = targ.armorvalue - MEDIUM_ARMOR;
		}
		
		targ.armorvalue -= save;
		damage -= save;
		
		if (targ.armorvalue == MEDIUM_ARMOR)
		{
			targ.items -= IT_ARMOR3;
			targ.items |= IT_ARMOR2;
			targ.armortype = MEDIUM_ARMOR_TYPE;
		}
		
		if (remaining <= 0)
			return damage;
	}
	
	if (targ.items & IT_ARMOR2)
	{
		save = floor(damage*targ.armortype);
		if (remaining > 0 && remaining < save)
			save = remaining;
		
		remaining = 0;
		if (targ.armorvalue - save < LIGHT_ARMOR)
		{
			remaining = (save - (targ.armorvalue-LIGHT_ARMOR));
			save = targ.armorvalue - LIGHT_ARMOR;
		}
		
		targ.armorvalue -= save;
		damage -= save;
		
		if (targ.armorvalue == LIGHT_ARMOR)
		{
			targ.items -= IT_ARMOR2;
			targ.items |= IT_ARMOR1;
			targ.armortype = LIGHT_ARMOR_TYPE;
		}
		
		if (remaining <= 0)
			return damage;
	}
	
	if (targ.items & IT_ARMOR1)
	{
		save = floor(damage*targ.armortype);
		if (remaining > 0 && remaining < save)
			save = remaining;
		
		if (save > targ.armorvalue)
			save = targ.armorvalue;
		
		targ.armorvalue -= save;
		damage -= save;
		
		if (targ.armorvalue <= 0)
		{
			targ.items -= IT_ARMOR1;
			targ.armortype = 0;
		}
	}
	
	return damage;
};

/*
============
T_Damage

The damage is coming from inflictor, but get mad at attacker
This should be the only function that ever reduces health.
============
*/
void(entity targ, entity inflictor, entity attacker, float damage, float pain, float ignore_armor) T_Damage =
{
	if (!targ.takedamage)
		return;
	if (IsCoop() && (coop & DISABLE_FRIENDLY_FIRE) && targ != attacker)
	{
		if (targ.classname == "player" && attacker.classname == "player")
			return;
	}

	// used by buttons and triggers to set activator for target firing
	damage_attacker = attacker;
	// keep track of the source of damage, used in gibs
	damage_inflictor = inflictor;

	// check for damage amp powerup on the attacker
	if (attacker.super_damage_finished > time)
	{
		damage *= DAMAGE_AMP;
		pain *= DAMAGE_AMP;
	}

	// save damage based on the target's armor level
	local float take = ceil(damage);
	if (!ignore_armor && !(targ.flags & FL_GODMODE) && targ.invincible_finished <= time)
		take = ApplyArmor(targ, take);

	// add to the damage total for clients, which will be sent as a single
	// message at the end of the frame
	// FIXME: remove after combining shotgun blasts?
	if (targ.flags & FL_CLIENT)
	{
		targ.dmg_take += take;
		targ.dmg_save += (ceil(damage) - take);
		targ.dmg_inflictor = inflictor;
	}

	// figure momentum add
	if (inflictor != world && targ.movetype == MOVETYPE_WALK)
		targ.velocity += normalize(targ.origin - (inflictor.absmin+inflictor.absmax)*0.5)*damage*8;

	// check for godmode or invincibility
	if (targ.flags & FL_GODMODE)
		return;
	if (targ.invincible_finished > time)
	{
		if (self.invincible_sound <= time)
		{
			sound (targ, CHAN_ITEM, "items/protect3.wav", 1, ATTN_NORM);
			self.invincible_sound = time + 2;
		}
		
		return;
	}

	// team play damage avoidance
	if (teamplay && targ.team > 0 && targ.team == attacker.team)
		return;

	// do the damage
	local float h = targ.health;
	if (h > 0 && targ.is_zombie)
	{
		if (targ.damage_accumulation_time < time || targ.damage_accumulator != attacker)
		{
			targ.damage_accumulator = attacker;
			targ.damage_accumulation_time = time;
			targ.damage_accumulation = 0;
		}
		
		targ.damage_accumulation += take;
		if (targ.damage_accumulation >= targ.health)
			targ.health -= targ.damage_accumulation;
	}
	else
		targ.health -= take;

	local entity oldself;
	if (h > 0 && targ.health <= 0)
		Killed (targ, attacker);
	if (targ.health <= 0 && targ.th_gib && targ.health <= targ.gib_health)
	{
		oldself = self;
		self = targ;
		SetUnblocking();
		self.th_gib();
		self = oldself;
	}
	
	if (targ.health <= 0)
		return;

	// react to the damage
	oldself = self;
	self = targ;

	if (self.flags & FL_MONSTER)
	{
		if (attacker == self.enemy)
		{
			if (self.queued_enemy.classname != "player")
				self.queued_enemy = world;
			
			self.search_time = time + 3;
		}
		else if (CanSwitchTo(attacker))
		{
			if (self.in_attack || self.in_pain)
			{
				if (attacker.classname == "player" || self.queued_enemy.classname != "player")
					self.queued_enemy = attacker;
			}
			else
			{
				local float had_enemy = self.enemy != world;
				
				if (self.enemy.classname == "player")
					self.last_enemy = self.enemy;
				
				self.enemy = attacker;
				FoundTarget(!had_enemy);
			}
		}
	}

	if (self.th_pain)
	{
		if (self.flags & FL_MONSTER)
			AccumulatePain(targ, pain, attacker, take);
		else
			self.th_pain(attacker, damage);
	}

	self = oldself;
};

/*
============
T_RadiusDamage
============
*/
void(entity inflictor, entity attacker, float max_damage, float min_damage, float dist, float pain, entity impact) T_RadiusDamage =
{
	local	float 	points;
	local	vector	org;
	local entity head = findradius(inflictor.origin, dist);
	while (head)
	{
		if (head.takedamage)
		{
			if (head == impact)
				points = max_damage;
			else
			{
				org = head.origin + (head.mins + head.maxs)*0.5;
				points = min_damage + (max_damage-min_damage)*(1 - vlen(org-inflictor.origin)/dist);
			}
			
			if (points >= min_damage)
			{
				if (CanDamage(head, inflictor))
				{
					// bosses takes half damage from all explosions
					if (head.is_boss)
						points *= 0.5;
						
					T_Damage (head, inflictor, attacker, points, pain, FALSE);
				}
			}
		}
		
		head = head.chain;
	}
};

/*
============
T_BeamDamage
============
*/
void(entity attacker, float damage) T_BeamDamage =
{
	local float points;
	local entity head;

	head = findradius(attacker.origin, damage+40);

	while (head)
	{
		if (head.takedamage)
		{
			points = 0.5*vlen (attacker.origin - head.origin);
			if (points < 0)
				points = 0;
			points = damage - points;
			if (head == attacker)
				points = points * 0.5;
			if (points > 0)
			{
				if (CanDamage (head, attacker))
				{
					if (head.classname == "monster_shambler")
						T_Damage (head, attacker, attacker, points*0.5, 0, FALSE);
					else
						T_Damage (head, attacker, attacker, points, 0, FALSE);
				}
			}
		}
		head = head.chain;
	}
};

/*
============
CalculateProjectileZ

For projectiles that use gravity, calculate the speed they need to
arc it towards their destination. If blocked, do the standard arc
formula. Also randomizes accuracy based on distance.
============
*/
float(vector orig, vector end, vector vel) CalculateProjectileZ
{
	local vector xy = orig - end;
	xy_z = 0;
	local float dist = vlen(xy);
	if (dist > INACCURACY_RANGE)
	{
		local float multi = (dist-INACCURACY_RANGE) / INACCURACY_RANGE;
		if (multi > 1)
			multi = 1;
		
		end += normalize(xy) * INACCURACY_DIST*multi*random();
	}
	
	local float traveltime = vlen(end - orig) / vlen(vel);
	local float grav = -1 * cvar("sv_gravity");
	local float zspeed = (end_z-orig_z - 0.5*grav*traveltime*traveltime) / traveltime;
	
	if (traveltime > 0.2)
	{
		local vector newvel = vel;
		newvel_z = zspeed;
		
		local float precision = ceil(60 * traveltime); // give longer ranges more precise checking
		if (precision > 60)
			precision = 60;
		
		++precision;
		for (float interval = 1; interval < precision; ++interval)
		{
			local float newtime = traveltime * (interval/precision);
			local vector dest = orig + newvel*newtime;
			dest_z = orig_z + newvel_z*newtime + 0.5*grav*newtime*newtime;
			
			if (pointcontents(dest) == CONTENT_SOLID)
				return vel_z + 300;
		}
	}
	
	return zspeed;
};

float(entity targ, float ang) CheckAboveBelow =
{
	return fabs(normalize(targ.origin-self.origin) * '0 0 1') >= ang;
};

/*
============
InAttackDirection

Make sure monsters never attack behind themselves
when in combat
============
*/
float(entity targ, float range) InAttackDirection =
{
	local float delta = anglemod(self.angles_y - vectoyaw(targ.origin-self.origin));
	if (delta <= range || delta >= 360-range)
		return TRUE;
	
	return CheckAboveBelow(targ, 0.866);
};

float() crandom;

float() CheckLoS = 
{
	traceline(self.origin, self.enemy.origin, FALSE, self);
	return trace_ent == self.enemy || trace_ent.classname == "player";
};

/*
============
FireProjectileAtEnemy

Accounts for gravity, tracking, and invisibility/out of sight
============
*/
entity(vector orig, vector ofs, float speed, float lifetime, string model, float track, float grav) FireProjectileAtEnemy =
{
	local entity missile = spawn();
	missile.owner = self;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_BBOX;
	
	if (lifetime > 0)
	{
		missile.nextthink = time + lifetime;
		missile.think = SUB_Remove;
	}
	
	local vector end;
	local float in_view = InAttackDirection(self.enemy, 60);
	local float invis = HasInvisible(self.enemy);
	local float hassight = in_view & !invis;
	if (hassight)
		hassight &= visible(self.enemy, FALSE);
	
	if (hassight)
	{
		end = self.enemy.origin + ofs;
		if (track)
		{
			local float dist = vlen(end - orig);
			if (dist < TRACK_RANGE)
			{
				local vector add = self.enemy.velocity * (dist / speed);
				add_z *= 0.2; // Prevent jumping from being overpowered
				end += add * (1 - dist/TRACK_RANGE);
			}
		}
		
		missile.velocity = normalize(end - orig) * speed;
		if (grav)
			missile.velocity_z = CalculateProjectileZ(orig, end, missile.velocity);
	}
	else
	{
		makevectors(self.angles);
		
		local vector dir;
		if (in_view)
		{
			end = self.enemy.origin + ofs;
			if (invis)
				end_z += 32*crandom();
			
			dir = end - orig;
			local float z = dir_z;
			
			dir_z = 0;
			dir = v_forward * vlen(dir);
			dir_z = z;
			
			dir = normalize(dir);
		}
		else
			dir = v_forward;
		
		missile.velocity = dir * speed;
		if (grav)
			missile.velocity_z += 300;
	}
	
	missile.angles = vectoangles(missile.velocity);
	
	setmodel(missile, model);
	setsize(missile, VEC_ORIGIN, VEC_ORIGIN);
	setorigin(missile, orig);
	
	return missile;
};

/*
============
FireProjectile
============
*/
entity(vector orig, vector dir, float speed, float lifetime, string model) FireProjectile =
{
	local entity missile = spawn();
	missile.owner = self;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_BBOX;
	
	if (lifetime > 0)
	{
		missile.nextthink = time + lifetime;
		missile.think = SUB_Remove;
	}
	
	missile.velocity = dir * speed;
	missile.angles = vectoangles(missile.velocity);
	
	setmodel(missile, model);
	setsize(missile, VEC_ORIGIN, VEC_ORIGIN);
	setorigin(missile, orig);
	
	return missile;
};

float(float a, float b) Min =
{
	if (a < b)
		return a;
	
	return b;
};

float(float a, float b) Max =
{
	if (a > b)
		return a;
	
	return b;
};

vector(vector org, entity e) GetNearestPoint =
{
	local vector e_min = e.origin + e.mins;
	local vector e_max = e.origin + e.maxs;
	
	local vector point;
	point_x = Max(e_min_x, Min(org_x, e_max_x));
	point_y = Max(e_min_y, Min(org_y, e_max_y));
	point_z = Max(e_min_z, Min(org_z, e_max_z));
	
	return point;
};

float(entity targ, vector orig, vector dir, float dist, float x_ofs, float y_ofs) CheckCollision =
{
	local vector o = orig;
	o_x += x_ofs;
	o_y += y_ofs;
	
	traceline(o, o + dir*dist, FALSE, self);
	return trace_ent == targ || trace_fraction == 1 || trace_ent.classname == "player";
};

/*
============
CheckBodyBlocking

Special collision checking to make sure a pathway
along the size of self's hitbox is clear
============
*/
float(entity targ, float range) CheckBodyBlocking =
{
	if (range > 0)
	{
		if (vlen(targ.origin-self.origin) > range)
			return FALSE;
	}
	
	traceline(self.origin, targ.origin, FALSE, self);
	if (trace_ent != targ && trace_ent.classname != "player")
		return FALSE;
	
	local vector targ_nearest = GetNearestPoint(self.origin, targ);
	local vector self_nearest = GetNearestPoint(targ_nearest, self);
	
	local float dist = vlen(targ_nearest - self_nearest);
	local vector dir = normalize(targ_nearest - self.origin);
	local vector offset = self_nearest - self.origin;
	
	if (!CheckCollision(targ, self.origin, dir, dist, -offset_y, offset_x))
		return FALSE;
	
	return CheckCollision(targ, self.origin, dir, dist, offset_y, -offset_x);
};

float(vector orig, vector dir, float dist, entity ignore) CheckCeiling =
{
	if (!self.block_ent)
	{
		self.block_ent = spawn();
		setsize(self.block_ent, self.mins, self.maxs);
	}
	
	local float old_solid = self.solid;
	local float old_ignore_solid = ignore.solid;
	self.solid = ignore.solid = SOLID_NOT;
	
	self.block_ent.solid = SOLID_SLIDEBOX;
	self.block_ent.movetype = MOVETYPE_STEP;
	self.block_ent.flags = FL_ONGROUND|FL_PARTIALGROUND;
	
	setorigin(self.block_ent, orig);
	
	local entity old = self;
	self = self.block_ent;
	
	local float empty = walkmove(0,0);
	if (empty)
	{
		self.flags = FL_ONGROUND|FL_PARTIALGROUND;
		setorigin(self, orig + dir*dist);
		empty = walkmove(0,0);
	}
	
	self = old;
	self.solid = old_solid;
	ignore.solid = old_ignore_solid;
	
	self.block_ent.solid = SOLID_NOT;
	self.block_ent.movetype = MOVETYPE_NONE;
	self.block_ent.flags = 0;
	
	return empty;
};

float(entity targ) CheckFloor =
{
	if (!self.block_ent)
	{
		self.block_ent = spawn();
		setsize(self.block_ent, self.mins, self.maxs);
	}
	
	self.block_ent.solid = self.solid;
	self.block_ent.movetype = self.movetype;
	self.block_ent.flags = self.flags;
	self.block_ent.flags -= (self.block_ent.flags & FL_MONSTER);
	
	local float old_solid = self.solid;
	local float old_targ_solid = targ.solid;
	self.solid = targ.solid = SOLID_NOT;
	
	setorigin(self.block_ent, self.origin);
	
	local entity old = self;
	self = self.block_ent;
	
	local float passed = walkmove(vectoyaw(targ.origin-self.origin), 20);
	
	self = old;
	self.solid = old_solid;
	targ.solid = old_targ_solid;
	
	self.block_ent.solid = SOLID_NOT;
	self.block_ent.movetype = MOVETYPE_NONE;
	self.block_ent.flags = 0;
	
	if (!passed)
		return FALSE;
	
	local vector dir = targ.origin - self.origin;
	dir_z = targ.origin_z+targ.mins_z - (self.origin_z+self.mins_z);
	
	local vector cur = self.origin;
	setorigin(self, self.origin + dir*0.5);
	local float ground = checkbottom(self);
	setorigin(self, cur);
	
	return ground;
};

/*
============
CheckLeap
============
*/
float(entity targ, float leap_range) CheckLeap =
{
	if (!(self.flags & FL_ONGROUND))
		return FALSE;
	
	// too low/high
	if (self.origin_z+self.mins_z > targ.origin_z+targ.mins_z + 0.75*targ.size_z
		|| self.origin_z+self.maxs_z < targ.origin_z+targ.mins_z + 0.25*targ.size_z)
	{
		return FALSE;
	}
	
	if (!CheckBodyBlocking(targ, leap_range))
		return FALSE;
	
	return CheckCeiling(self.origin + '0 0 1'*self.maxs_z, normalize(targ.origin-self.origin), Min(self.size.x,self.size.y), targ);
};

void(void() t, float spd, float jmp) LeapAttack =
{
	self.touch = t;
	self.flags -= (self.flags & FL_ONGROUND);
	
	local float in_view = InAttackDirection(self.enemy, 60);
	local float hassight = in_view;
	if (hassight)
	{
		hassight &= !HasInvisible(self.enemy);
		if (hassight)
			hassight &= visible(self.enemy, FALSE);
	}
	
	local vector dir;
	if (hassight)
		dir = normalize(self.enemy.origin - self.origin);
	else
	{
		makevectors(self.angles);
		
		if (in_view)
		{
			dir = self.enemy.origin - self.origin;
			local float z = dir_z;
			
			dir_z = 0;
			dir = v_forward * vlen(dir);
			dir_z = z;
			
			dir = normalize(dir);
		}
		else
			dir = v_forward;
	}
	
	self.velocity = dir*spd;
	self.velocity_z += jmp;
};

/*
============
CheckChargeAttack

Make sure level geo and enemies aren't going to
block the charge path
============
*/
float(entity e, float melee_range, float charge_range) CheckChargeAttack =
{
	if (!(self.flags & FL_ONGROUND))
		return FALSE;
	if (fabs(e.origin_z-self.origin_z) > 20)
		return FALSE;
	if (melee_range > 0)
	{
		if (vlen(e.origin-self.origin) <= melee_range)
			return FALSE;
	}
	
	if (!CheckBodyBlocking(e, charge_range))
		return FALSE;
	
	return CheckFloor(self.enemy);
};

/*
============
CheckMeleeRange

Make sure nothing is blocking. Supports full
3D range checking
============
*/
float(entity targ, float range) CheckMeleeRange =
{
	if (vlen(targ.origin-self.origin) > range)
		return FALSE;
	
	traceline(self.origin, targ.origin, FALSE, self);
	return trace_ent == targ || trace_ent.classname == "player";
};

/*
============
MeleeAttack

Try and swing at its enemy
============
*/
void(float damage, float dist, float pain) MeleeAttack =
{
	local vector dir;
	local float in_view = InAttackDirection(self.enemy, 60);
	local float hassight = in_view;
	if (hassight) // gross
	{
		hassight &= !HasInvisible(self.enemy);
		if (hassight)
			hassight &= visible(self.enemy, FALSE);
	}
	
	if (hassight)
		dir = normalize(self.enemy.origin - self.origin);
	else
	{
		makevectors(self.angles);
		
		if (in_view)
		{
			dir = self.enemy.origin - self.origin;
			local float z = dir_z;
			
			dir_z = 0;
			dir = v_forward * vlen(dir);
			dir_z = z;
			
			dir = normalize(dir);
		}
		else
			dir = v_forward;
	}
	
	traceline(self.origin, self.origin + dir*dist, FALSE, self);
	T_Damage(trace_ent, self, self, damage, pain, FALSE);
};

void(entity e, vector org, vector end) SpawnLightning =
{
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_LIGHTNING2);
	WriteEntity (MSG_BROADCAST, e);
	WriteCoord (MSG_BROADCAST, org_x);
	WriteCoord (MSG_BROADCAST, org_y);
	WriteCoord (MSG_BROADCAST, org_z);
	WriteCoord (MSG_BROADCAST, end_x);
	WriteCoord (MSG_BROADCAST, end_y);
	WriteCoord (MSG_BROADCAST, end_z);
};
