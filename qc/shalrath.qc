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
/*
==============================================================================

SHAL-RATH (Vore)

==============================================================================
*/
$cd id1/models/shalrath
$origin 0 0 24
$base base
$skin skin
$scale 0.7

$frame attack1 attack2 attack3 attack4 attack5 attack6 attack7 attack8
$frame attack9 attack10 attack11

$frame pain1 pain2 pain3 pain4 pain5

$frame death1 death2 death3 death4 death5 death6 death7

$frame	walk1 walk2 walk3 walk4 walk5 walk6 walk7 walk8 walk9 walk10
$frame	walk11 walk12

void() ShalMissile;
void() shal_stand     =[      $walk1,       shal_stand    ] {ai_stand();};

void() shal_walk1     =[      $walk2,       shal_walk2    ]
{
	IdleSound("shalrath/idle.wav", 0.2);
	ai_walk(6);
};
void() shal_walk2     =[      $walk3,       shal_walk3    ] {ai_walk(4);};
void() shal_walk3     =[      $walk4,       shal_walk4    ] {ai_walk(0);};
void() shal_walk4     =[      $walk5,       shal_walk5    ] {ai_walk(0);};
void() shal_walk5     =[      $walk6,       shal_walk6    ] {ai_walk(0);};
void() shal_walk6     =[      $walk7,       shal_walk7    ] {ai_walk(0);};
void() shal_walk7     =[      $walk8,       shal_walk8    ] {ai_walk(5);};
void() shal_walk8     =[      $walk9,       shal_walk9    ] {ai_walk(6);};
void() shal_walk9     =[      $walk10,       shal_walk10    ] {ai_walk(5);};
void() shal_walk10    =[      $walk11,       shal_walk11    ] {ai_walk(0);};
void() shal_walk11    =[      $walk12,       shal_walk12    ] {ai_walk(4);};
void() shal_walk12    =[      $walk1,       shal_walk1    ] {ai_walk(5);};

void() shal_run1     =[      $walk2,       shal_run2    ]
{
	IdleSound("shalrath/idle.wav", 0.2);
	ai_run(6);
};
void() shal_run2     =[      $walk3,       shal_run3    ] {ai_run(4);};
void() shal_run3     =[      $walk4,       shal_run4    ] {ai_run(0);};
void() shal_run4     =[      $walk5,       shal_run5    ] {ai_run(0);};
void() shal_run5     =[      $walk6,       shal_run6    ] {ai_run(0);};
void() shal_run6     =[      $walk7,       shal_run7    ] {ai_run(0);};
void() shal_run7     =[      $walk8,       shal_run8    ] {ai_run(5);};
void() shal_run8     =[      $walk9,       shal_run9    ] {ai_run(6);};
void() shal_run9     =[      $walk10,       shal_run10    ] {ai_run(5);};
void() shal_run10    =[      $walk11,       shal_run11    ] {ai_run(0);};
void() shal_run11    =[      $walk12,       shal_run12    ] {ai_run(4);};
void() shal_run12    =[      $walk1,       shal_run1    ] {ai_run(5);};

void() shal_attack1     =[      $attack1,       shal_attack2    ]
{
	sound (self, CHAN_VOICE, "shalrath/attack.wav", 1, ATTN_NORM);
	ai_face();
};
void() shal_attack2     =[      $attack2,       shal_attack3    ] {ai_face();};
void() shal_attack3     =[      $attack3,       shal_attack4    ] {ai_face();};
void() shal_attack4     =[      $attack4,       shal_attack5    ] {ai_face();};
void() shal_attack5     =[      $attack5,       shal_attack6    ] {ai_face();};
void() shal_attack6     =[      $attack6,       shal_attack7    ] {ai_face();};
void() shal_attack7     =[      $attack7,       shal_attack8    ] {ai_face();};
void() shal_attack8     =[      $attack8,       shal_attack9    ] {ai_face();};
void() shal_attack9     =[      $attack9,       shal_attack10   ] {ai_face();ShalMissile();};
void() shal_attack10    =[      $attack10,      shal_attack11   ] {ai_face();};
void() shal_attack11    =[      $attack11,      shal_run1   ] {};

void() shal_pain1       =[      $pain1, shal_pain2      ] {};
void() shal_pain2       =[      $pain2, shal_pain3      ] {};
void() shal_pain3       =[      $pain3, shal_pain4      ] {};
void() shal_pain4       =[      $pain4, shal_pain5      ] {};
void() shal_pain5       =[      $pain5, shal_run1      ] {};

void() shal_death1      =[      $death1,        shal_death2     ] {};
void() shal_death2      =[      $death2,        shal_death3     ] {SetUnblocking();};
void() shal_death3      =[      $death3,        shal_death4     ] {};
void() shal_death4      =[      $death4,        shal_death5     ] {};
void() shal_death5      =[      $death5,        shal_death6     ] {};
void() shal_death6      =[      $death6,        shal_death7     ] {};
void() shal_death7      =[      $death7,        shal_death7    ] {};


void(entity attacker, float damage) shalrath_pain =
{
	sound (self, CHAN_VOICE, "shalrath/pain.wav", 1, ATTN_NORM);
	shal_pain1();
	SUB_PainFinished(1, 5);
	self.special = time + 0.5; // momentarily stop tracking target
};

void() shalrath_gib =
{
	sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
	ThrowHead ("progs/h_shal.mdl", self.health);
	ThrowGib ("progs/gib1.mdl", self.health);
	ThrowGib ("progs/gib2.mdl", self.health);
	ThrowGib ("progs/gib3.mdl", self.health);
}

void() shalrath_die =
{
	sound (self, CHAN_VOICE, "shalrath/death.wav", 1, ATTN_NORM);
	shal_death1();
};

/*
================
ShalMissile
================
*/
void() ShalMissileTouch;
void() ShalHome;
void() ShalMissile =
{
	self.effects |= EF_MUZZLEFLASH;
	sound (self, CHAN_WEAPON, "shalrath/attack2.wav", 1, ATTN_NORM);
	
	local entity missile = FireProjectileAtEnemy(self.origin+'0 0 10', '0 0 10', 350, 0, "progs/v_spike.mdl", TRUE, FALSE);
	missile.avelocity = '300 300 300';
	missile.nextthink = time + 0.1;
	missile.think = ShalHome;
	missile.touch = ShalMissileTouch;
	missile.special = 4;
};

void() ShalHome =
{
	if (self.special > 0)
		self.special -= 0.1;
	
	if (self.owner.health <= 0 || self.owner.enemy.health <= 0 || self.special <= 0)
	{
		self.special = 0;
		return;
	}
	
	self.nextthink = time + 0.1;
	if (self.owner.special > time)
		return;
	
	local entity o = self;
	self = self.owner;
	local float novis = HasInvisible(self.enemy);
	if (!novis)
		novis |= !visible(self.enemy, FALSE);
	self = o;
	
	if (novis)
		return;
	
	local vector vel = normalize(self.velocity);
	local vector dir = normalize(self.owner.enemy.origin+'0 0 10' - self.origin);
	local float dot = vel * dir;
	if (dot == 1)
		return;
	
	local vector cs = '0 1 0' * (30 * (self.special / 4));
	makevectors(cs);
	cs_x = v_forward_x;
	cs_y = v_forward_y;
	
	local vector newdir;
	if (dot >= cs_x)
		newdir = dir;
	else
	{
		local vector cross;
		cross_x = vel_y*dir_z - vel_z*dir_y;
		cross_y = vel_z*dir_x - vel_x*dir_z;
		cross_z = vel_x*dir_y - vel_y*dir_x;
		cross = normalize(cross);
		
		local vector r;
		r_x = cross_y*vel_z - cross_z*vel_y;
		r_y = cross_z*vel_x - cross_x*vel_z;
		r_z = cross_x*vel_y - cross_y*vel_x;
		
		newdir = normalize(vel*cs_x + r*cs_y + cross*(cross*vel)*(1-cs_x));
	}
	
	self.velocity = newdir * vlen(self.velocity);
};

void() ShalMissileTouch =
{
	if (other == self.owner)
		// don't explode on owner
		return;
	
	self.special = 0;

	local float damage = 10;
	if (other.is_zombie)
		damage *= 3;
	
	T_Damage(other, self, self.owner, damage, 50, FALSE);
	T_RadiusDamage (self, self.owner, 30, 20, 80, 50, other);
	sound (self, CHAN_WEAPON, "weapons/r_exp3.wav", 1, ATTN_NORM);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	self.velocity = '0 0 0';
	self.touch = SUB_Null;
	setmodel (self, "progs/s_explod.spr");
	self.solid = SOLID_NOT;
	s_explode1 ();
};

float() shal_los = 
{
	traceline(self.origin+'0 0 10', self.enemy.origin+'0 0 10', FALSE, self);
	return trace_ent == self.enemy || trace_ent.classname == "player";
};

float() shal_checkatk =
{
	if (self.attack_finished > time || enemy_range == RANGE_FAR)
		return FALSE;
	if (!shal_los())
		return FALSE;
	
	self.attack_state = AS_MISSILE;
	SUB_AttackFinished(1.3+random()*0.3, 1.1, FALSE);
	return TRUE;
};

//=================================================================

/*QUAKED monster_shalrath (1 0 0) (-32 -32 -24) (32 32 48) Ambush
*/
void() monster_shalrath =
{
	if (deathmatch)
	{
		remove(self);
		return;
	}
	precache_model2 ("progs/shalrath.mdl");
	precache_model2 ("progs/h_shal.mdl");
	precache_model2 ("progs/v_spike.mdl");

	precache_sound2 ("shalrath/attack.wav");
	precache_sound2 ("shalrath/attack2.wav");
	precache_sound2 ("shalrath/death.wav");
	precache_sound2 ("shalrath/idle.wav");
	precache_sound2 ("shalrath/pain.wav");
	precache_sound2 ("shalrath/sight.wav");

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

	setmodel (self, "progs/shalrath.mdl");
	setsize (self, '-32 -32 -24', '32 32 40');
	self.health = 360;
	self.gib_health = -72;
	self.pain_threshold = 270;

	self.th_stand = shal_stand;
	self.th_walk = shal_walk1;
	self.th_run = shal_run1;
	self.th_die = shalrath_die;
	self.th_gib = shalrath_gib;
	self.th_pain = shalrath_pain;
	self.th_missile = shal_attack1;
	self.th_checkatk = shal_checkatk;

	self.think = walkmonster_start;
	self.nextthink = time + 0.1 + random ()*0.1;
};
