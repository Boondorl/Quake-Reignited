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
void() movetarget_f;
void() t_movetarget;
void() knight_walk1;
void() knight_bow6;
void() knight_bow1;
void(entity etemp, entity stemp, entity stemp, float dmg, float pain, float ignore_armor) T_Damage;
/*

.enemy
Will be world if not currently angry at anyone.

.movetarget
The next path spot to walk toward.  If .enemy, ignore .movetarget.
When an enemy is killed, the monster will try to return to it's path.

.hunt_time
Set to time + something when the player is in sight, but movement straight for
him is blocked.  This causes the monster to use wall following code for
movement direction instead of sighting on the player.

.ideal_yaw
A yaw angle of the intended direction, which will be turned towards at up
to 45 deg / state.  If the enemy is in view and hunt_time is not active,
this will be the exact line towards the enemy.

.pausetime
A monster will leave it's stand state and head towards it's .movetarget when
time > .pausetime.

walkmove(angle, speed) primitive is all or nothing
*/


//
// globals
//


//
// when a monster becomes angry at a player, that monster will be used
// as the sight target the next frame so that monsters near that one
// will wake up even if they wouldn't have noticed the player
//
entity	sight_entity;
float	sight_entity_time;

float(float v) anglemod =
{
	while (v >= 360)
		v -= 360;
	while (v < 0)
		v += 360;
	return v;
};

/*
==============================================================================

MOVETARGET CODE

The angle of the movetarget effects standing and bowing direction, but has no effect on movement, which always heads to the next target.

targetname
must be present.  The name of this movetarget.

target
the next spot to move to.  If not present, stop here for good.

pausetime
The number of seconds to spend standing or bowing for path_stand or path_bow

==============================================================================
*/


void() movetarget_f =
{
	if (!self.targetname)
		objerror ("monster_movetarget: no targetname");

	self.solid = SOLID_TRIGGER;
	self.touch = t_movetarget;
	setsize (self, '-8 -8 -8', '8 8 8');

};

/*QUAKED path_corner (0.5 0.3 0) (-8 -8 -8) (8 8 8)
Monsters will continue walking towards the next target corner.
*/
void() path_corner =
{
	movetarget_f ();
};


/*
=============
t_movetarget

Something has bumped into a movetarget.  If it is a monster
moving towards it, change the next destination and continue.
==============
*/
void() t_movetarget =
{
	if (other.movetarget != self || other.enemy)
		return;

	local entity temp = self;
	self = other;
	other = temp;

	if (self.classname == "monster_ogre")
		sound (self, CHAN_VOICE, "ogre/ogdrag.wav", 1, ATTN_IDLE);// play chainsaw drag sound

	self.goalentity = self.movetarget = find (world, targetname, other.target);
	self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
	if (!self.movetarget)
	{
		self.pausetime = time + 999999;
		self.th_stand ();
		return;
	}
};



//============================================================================

float(entity targ) HasInvisible =
{
	if (targ.invisible_finished <= time)
		return FALSE;
	if (range(targ) <= RANGE_MELEE)
		return FALSE;
	
	return TRUE;
}

/*
=============
range

returns the range catagorization of an entity reletive to self
0	melee range, will become hostile even if back is turned
1	visibility and infront, or visibility and show hostile
2	infront and show hostile
3	only triggered by damage
=============
*/
float(entity targ) range =
{
	local float r = vlen (targ.origin - self.origin);
	if (r < 120)
		return RANGE_MELEE;
	if (r < 500)
		return RANGE_NEAR;
	if (r < 1000)
		return RANGE_MID;
	return RANGE_FAR;
};

/*
=============
visible

returns 1 if the entity is visible to self, even if not infront ()
=============
*/
float (entity targ, float ignore_water) visible =
{
	traceline (self.origin+self.view_ofs, targ.origin+targ.view_ofs, TRUE, self);	// see through other monsters

	if (!ignore_water && trace_inopen && trace_inwater)
		return FALSE;			// sight line crossed contents

	return trace_fraction == 1;
};


/*
=============
infront

returns 1 if the entity is in front (in sight) of self
=============
*/
float(entity targ) infront =
{
	makevectors (self.angles);

	return normalize(targ.origin-self.origin) * v_forward > 0.3;
};


//============================================================================

void(float wake_up) HuntTarget =
{
	self.goalentity = self.enemy;
	self.ideal_yaw = vectoyaw(self.enemy.origin - self.origin);
	if (wake_up)
	{
		SUB_AttackFinished (0.5, 0.2, TRUE);	// wait a while before first attack
		self.th_run();
	}
};

void() SightSound =
{
	if (self.classname == "monster_ogre")
		sound (self, CHAN_VOICE, "ogre/ogwake.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_knight")
		sound (self, CHAN_VOICE, "knight/ksight.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_shambler")
		sound (self, CHAN_VOICE, "shambler/ssight.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_demon1")
		sound (self, CHAN_VOICE, "demon/sight2.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_wizard")
		sound (self, CHAN_VOICE, "wizard/wsight.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_zombie")
		sound (self, CHAN_VOICE, "zombie/z_idle.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_dog")
		sound (self, CHAN_VOICE, "dog/dsight.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_hell_knight")
		sound (self, CHAN_VOICE, "hknight/sight1.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_tarbaby")
		sound (self, CHAN_VOICE, "blob/sight1.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_enforcer")
	{
		local float rsnd = rint(random() * 3);
		if (rsnd == 1)
			sound (self, CHAN_VOICE, "enforcer/sight1.wav", 1, ATTN_NORM);
		else if (rsnd == 2)
			sound (self, CHAN_VOICE, "enforcer/sight2.wav", 1, ATTN_NORM);
		else if (rsnd == 0)
			sound (self, CHAN_VOICE, "enforcer/sight3.wav", 1, ATTN_NORM);
		else
			sound (self, CHAN_VOICE, "enforcer/sight4.wav", 1, ATTN_NORM);
	}
	else if (self.classname == "monster_army")
		sound (self, CHAN_VOICE, "soldier/sight1.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_shalrath")
		sound (self, CHAN_VOICE, "shalrath/sight.wav", 1, ATTN_NORM);
};

float() IsCoop;

void(float wake_up) FoundTarget =
{
	self.queued_enemy = world;
	
	if (self.enemy.classname == "player")
	{	// let other monsters see this monster for a while
		sight_entity = self;
		sight_entity_time = time;
	}

	self.show_hostile = time + 1;		// wake up other monsters
	self.sight_finished = time + 2; // make sure idle sounds don't interrupt waking up
	self.switch_time = time + 3;
	self.last_seen_time = time + 3;
	self.search_time = time + 5;

	SightSound ();
	HuntTarget (wake_up);
};

void(string snd, float chance) IdleSound =
{
	if (self.sight_finished > time)
		return;
	
	if (random() < chance)
		sound(self, CHAN_VOICE, snd, 1, ATTN_IDLE);
};

/*
===========
FindTarget

Self is currently not attacking anything, so try to find a target

Returns TRUE if an enemy was sighted

When a player fires a missile, the point of impact becomes a fakeplayer so
that monsters that see the impact will respond as if they had seen the
player.

To avoid spending too much time, only a single client (or fakeclient) is
checked each frame.  This means multi player games will have slightly
slower noticing monsters.
============
*/
float() FindTarget =
{
	local entity	client;

	// if the first spawnflag bit is set, the monster will only wake up on
	// really seeing the player, not another monster getting angry

	// spawnflags & 3 is a big hack, because zombie crucified used the first
	// spawn flag prior to the ambush flag, and I forgot about it, so the second
	// spawn flag works as well
	if (sight_entity_time >= time - 0.1 && !(self.spawnflags & 3) )
	{
		client = sight_entity;
		if (client.enemy == self.enemy)
			return FALSE;
	}
	else
	{
		client = checkclient ();
		if (!client)
			return FALSE;	// current check entity isn't in PVS
	}

	if (client == self.enemy || (client.flags & FL_NOTARGET))
		return FALSE;
	
	local float r = range(client);
	if (r == RANGE_FAR)
		return FALSE;
	if (HasInvisible(client))
		return FALSE;
	if (!visible(client, FALSE))
		return FALSE;

	if (r == RANGE_NEAR)
	{
		if (client.show_hostile < time)
		{
			if (!infront (client))
				return FALSE;
		}
	}
	else if (r == RANGE_MID)
	{
		if (!infront (client))
			return FALSE;
	}

	//
	// got one
	//
	local float had_enemy = self.enemy != world;
	self.enemy = client;
	if (self.enemy.classname != "player")
	{
		self.enemy = self.enemy.enemy;
		if (self.enemy.classname != "player")
		{
			self.enemy = world;
			return FALSE;
		}
	}

	FoundTarget (!had_enemy);

	return TRUE;
};


//=============================================================================

void(float dist) ai_forward =
{
	walkmove (self.angles_y, dist);
};

void(float dist) ai_back =
{
	walkmove ( (self.angles_y+180), dist);
};


/*
=============
ai_pain

stagger back a bit
=============
*/
void(float dist) ai_pain =
{
	ai_back (dist);
};

/*
=============
ai_painforward

stagger back a bit
=============
*/
void(float dist) ai_painforward =
{
	walkmove (self.angles_y, dist);
};

/*
=============
ai_walk

The monster is walking it's beat
=============
*/
void(float dist) ai_walk =
{
	movedist = dist;

	// check for noticing a player
	if (FindTarget ())
		return;

	movetogoal (dist);
};


/*
=============
ai_stand

The monster is staying in one place for a while, with slight angle turns
=============
*/
void() ai_stand =
{
	if (FindTarget ())
		return;

	if (time > self.pausetime)
		self.th_walk ();
};

/*
=============
ai_turn

don't move, but turn towards ideal_yaw
=============
*/
void() ai_turn =
{
	if (FindTarget ())
		return;

	ChangeYaw ();
};

//=============================================================================

/*
=============
ChooseTurn
=============
*/
void(vector dest3) ChooseTurn =
{
	local vector dir = self.origin - dest3;

	local vector newdir;
	newdir_x = trace_plane_normal_y;
	newdir_y = 0 - trace_plane_normal_x;
	newdir_z = 0;

	if (dir * newdir > 0)
	{
		dir_x = 0 - trace_plane_normal_y;
		dir_y = trace_plane_normal_x;
	}
	else
	{
		dir_x = trace_plane_normal_y;
		dir_y = 0 - trace_plane_normal_x;
	}

	dir_z = 0;
	self.ideal_yaw = vectoyaw(dir);
};

float(entity targ, float ang) CheckAboveBelow;

/*
============
FacingIdeal

============
*/
float() FacingIdeal =
{
	local float delta = anglemod(self.angles_y - self.ideal_yaw);
	if (delta <= 45 || delta >= 315)
		return TRUE;
	
	if (self.enemy)
		return CheckAboveBelow(self.enemy, 0.866);
	
	return FALSE;
};


//=============================================================================

float()	WizardCheckAttack;
float()	DogCheckAttack;

float() CheckAnyAttack =
{
	if (!enemy_vis)
		return FALSE;
	
	if (self.th_checkatk)
		return self.th_checkatk();
	
	return CheckAttack ();
};

float(entity targ) CanSwitchTo =
{
	if (targ.health <= 0 || targ == world || targ == self || targ.is_zombie || !targ.takedamage)
		return FALSE;
	
	if (!self.infight_class && targ.classname == self.classname)
		return FALSE;
	
	if (self.is_zombie && other.classname != "player")
		return FALSE;
	
	if (self.enemy)
	{
		if (targ == self.enemy)
			return FALSE;
		
		if (self.switch_time > time)
		{
			if (self.enemy.classname == "player")
				return FALSE;
			if (targ.classname != "player")
				return FALSE;
		}
	}
	
	return TRUE;
};


/*
=============
ai_run_melee

Turn and close until within an angle to launch a melee attack
=============
*/
void() ai_run_melee =
{
	ai_face();

	if (FacingIdeal())
	{
		self.th_melee ();
		self.attack_state = AS_STRAIGHT;
	}
};


/*
=============
ai_run_missile

Turn in place until within an angle to launch a missile attack
=============
*/
void() ai_run_missile =
{
	ai_face();
	if (FacingIdeal())
	{
		self.th_missile ();
		self.attack_state = AS_STRAIGHT;
		return;
	}
	
	if (self.attack_finished > time)
		self.attack_finished += 0.1;
};


/*
=============
ai_run_slide

Strafe sideways, but stay at aproximately the same range
=============
*/
void() ai_run_slide =
{
	local float	ofs;

	ai_face();
	if (self.lefty)
		ofs = 90;
	else
		ofs = -90;

	if (walkmove (self.ideal_yaw + ofs, movedist))
		return;

	self.lefty = !self.lefty;

	walkmove (self.ideal_yaw - ofs, movedist);
};


/*
=============
ai_run

The monster has an enemy it is trying to kill
=============
*/
float crandom();

void(float dist) ai_run =
{
	movedist = dist;
	
	self.in_pain = FALSE;
	if (self.queued_enemy)
	{
		if (self.queued_enemy != self.enemy && self.queued_enemy.health > 0)
		{
			if (self.enemy.classname == "player")
				self.last_enemy = self.enemy;
				
			self.enemy = self.queued_enemy;
			FoundTarget(FALSE);
		}
		
		self.queued_enemy = world;
	}
	
	// see if the enemy is dead
	if (self.enemy.health <= 0)
	{
		if (!FindTarget())
		{
			self.enemy = world;
			
			if (self.last_enemy)
			{
				if (self.last_enemy.health > 0)
				{
					self.enemy = self.last_enemy;
					FoundTarget(FALSE);
				}
				
				self.last_enemy = world;
			}
			
			if (!self.enemy)
			{
				self.in_attack = FALSE;
				self.attack_state = AS_STRAIGHT;
				
				if (self.movetarget)
					self.th_walk ();
				else
					self.th_stand ();
				
				return;
			}
		}
	}
	
	// look for other coop players
	if (!self.in_attack && self.search_time <= time && (IsCoop() || (self.enemy.flags & FL_MONSTER)))
	{
		if (!FindTarget ())
			self.search_time = time + 0.5;
	}

	// wake up other monsters
	self.show_hostile = time + 1;

	// check knowledge of enemy
	enemy_vis = visible(self.enemy, self.waterlevel > 0 && self.enemy.waterlevel > 0);
	if (enemy_vis || self.in_attack)
		self.last_seen_time = time + 3;

	enemy_infront = infront(self.enemy);
	enemy_range = range(self.enemy);
	enemy_yaw = vectoyaw(self.enemy.origin - self.origin);

	if (self.attack_state == AS_MISSILE)
	{
		ai_run_missile ();
		return;
	}
	if (self.attack_state == AS_MELEE)
	{
		ai_run_melee ();
		return;
	}

	self.in_attack = FALSE;
	if (self.last_seen_time <= time)
		SUB_AttackFinished(0.3, 0.15, TRUE);
	
	if (CheckAnyAttack ())
	{
		self.in_attack = TRUE;
		self.ideal_yaw = enemy_yaw;
		
		if (self.attack_state == AS_MISSILE)
		{
			if (HasInvisible(self.enemy))
				self.ideal_yaw += 30*crandom();
			
			ai_run_missile();
		}
		else if (self.attack_state == AS_MELEE)
			ai_run_melee();
		
		return;					// beginning an attack
	}

	if (self.attack_state == AS_SLIDING)
	{
		ai_run_slide ();
		return;
	}

	// head straight in
	movetogoal (dist);		// done in C code...
};
